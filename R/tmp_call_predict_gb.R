library(httr)
library(jsonlite)

payload <- list(
  model = "gradient_boosting",
  features = list(
    pluviometrie = 320,
    temperature  = 21.4,
    humidite     = 64,
    ph           = 6.9,
    azote        = 0.18,
    phosphore    = 42,
    potassium    = 165,
    surface      = 8.5
  )
)

resp <- httr::POST(
  url         = "http://127.0.0.1:8000/api/predict",
  body        = jsonlite::toJSON(payload, auto_unbox = TRUE),
  encode      = "raw",
  httr::content_type_json()
)

cat(httr::status_code(resp), "\n")
cat(httr::content(resp, as = "text", encoding = "UTF-8"), "\n")
