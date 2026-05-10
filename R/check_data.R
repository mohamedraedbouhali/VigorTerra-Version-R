# Vérifier les données collectées

check_collected_data <- function(data_folder = "data/raw") {
  files <- list(
    "Climat (journalier)" = "climate_data_openmeteo.csv",
    "Climat (annuel)"     = "climate_data_yearly.csv",
    "FAOSTAT"             = "faostat_data.csv",
    "Sol"                 = "soil_data.csv"
  )

  cat(strrep("=", 60), "\n")
  cat("VERIFICATION DES DONNEES COLLECTEES\n")
  cat(strrep("=", 60), "\n")

  for (name in names(files)) {
    filename <- files[[name]]
    filepath <- file.path(data_folder, filename)

    cat("\n", strrep("-", 60), "\n", sep = "")
    cat(sprintf("Fichier %s : %s\n", name, filename))
    cat(strrep("-", 60), "\n")

    if (file.exists(filepath)) {
      df <- read.csv(filepath, stringsAsFactors = FALSE, check.names = FALSE)
      cat("Fichier trouve\n")
      cat(sprintf("   Lignes   : %d\n", nrow(df)))
      cat(sprintf("   Colonnes : %d\n", ncol(df)))
      cat(sprintf("   Colonnes : %s\n", paste(names(df), collapse = ", ")))
      cat("\n   Apercu :\n")
      print(head(df, 3))
    } else {
      cat("Fichier non trouve\n")
    }
  }

  cat("\n", strrep("=", 60), "\n", sep = "")
}


if (!interactive()) {
  args   <- commandArgs(trailingOnly = TRUE)
  folder <- if (length(args) >= 1) args[1] else "data/raw"
  check_collected_data(folder)
}
