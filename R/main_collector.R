# Script principal de collecte des données.
# Sources: FAOSTAT, Open-Meteo, Agridata, INM meteo.tn, Sol synthétique.
#
# Usage: Rscript R/main_collector.R [dossier_sortie]
# Par défaut: agriculture_scraping/data/

script_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) "R")

source(file.path(script_dir, "scraping", "faostat_api.R"))
source(file.path(script_dir, "scraping", "openmeteo_api.R"))
source(file.path(script_dir, "scraping", "agridata_scraper.R"))
source(file.path(script_dir, "scraping", "meteo_scraper.R"))
source(file.path(script_dir, "scraping", "soil_data_generator.R"))
source(file.path(script_dir, "preprocessing", "data_merger.R"))


run_collection <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  summary_out <- list()

  # 1) FAOSTAT
  cat("--- FAOSTAT (rendement, production, surface) ---\n")
  tryCatch({
    df_fao <- download_faostat_crops_tunisia(output_dir)
    summary_out$faostat <- nrow(df_fao)
    cat(sprintf("  Lignes: %d\n", nrow(df_fao)))
  }, error = function(e) {
    summary_out$faostat <<- 0
    cat(sprintf("  Erreur: %s\n", conditionMessage(e)))
  })

  # 2) Open-Meteo
  cat("--- Open-Meteo (température, pluie, humidité) ---\n")
  tryCatch({
    df_om <- save_openmeteo_tunisia(output_dir)
    summary_out$openmeteo <- nrow(df_om)
    cat(sprintf("  Lignes: %d\n", nrow(df_om)))
  }, error = function(e) {
    summary_out$openmeteo <<- 0
    cat(sprintf("  Erreur: %s\n", conditionMessage(e)))
  })

  # 3) Agridata
  cat("--- Agridata (pluviométrie, production) ---\n")
  tryCatch({
    df_pluv <- scrape_agridata_pluviometry(output_dir)
    df_prod <- scrape_agridata_production(output_dir)
    summary_out$agridata_pluviometry <- nrow(df_pluv)
    summary_out$agridata_production  <- nrow(df_prod)
    cat(sprintf("  Pluviométrie: %d, Production: %d\n", nrow(df_pluv), nrow(df_prod)))
  }, error = function(e) {
    summary_out$agridata_pluviometry <<- 0
    summary_out$agridata_production  <<- 0
    cat(sprintf("  Erreur: %s\n", conditionMessage(e)))
  })

  # 4) INM meteo.tn
  cat("--- INM meteo.tn ---\n")
  tryCatch({
    df_inm <- collect_inm_data(output_dir)
    summary_out$meteo_tn <- nrow(df_inm)
    cat(sprintf("  Lignes: %d\n", nrow(df_inm)))
  }, error = function(e) {
    summary_out$meteo_tn <<- 0
    cat(sprintf("  Erreur: %s\n", conditionMessage(e)))
  })

  # 5) Données sol synthétiques
  cat("--- Données sol (pH, N, P, K) ---\n")
  tryCatch({
    df_soil <- save_soil_data(output_dir)
    summary_out$soil <- nrow(df_soil)
    cat(sprintf("  Lignes: %d\n", nrow(df_soil)))
  }, error = function(e) {
    summary_out$soil <<- 0
    cat(sprintf("  Erreur: %s\n", conditionMessage(e)))
  })

  # 6) Fusion pour ML
  cat("--- Fusion des données ---\n")
  tryCatch({
    merged_path <- merge_all_to_ml_dataset(output_dir)
    summary_out$merged_ml <- merged_path
    cat(sprintf("  Fichier fusionné: %s\n", merged_path))
  }, error = function(e) {
    summary_out$merged_ml <<- NULL
    cat(sprintf("  Fusion: %s\n", conditionMessage(e)))
  })

  summary_out
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  out  <- if (length(args) >= 1) args[1] else file.path(getwd(), "agriculture_scraping", "data")
  cat(sprintf("Sortie: %s\n\n", out))
  run_collection(out)
  cat("\nCollecte terminée.\n")
}
