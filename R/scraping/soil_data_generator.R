# Génération de données pédologiques (pH, N, P, K) pour la Tunisie.
# Données synthétiques réalistes par région/gouvernorat.

REGIONS_SOIL <- list(
  list(region="Nord",   gov="Tunis",    ph_min=7.2, ph_max=8.2, n_min=0.05, n_max=0.25, p_min=15, p_max=80, k_min=120, k_max=400),
  list(region="Nord",   gov="Bizerte",  ph_min=7.0, ph_max=8.0, n_min=0.06, n_max=0.28, p_min=18, p_max=85, k_min=130, k_max=420),
  list(region="Nord",   gov="Beja",     ph_min=6.8, ph_max=7.8, n_min=0.05, n_max=0.22, p_min=12, p_max=70, k_min=100, k_max=350),
  list(region="Nord",   gov="Jendouba", ph_min=6.5, ph_max=7.5, n_min=0.06, n_max=0.26, p_min=15, p_max=75, k_min=110, k_max=380),
  list(region="Nord",   gov="Nabeul",   ph_min=7.2, ph_max=8.3, n_min=0.04, n_max=0.20, p_min=14, p_max=72, k_min=115, k_max=360),
  list(region="Centre", gov="Sousse",   ph_min=7.3, ph_max=8.4, n_min=0.04, n_max=0.18, p_min=12, p_max=65, k_min=100, k_max=320),
  list(region="Centre", gov="Sfax",     ph_min=7.5, ph_max=8.5, n_min=0.03, n_max=0.16, p_min=10, p_max=58, k_min=90,  k_max=300),
  list(region="Centre", gov="Kairouan", ph_min=7.2, ph_max=8.2, n_min=0.04, n_max=0.19, p_min=11, p_max=62, k_min=95,  k_max=310),
  list(region="Centre", gov="Kef",      ph_min=6.8, ph_max=7.8, n_min=0.05, n_max=0.22, p_min=14, p_max=68, k_min=105, k_max=340),
  list(region="Sud",    gov="Gabes",    ph_min=7.6, ph_max=8.6, n_min=0.03, n_max=0.14, p_min=8,  p_max=50, k_min=85,  k_max=280),
  list(region="Sud",    gov="Medenine", ph_min=7.5, ph_max=8.5, n_min=0.03, n_max=0.15, p_min=9,  p_max=52, k_min=88,  k_max=290),
  list(region="Sud",    gov="Tozeur",   ph_min=7.8, ph_max=8.8, n_min=0.02, n_max=0.12, p_min=7,  p_max=45, k_min=80,  k_max=260),
  list(region="Sud",    gov="Kebili",   ph_min=7.7, ph_max=8.7, n_min=0.02, n_max=0.13, p_min=8,  p_max=48, k_min=82,  k_max=270)
)


generate_soil_data <- function(years = NULL, rows_per_region_year = 5, seed = 42) {
  set.seed(seed)
  if (is.null(years)) years <- 2010:2023

  rows <- vector("list", length(REGIONS_SOIL) * length(years) * rows_per_region_year)
  idx <- 1L
  for (rec in REGIONS_SOIL) {
    for (year in years) {
      for (i in seq_len(rows_per_region_year)) {
        rows[[idx]] <- data.frame(
          year               = year,
          region             = rec$region,
          governorate        = rec$gov,
          ph                 = round(runif(1, rec$ph_min, rec$ph_max), 2),
          nitrogen_N         = round(runif(1, rec$n_min, rec$n_max), 4),
          phosphorus_P_mg_kg = round(runif(1, rec$p_min, rec$p_max), 1),
          potassium_K_mg_kg  = round(runif(1, rec$k_min, rec$k_max), 1),
          stringsAsFactors   = FALSE
        )
        idx <- idx + 1L
      }
    }
  }
  do.call(rbind, rows)
}


save_soil_data <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  df <- generate_soil_data()
  out_path <- file.path(output_dir, "soil_tunisia.csv")
  write.csv(df, out_path, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(df)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  out  <- if (length(args) >= 1) args[1] else "data"
  df   <- save_soil_data(out)
  cat(sprintf("Lignes sol: %d\n", nrow(df)))
  print(head(df, 10))
}
