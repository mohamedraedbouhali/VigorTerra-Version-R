# Agridata Tunisie - Scraping pluviométrie et données agricoles depuis le portail CKAN.
# Source: https://catalog.agridata.tn

library(httr)
library(readr)
library(readxl)
library(dplyr)
library(rvest)

CATALOG_API <- "https://catalog.agridata.tn/api/3/action"
BASE_URL    <- "https://catalog.agridata.tn"


.ckan_request <- function(action, ...) {
  url    <- paste0(CATALOG_API, "/", action)
  params <- list(...)
  tryCatch({
    resp <- httr::GET(url, query = params, httr::timeout(25))
    if (httr::status_code(resp) == 200) {
      return(httr::content(resp, as = "parsed", encoding = "UTF-8"))
    }
  }, error = function(e) {
    cat(sprintf("CKAN %s: %s\n", action, conditionMessage(e)))
  })
  list(success = FALSE, result = NULL)
}


list_datasets <- function(query = "") {
  out   <- .ckan_request("package_list")
  names <- out$result
  if (is.null(names)) return(character(0))
  if (nzchar(query)) names <- names[grepl(query, names, ignore.case = TRUE)]
  unlist(names)
}


get_package_resources <- function(package_id) {
  out <- .ckan_request("package_show", id = package_id)
  if (!isTRUE(out$success)) return(list())
  pkg <- out$result
  if (is.null(pkg)) return(list())
  pkg$resources %||% list()
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x


.download_resource_raw <- function(url) {
  tryCatch({
    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) == 200) return(httr::content(resp, as = "raw"))
    NULL
  }, error = function(e) {
    cat(sprintf("Download %.60s...: %s\n", url, conditionMessage(e)))
    NULL
  })
}


.load_raw_as_df <- function(raw, url, fmt = "") {
  if (is.null(raw) || length(raw) == 0) return(data.frame())
  ext <- tolower(tools::file_ext(strsplit(url, "\\?")[[1]][1]))
  if (ext == "" && nzchar(fmt)) ext <- tolower(fmt)

  tryCatch({
    if (ext %in% c("csv", "txt") || nzchar(fmt) && grepl("csv", tolower(fmt))) {
      readr::read_csv(raw, show_col_types = FALSE, progress = FALSE)
    } else if (ext %in% c("xlsx", "xls")) {
      tmp <- tempfile(fileext = paste0(".", ext))
      writeBin(raw, tmp)
      on.exit(unlink(tmp))
      readxl::read_excel(tmp)
    } else {
      # Try CSV as fallback
      readr::read_csv(raw, show_col_types = FALSE, progress = FALSE)
    }
  }, error = function(e) data.frame())
}


scrape_agridata_pluviometry <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  candidates <- c(
    "pluviometriques-journalieres-observees",
    "donnee-climatique",
    "donnees-climatiques-gouvernorat-de-siliana"
  )

  all_dfs <- list()
  for (package_id in candidates) {
    resources <- get_package_resources(package_id)
    if (length(resources) == 0) next

    for (res in resources) {
      url <- res$url %||% res$resource_url %||% ""
      if (!nzchar(url)) next
      url_lower <- tolower(url)
      if (!any(sapply(c(".csv", "csv", "xlsx", "xls"), function(s) grepl(s, url_lower)))) next

      raw <- .download_resource_raw(url)
      if (is.null(raw)) next

      fmt <- res$format %||% ""
      df  <- .load_raw_as_df(raw, url, fmt)
      if (nrow(df) == 0) next

      df$`_source_dataset` <- package_id
      all_dfs[[length(all_dfs) + 1]] <- df

      res_name <- res$name %||% tolower(res$format %||% "data")
      out_name <- substr(gsub(" ", "_", paste0("agridata_", package_id, "_", res_name, ".csv")), 1, 80)
      readr::write_csv(df, file.path(output_dir, out_name))
    }
  }

  if (length(all_dfs) == 0) {
    # Fallback: HTML catalogue
    tryCatch({
      resp <- httr::GET(paste0(BASE_URL, "/fr/dataset/"), httr::timeout(20))
      if (httr::status_code(resp) == 200) {
        page  <- rvest::read_html(httr::content(resp, as = "text", encoding = "UTF-8"))
        links <- rvest::html_attr(rvest::html_nodes(page, 'a[href*="/dataset/"]'), "href")
        links <- links[grepl("pluvio", links, ignore.case = TRUE)]
        if (length(links) > 0) cat(sprintf("Fallback: found %d pluvio links\n", length(links)))
      }
    }, error = function(e) cat(sprintf("Fallback scrape: %s\n", conditionMessage(e))))
  }

  if (length(all_dfs) > 0) {
    combined <- dplyr::bind_rows(all_dfs)
    readr::write_csv(combined, file.path(output_dir, "agridata_pluviometry_combined.csv"))
    return(invisible(combined))
  }
  data.frame()
}


scrape_agridata_production <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  candidates <- c(
    "evolution-de-la-production-nationale-des-cereales",
    "evolution-de-la-production-vegetale",
    "evolution-des-cereales-pendant-la-periode-1980-2022"
  )

  all_dfs <- list()
  for (package_id in candidates) {
    resources <- get_package_resources(package_id)
    for (res in resources) {
      url <- res$url %||% res$resource_url %||% ""
      if (!nzchar(url)) next

      raw <- .download_resource_raw(url)
      if (is.null(raw)) next

      fmt <- res$format %||% ""
      df  <- .load_raw_as_df(raw, url, fmt)
      if (nrow(df) == 0) next

      df$`_source_dataset` <- package_id
      all_dfs[[length(all_dfs) + 1]] <- df

      safe_name <- substr(gsub("-", "_", package_id), 1, 50)
      readr::write_csv(df, file.path(output_dir, paste0("agridata_production_", safe_name, ".csv")))
    }
  }

  if (length(all_dfs) > 0) {
    combined <- dplyr::bind_rows(all_dfs)
    readr::write_csv(combined, file.path(output_dir, "agridata_production_combined.csv"))
    return(invisible(combined))
  }
  data.frame()
}


if (!interactive()) {
  args     <- commandArgs(trailingOnly = TRUE)
  out      <- if (length(args) >= 1) args[1] else "data"
  df_pluv  <- scrape_agridata_pluviometry(out)
  cat(sprintf("Pluviométrie Agridata: %d lignes\n", nrow(df_pluv)))
  df_prod  <- scrape_agridata_production(out)
  cat(sprintf("Production Agridata: %d lignes\n", nrow(df_prod)))
}
