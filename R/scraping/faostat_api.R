# FAOSTAT - Récupération rendement agricole, production et surface cultivée (Tunisie).
# Source: https://www.fao.org/faostat

library(httr)
library(readr)
library(dplyr)
library(tidyr)

TUNISIA_AREA_CODE       <- "222"
FAOSTAT_CROPS_BULK_URL  <- "https://bulks-faostat.fao.org/production/Production_Crops_Livestock_E_All_Data_(Normalized).zip"
FAOSTAT_CROPS_FALLBACK  <- "https://fenixservices.fao.org/faostat/static/bulkdownloads/Production_Crops_Livestock_E_All_Data_(Normalized).zip"


.get_crops_bulk_url <- function() {
  catalog_url <- "http://fenixservices.fao.org/faostat/static/bulkdownloads/datasets_E.json"
  tryCatch({
    resp <- httr::GET(catalog_url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      data <- httr::content(resp, as = "parsed", encoding = "UTF-8")
      datasets <- data$Datasets$Dataset
      if (!is.null(datasets)) {
        for (ds in datasets) {
          code <- ds$DatasetCode %||% ""
          name <- tolower(ds$DatasetName %||% "")
          if (code == "QCL" || (grepl("crop", name) && grepl("production", name))) {
            loc <- ds$FileLocation
            if (!is.null(loc) && nzchar(loc)) return(loc)
          }
        }
      }
    }
  }, error = function(e) NULL)
  FAOSTAT_CROPS_BULK_URL
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x


.download_zip_raw <- function(url) {
  for (u in c(url, FAOSTAT_CROPS_FALLBACK)) {
    tryCatch({
      resp <- httr::GET(u, httr::timeout(180))
      if (httr::status_code(resp) == 200) {
        return(httr::content(resp, as = "raw"))
      }
    }, error = function(e) NULL)
  }
  stop("Impossible de télécharger les données FAOSTAT.")
}


download_faostat_crops_tunisia <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  url         <- .get_crops_bulk_url()
  raw_content <- .download_zip_raw(url)

  tmp_zip <- tempfile(fileext = ".zip")
  writeBin(raw_content, tmp_zip)
  on.exit(unlink(tmp_zip), add = TRUE)

  tmp_dir <- file.path(tempdir(), paste0("faostat_", as.integer(Sys.time())))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  unzip(tmp_zip, exdir = tmp_dir, overwrite = TRUE)

  all_csv  <- list.files(tmp_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  csv_file <- grep("Normalized", all_csv, value = TRUE, ignore.case = TRUE)[1]
  if (is.na(csv_file)) csv_file <- all_csv[1]

  df <- readr::read_csv(csv_file, show_col_types = FALSE, locale = readr::locale(encoding = "UTF-8"))

  # Filter Tunisia
  if ("Area Code (ISO3)" %in% names(df)) {
    df <- df[trimws(as.character(df[["Area Code (ISO3)"]])) == "TUN", ]
  } else if ("Area Code" %in% names(df)) {
    df <- df[as.character(df[["Area Code"]]) == TUNISIA_AREA_CODE, ]
  } else if ("Area" %in% names(df)) {
    df <- df[tolower(trimws(as.character(df$Area))) == "tunisia", ]
  }

  # Harmonize column names (handle duplicates introduced by read_csv)
  col_map <- stats::setNames(names(df), names(df))
  for (col in names(df)) {
    col_lower <- tolower(col)
    if (grepl("^year", col_lower) && !grepl("code", col_lower))  col_map[[col]] <- "Year"
    if (grepl("element", col_lower) && !grepl("code", col_lower)) col_map[[col]] <- "Element"
    if (grepl("^item$", col_lower))                               col_map[[col]] <- "Item"
    if (grepl("^value$", col_lower))                              col_map[[col]] <- "Value"
    if (grepl("^unit$", col_lower))                               col_map[[col]] <- "Unit"
  }
  names(df) <- unname(col_map)
  df <- df[, !duplicated(names(df)), drop = FALSE]

  out_path <- file.path(output_dir, "faostat_crops_tunisia.csv")
  readr::write_csv(df, out_path)
  df
}


get_yield_production_area_df <- function(df) {
  if (nrow(df) == 0 || !"Element" %in% names(df)) return(data.frame())

  elements <- c("Yield", "Production", "Area harvested")
  df <- df[trimws(as.character(df$Element)) %in% elements, ]
  if (nrow(df) == 0) return(data.frame())

  pivot_cols <- intersect(c("Year", "Item", "Element", "Value"), names(df))
  df_sub <- unique(df[, pivot_cols, drop = FALSE])

  piv <- tidyr::pivot_wider(
    df_sub,
    names_from  = "Element",
    values_from = "Value",
    values_fn   = dplyr::first
  )

  rename_map <- c(
    "Area harvested" = "area_harvested_ha",
    "Production"     = "production_tonnes",
    "Yield"          = "yield_value"
  )
  for (old in names(rename_map)) {
    if (old %in% names(piv)) names(piv)[names(piv) == old] <- rename_map[[old]]
  }

  if ("yield_value" %in% names(piv) && "Unit" %in% names(df)) {
    unit_val <- na.omit(df$Unit)[1]
    if (!is.na(unit_val) && grepl("hg", tolower(unit_val))) {
      piv$yield_tonnes_per_ha <- piv$yield_value / 10000
    } else {
      piv$yield_tonnes_per_ha <- piv$yield_value
    }
  }

  piv
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  out  <- if (length(args) >= 1) args[1] else "data"
  df   <- download_faostat_crops_tunisia(out)
  cat(sprintf("Lignes Tunisie: %d\n", nrow(df)))
  if (nrow(df) > 0) {
    summary_df <- get_yield_production_area_df(df)
    print(head(summary_df, 20))
  }
}
