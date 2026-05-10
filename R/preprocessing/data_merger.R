# Fusion des données collectées en un jeu unique pour le ML.
# Colonnes cibles: pluviométrie, température, humidité, pH, N, P, K,
# surface cultivée, année, rendement agricole (variable cible).

library(readr)
library(dplyr)
library(tidyr)


load_sources <- function(data_dir) {
  out <- list()

  p <- file.path(data_dir, "faostat_crops_tunisia.csv")
  if (file.exists(p)) out$faostat <- readr::read_csv(p, show_col_types = FALSE)

  p <- file.path(data_dir, "openmeteo_tunisia_annual.csv")
  if (file.exists(p)) out$openmeteo_annual <- readr::read_csv(p, show_col_types = FALSE)

  p <- file.path(data_dir, "openmeteo_tunisia.csv")
  if (file.exists(p)) out$openmeteo <- readr::read_csv(p, show_col_types = FALSE)

  p <- file.path(data_dir, "soil_tunisia.csv")
  if (file.exists(p)) out$soil <- readr::read_csv(p, show_col_types = FALSE)

  out
}


faostat_to_yield_table <- function(df) {
  if (nrow(df) == 0) return(data.frame())

  # Handle possible duplicate column renaming (Element / Element...2 etc.)
  element_col <- if ("Element.1" %in% names(df)) "Element.1" else if ("Element" %in% names(df)) "Element" else NULL
  if (is.null(element_col)) return(data.frame())

  year_col <- if ("Year" %in% names(df)) "Year" else NULL
  if (is.null(year_col)) return(data.frame())

  elements <- c("Yield", "Production", "Area harvested")
  sub <- df[trimws(as.character(df[[element_col]])) %in% elements, ]

  keep_cols <- intersect(c(year_col, "Item", element_col, "Value"), names(sub))
  if (length(keep_cols) < 4) return(data.frame())

  sub <- unique(sub[, keep_cols, drop = FALSE])
  names(sub)[names(sub) == element_col] <- "Element"
  names(sub)[names(sub) == year_col]    <- "Year"

  piv <- tidyr::pivot_wider(
    sub,
    names_from  = "Element",
    values_from = "Value",
    values_fn   = dplyr::first
  )

  for (old_new in list(c("Area harvested", "area_harvested_ha"),
                        c("Production",     "production_tonnes"),
                        c("Yield",          "yield_value"))) {
    if (old_new[1] %in% names(piv)) names(piv)[names(piv) == old_new[1]] <- old_new[2]
  }

  if ("yield_value" %in% names(piv)) {
    piv$yield_tonnes_per_ha <- piv$yield_value / 10000.0  # hg/ha -> t/ha
  }

  piv
}


