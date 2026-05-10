# Open-Meteo API - Température, précipitations, humidité pour la Tunisie.
# Source: https://open-meteo.com

library(httr)
library(readr)
library(dplyr)

TUNISIA_COORDS <- list(
  list(name="Tunis",    lat=36.8065, lon=10.1815),
  list(name="Sfax",     lat=34.7406, lon=10.7603),
  list(name="Sousse",   lat=35.8256, lon=10.6346),
  list(name="Kairouan", lat=35.6781, lon=10.0963),
  list(name="Bizerte",  lat=37.2744, lon=9.8739),
  list(name="Gabes",    lat=33.8815, lon=10.0982),
  list(name="Beja",     lat=36.7256, lon=9.1817)
)

BASE_FORECAST <- "https://api.open-meteo.com/v1/forecast"
ARCHIVE_API   <- "https://archive-api.open-meteo.com/v1/archive"


.parse_daily_response <- function(data, latitude, longitude) {
  daily <- data$daily
  if (is.null(daily) || length(daily) == 0) return(data.frame())

  t_max  <- daily$temperature_2m_max
  t_min  <- daily$temperature_2m_min
  t_mean <- daily$temperature_2m_mean
  if (is.null(t_mean) && !is.null(t_max) && !is.null(t_min)) {
    t_mean <- (unlist(t_max) + unlist(t_min)) / 2
  }

  data.frame(
    date                 = as.Date(unlist(daily$time)),
    temperature_max_c    = unlist(t_max),
    temperature_min_c    = unlist(t_min),
    temperature_mean_c   = unlist(t_mean),
    precipitation_mm     = unlist(daily$precipitation_sum),
    relative_humidity_pct = unlist(daily$relative_humidity_2m_mean),
    latitude             = latitude,
    longitude            = longitude,
    stringsAsFactors     = FALSE
  )
}


fetch_openmeteo_daily <- function(latitude, longitude, start_date, end_date,
                                   timezone = "Africa/Tunis") {
  params <- list(
    latitude   = latitude,
    longitude  = longitude,
    start_date = start_date,
    end_date   = end_date,
    timezone   = timezone,
    daily      = paste(
      "temperature_2m_max", "temperature_2m_min", "temperature_2m_mean",
      "precipitation_sum", "relative_humidity_2m_mean",
      sep = ","
    )
  )
  resp <- httr::GET(ARCHIVE_API, query = params, httr::timeout(30))
  httr::stop_for_status(resp)
  data <- httr::content(resp, as = "parsed", encoding = "UTF-8")
  .parse_daily_response(data, latitude, longitude)
}


fetch_openmeteo_forecast_past_days <- function(latitude, longitude, past_days = 92,
                                                timezone = "Africa/Tunis") {
  params <- list(
    latitude      = latitude,
    longitude     = longitude,
    past_days     = past_days,
    forecast_days = 0,
    timezone      = timezone,
    daily         = paste(
      "temperature_2m_max", "temperature_2m_min", "temperature_2m_mean",
      "precipitation_sum", "relative_humidity_2m_mean",
      sep = ","
    )
  )
  resp <- httr::GET(BASE_FORECAST, query = params, httr::timeout(30))
  httr::stop_for_status(resp)
  data <- httr::content(resp, as = "parsed", encoding = "UTF-8")
  .parse_daily_response(data, latitude, longitude)
}


collect_tunisia_climate <- function(start_date = "2015-01-01", end_date = NULL,
                                     use_archive = TRUE, locations = NULL) {
  if (is.null(end_date)) end_date <- as.character(Sys.Date())
  if (is.null(locations)) locations <- TUNISIA_COORDS

  all_dfs <- list()
  for (loc in locations) {
    lat  <- loc$lat
    lon  <- loc$lon
    name <- loc$name %||% "point"
    tryCatch({
      df <- if (use_archive) {
        fetch_openmeteo_daily(lat, lon, start_date, end_date)
      } else {
        fetch_openmeteo_forecast_past_days(lat, lon, past_days = 90)
      }
      df$location <- name
      all_dfs[[length(all_dfs) + 1]] <- df
    }, error = function(e) {
      cat(sprintf("Open-Meteo %s: %s\n", name, conditionMessage(e)))
    })
  }

  if (length(all_dfs) == 0) return(data.frame())
  dplyr::bind_rows(all_dfs)
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x


save_openmeteo_tunisia <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  df <- tryCatch(
    collect_tunisia_climate(start_date = "2015-01-01", end_date = NULL, use_archive = TRUE),
    error = function(e) data.frame()
  )

  if (nrow(df) == 0) {
    df <- collect_tunisia_climate(use_archive = FALSE)
  }

  if (nrow(df) > 0) {
    readr::write_csv(df, file.path(output_dir, "openmeteo_tunisia.csv"))

    df$year <- as.integer(format(as.Date(df$date), "%Y"))
    annual <- df %>%
      dplyr::group_by(year, location) %>%
      dplyr::summarise(
        precipitation_mm      = sum(precipitation_mm,      na.rm = TRUE),
        temperature_mean_c    = mean(temperature_mean_c,    na.rm = TRUE),
        relative_humidity_pct = mean(relative_humidity_pct, na.rm = TRUE),
        .groups = "drop"
      )
    readr::write_csv(annual, file.path(output_dir, "openmeteo_tunisia_annual.csv"))
  }

  invisible(df)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  out  <- if (length(args) >= 1) args[1] else "data"
  df   <- save_openmeteo_tunisia(out)
  cat(sprintf("Lignes Open-Meteo: %d\n", nrow(df)))
  if (nrow(df) > 0) print(head(df, 10))
}