merge_all_to_ml_dataset <- function(data_dir) {
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  sources <- load_sources(data_dir)

  # ---- Base: FAOSTAT yields ----
  if (!"faostat" %in% names(sources) || nrow(sources$faostat) == 0) {
    ml_df <- data.frame(year = integer(), item = character(),
                        yield_tonnes_per_ha = numeric(),
                        area_harvested_ha   = numeric(),
                        production_tonnes   = numeric(),
                        stringsAsFactors    = FALSE)
  } else {
    ml_df <- faostat_to_yield_table(sources$faostat)

    if (nrow(ml_df) == 0 && "Item" %in% names(sources$faostat)) {
      df <- sources$faostat
      element_col <- if ("Element.1" %in% names(df)) "Element.1" else "Element"
      year_col    <- if ("Year" %in% names(df)) "Year" else NULL

      if (!is.null(year_col) && element_col %in% names(df)) {
        elem <- trimws(as.character(df[[element_col]]))
        for (pair in list(c("Yield", "yield_tonnes_per_ha"),
                          c("Area harvested", "area_harvested_ha"),
                          c("Production",     "production_tonnes"))) {
          sub <- df[elem == pair[1], c(year_col, "Item", "Value"), drop = FALSE]
          sub <- unique(sub)
          names(sub)[names(sub) == year_col] <- "year"
          names(sub)[names(sub) == "Item"]   <- "item"
          names(sub)[names(sub) == "Value"]  <- pair[2]

          if (pair[2] == "yield_tonnes_per_ha") {
            sub[[pair[2]]] <- as.numeric(sub[[pair[2]]]) / 10000.0
          }

          if (nrow(ml_df) == 0) {
            ml_df <- sub
          } else if (nrow(sub) > 0) {
            merge_key <- intersect(c("year", "item"), names(ml_df))
            if (length(merge_key) > 0 && length(merge_key) == length(intersect(merge_key, names(sub)))) {
              ml_df <- dplyr::full_join(ml_df, sub, by = merge_key)
            }
          }
        }
      }
    }

    if ("yield_value" %in% names(ml_df) && !"yield_tonnes_per_ha" %in% names(ml_df)) {
      ml_df$yield_tonnes_per_ha <- as.numeric(ml_df$yield_value) / 10000.0
    }
  }

  # ---- Climate: Open-Meteo annual ----
  if ("openmeteo_annual" %in% names(sources) && nrow(sources$openmeteo_annual) > 0) {
    om <- sources$openmeteo_annual
    if ("year" %in% names(om)) {
      climate <- om %>%
        dplyr::group_by(year) %>%
        dplyr::summarise(
          pluviometrie_mm       = mean(precipitation_mm,      na.rm = TRUE),
          temperature_moyenne_c = mean(temperature_mean_c,    na.rm = TRUE),
          humidite_pct          = mean(relative_humidity_pct, na.rm = TRUE),
          .groups = "drop"
        )
      merge_year <- if ("year" %in% names(ml_df)) "year" else if ("Year" %in% names(ml_df)) "Year" else NULL
      if (!is.null(merge_year)) {
        ml_df <- dplyr::left_join(ml_df, climate, by = stats::setNames("year", merge_year))
      }
    }
  } else if ("openmeteo" %in% names(sources) && nrow(sources$openmeteo) > 0) {
    om <- sources$openmeteo
    om$year <- as.integer(format(as.Date(as.character(om$date)), "%Y"))
    climate  <- om %>%
      dplyr::group_by(year) %>%
      dplyr::summarise(
        pluviometrie_mm       = sum(precipitation_mm,      na.rm = TRUE),
        temperature_moyenne_c = mean(temperature_mean_c,    na.rm = TRUE),
        humidite_pct          = mean(relative_humidity_pct, na.rm = TRUE),
        .groups = "drop"
      )
    merge_year <- if ("year" %in% names(ml_df)) "year" else if ("Year" %in% names(ml_df)) "Year" else NULL
    if (!is.null(merge_year)) {
      ml_df <- dplyr::left_join(ml_df, climate, by = stats::setNames("year", merge_year))
    }
  }

  # ---- Soil: mean by year ----
  if ("soil" %in% names(sources) && nrow(sources$soil) > 0) {
    soil <- sources$soil
    if ("year" %in% names(soil)) {
      soil_agg <- soil %>%
        dplyr::group_by(year) %>%
        dplyr::summarise(
          ph                = mean(ph,                  na.rm = TRUE),
          azote_N           = mean(nitrogen_N,          na.rm = TRUE),
          phosphore_P_mg_kg = mean(phosphorus_P_mg_kg,  na.rm = TRUE),
          potassium_K_mg_kg = mean(potassium_K_mg_kg,   na.rm = TRUE),
          .groups = "drop"
        )
      merge_year <- if ("year" %in% names(ml_df)) "year" else if ("Year" %in% names(ml_df)) "Year" else NULL
      if (!is.null(merge_year)) {
        ml_df <- dplyr::left_join(ml_df, soil_agg, by = stats::setNames("year", merge_year))
      }
    }
  }

  # ---- Normalize "Year" -> "year" ----
  if ("Year" %in% names(ml_df) && !"year" %in% names(ml_df)) {
    names(ml_df)[names(ml_df) == "Year"] <- "year"
  }

  # ---- Final column renames ----
  rename_final <- c(
    yield_tonnes_per_ha = "rendement_tonnes_ha",
    area_harvested_ha   = "surface_cultivee_ha",
    year                = "annee"
  )
  for (old in names(rename_final)) {
    if (old %in% names(ml_df)) names(ml_df)[names(ml_df) == old] <- rename_final[[old]]
  }

  out_path <- file.path(data_dir, "dataset_ml_rendement_tunisie.csv")
  readr::write_csv(ml_df, out_path)
  out_path
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  out  <- if (length(args) >= 1) args[1] else "agriculture_scraping/data"
  path <- merge_all_to_ml_dataset(out)
  cat(sprintf("Dataset fusionné: %s\n", path))
}
