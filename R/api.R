library(plumber)
library(jsonlite)
library(httr)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) return(y)
  if (is.atomic(x) && length(x) == 1 && is.na(x)) return(y)
  x
}

.CORS_ORIGINS <- c(
  "http://localhost", "http://127.0.0.1",
  "http://localhost:3000", "http://localhost:3001", "http://localhost:3002",
  "http://127.0.0.1:3000", "http://127.0.0.1:3001", "http://127.0.0.1:3002"
)

#* @filter cors
function(req, res) {
  origin <- req$HTTP_ORIGIN %||% ""
  if (nzchar(origin) && origin %in% .CORS_ORIGINS) {
    res$setHeader("Access-Control-Allow-Origin", origin)
  }
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  res$setHeader("Access-Control-Allow-Credentials", "true")
  if (identical(req$REQUEST_METHOD, "OPTIONS")) {
    res$status <- 204
    return(list())
  }
  plumber::forward()
}

service_payload <- function() {
  list(status = "ok", service = "rendement-agricole-api")
}

LOCAL_RESPONSES <- c(
  "hi" = "👋 Hi! I'm Terra, your farming assistant. Ask me about crops, weather, soil, or yield!",
  "hello" = "👋 Hello! Welcome to VigorTerra. I'm Terra, ready to help with farming questions!",
  "hey" = "👋 Hey there! What farming question can I help with?",
  "help" = "I can answer questions about:\n🌾 Crop types & varieties\n🌧️ Weather & climate\n🥔 Soil properties\n📊 Yield prediction\n🌱 Farming practices",
  "what can you do" = "I can answer questions about:\n🌾 Crop types & varieties\n🌧️ Weather & climate\n🥔 Soil properties\n📊 Yield prediction\n🌱 Farming practices",
  "what can you help with" = "I can answer questions about:\n🌾 Crop types & varieties\n🌧️ Weather & climate\n🥔 Soil properties\n📊 Yield prediction\n🌱 Farming practices",
  "what crops grow in tunisia" = "Tunisia grows: 🌾 Wheat, barley, oats 🫒 Olives 🍇 Grapes 🍅 Tomatoes 🥒 Dates in Sahara",
  "what is wheat" = "🌾 Wheat is a cereal grain used for flour, bread, pasta. Grows well in cool climates with moderate rainfall.",
  "what is barley" = "🌾 Barley is a cereal grain similar to wheat. Tolerates drier conditions. Used for animal feed and beer.",
  "olive farming" = "🫒 Olives need:\n- Mediterranean climate\n- Well-drained soil\n- ~2-3 years before first harvest\n- Prune in late winter",
  "how to grow tomatoes" = "🍅 Tomatoes need:\n- Warm temps (60-75°F)\n- Full sunlight (6-8 hours)\n- Rich, well-drained soil\n- Regular watering\n- Support stakes",
  "how does rain affect crops" = "🌧️ Rain effects:\n✅ Positive: Provides water, reduces irrigation need\n⚠️ Too much: Waterlogging, disease\n⚠️ Too little: Drought stress, low yield",
  "what temperature is best for crops" = "Temperature varies by crop:\n- Cool crops (wheat): 50-65°F\n- Warm crops (tomatoes): 65-80°F\n- Hot crops (dates): 75-95°F",
  "how does sun affect plants" = "☀️ Sunlight effects:\n- Energy for photosynthesis\n- 6-8 hours minimum for most crops\n- Too much heat: Stress & wilting\n- Too little: Weak growth",
  "what is soil ph" = "🥔 pH measures soil acidity (1-14 scale):\n- pH 7 = neutral\n- pH < 7 = acidic (good for berries)\n- pH > 7 = alkaline (good for wheat)\n- Most crops: 6-7.5 optimal",
  "how to improve soil" = "🥔 Soil improvement:\n✅ Add compost/manure\n✅ Crop rotation\n✅ Mulching\n✅ Avoid over-tilling\n✅ Grow cover crops",
  "what is nitrogen" = "🥔 Nitrogen (N):\n- Essential plant nutrient\n- Promotes leaf growth\n- Sources: Manure, legumes, fertilizer\n- Deficiency: Yellow leaves, weak growth",
  "what is phosphorus" = "🥔 Phosphorus (P):\n- Root development & flowering\n- Energy production in plants\n- Sources: Bone meal, rock phosphate\n- Deficiency: Poor root growth",
  "what is potassium" = "🥔 Potassium (K):\n- Overall plant health\n- Drought resistance\n- Fruit quality\n- Sources: Wood ash, kelp, fertilizer",
  "how to increase yield" = "📊 Increase yield:\n✅ Healthy soil with good nutrients\n✅ Proper irrigation schedule\n✅ Control pests & diseases\n✅ Choose right crop varieties\n✅ Optimal planting density",
  "what affects crop yield" = "Factor affecting yield:\n🌧️ Water availability\n☀️ Sunlight\n🌡️ Temperature\n🥔 Soil fertility\n🐛 Pests & diseases\n👨‍🌾 Farming practices",
  "what is yield" = "📊 Yield = crop produced per unit area, measured in t/ha (tons per hectare). Affected by soil, weather, practices.",
  "what is t/ha" = "📊 t/ha = Tons per Hectare. 1 hectare = 10,000 m². 2.74 t/ha means 2.74 tons from 1 hectare.",
  "what is gradient boosting" = "📊 Machine learning model that learns from data patterns. Often very accurate for yield prediction.",
  "what is anomaly" = "⚠️ Anomaly = unusual conditions detected. Factors outside normal ranges that can reduce yield.",
  "what is ph" = "🥔 pH measures soil acidity (0-14). pH 7 = neutral. Optimal for crops: 6-7.5. Out of range = nutrient problems.",
  "what is humidity" = "💧 Moisture in air (0-100%). Low: plant stress. High: disease risk. Optimal: 40-70% for crops.",
  "what is rainfall" = "🌧️ Water from rain. Too little: drought. Too much: flooding. Optimal: 400-600mm annual.",
  "how often to water crops" = "💧 Watering depends on:\n- Crop type (1-3 inches/week typical)\n- Soil type (sandy needs more)\n- Weather (less in cool season)\n- Growth stage (more during fruiting)\nCheck soil 2-3 inches deep - water if dry",
  "best time to plant" = "📅 Typical planting:\n- Spring (warm crops): March-May\n- Fall (cool crops): August-October\n- Region-dependent (check local climate)",
  "pest control" = "🐛 Pest control:\n✅ Natural: Ladybugs, neem oil\n✅ Chemical: Use sparingly, follow instructions\n✅ Prevention: Crop rotation, healthy soil\n✅ Monitoring: Check plants regularly",
  "how to control pests" = "🐛 Pest control:\n✅ Natural: Ladybugs, neem oil\n✅ Chemical: Use sparingly, follow instructions\n✅ Prevention: Crop rotation, healthy soil\n✅ Monitoring: Check plants regularly",
  "what are common pests" = "🐛 Common pests:\n- Aphids: Small insects, suck sap\n- Caterpillars: Eat leaves\n- Beetles: Various types damage crops\n- Mites: Tiny spiders, cause yellowing",
  "how to prevent diseases" = "🦠 Disease prevention:\n✅ Plant resistant varieties\n✅ Proper spacing for air circulation\n✅ Avoid overhead watering\n✅ Clean tools & equipment\n✅ Crop rotation",
  "what fertilizer to use" = "🌱 Fertilizer choice:\n- Nitrogen: For leafy growth (urea, ammonium nitrate)\n- Phosphorus: For roots & flowers (superphosphate)\n- Potassium: For fruit quality (potash)\n- Organic: Compost, manure (slower but safer)",
  "organic fertilizer" = "🌱 Organic fertilizers:\n✅ Compost: Decomposed plant matter\n✅ Manure: Animal waste (aged)\n✅ Bone meal: For phosphorus\n✅ Fish emulsion: Quick nitrogen boost\n✅ Blood meal: High nitrogen",
  "what is crop rotation" = "🌾 Crop rotation:\n- Plant different crops in sequence\n- Prevents soil depletion\n- Reduces pest/disease buildup\n- Improves soil structure\n- Example: Wheat → Legumes → Corn",
  "how to prepare for drought" = "🌵 Drought preparation:\n✅ Mulch to retain moisture\n✅ Choose drought-tolerant varieties\n✅ Deep watering less frequently\n✅ Use drip irrigation\n✅ Monitor soil moisture",
  "what to do in flood" = "🌊 Flood response:\n✅ Remove standing water quickly\n✅ Check for root rot\n✅ Replant if needed\n✅ Improve drainage\n✅ Use raised beds next time",
  "when to harvest" = "🌾 Harvest timing:\n- Wheat: When grains are hard, straw yellow\n- Tomatoes: When fully colored, slightly soft\n- Olives: When fruit changes color\n- Grapes: When sugar content optimal\nCheck specific crop guides",
  "how to store crops" = "📦 Crop storage:\n✅ Cool, dry, dark place\n✅ Good ventilation\n✅ Check for pests regularly\n✅ Use proper containers\n✅ Some crops need curing first",
  "sustainable farming" = "🌱 Sustainable practices:\n✅ Crop rotation\n✅ Organic fertilizers\n✅ Integrated pest management\n✅ Water conservation\n✅ Soil conservation\n✅ Biodiversity promotion",
  "what is organic farming" = "🌱 Organic farming:\n- No synthetic pesticides/fertilizers\n- Natural pest control\n- Organic compost/manure\n- Crop rotation\n- Soil health focus\n- Environmentally friendly",
  "tunisian agriculture" = "🇹🇳 Tunisia agriculture:\n- Mediterranean climate\n- Main crops: Wheat, olives, dates\n- Irrigation from dams & groundwater\n- Challenges: Water scarcity, soil erosion\n- Opportunities: Export potential, tourism",
  "best crops for tunisia" = "🇹🇳 Best Tunisian crops:\n🌾 Cereals: Wheat, barley (northern regions)\n🫒 Olives: Central & southern\n🍇 Grapes: Coastal areas\n🥭 Dates: Sahara oases\n🍅 Vegetables: Market gardens",
  "farming tools" = "🛠️ Essential tools:\n- Hoe: Weed control\n- Shovel: Digging & planting\n- Rake: Soil leveling\n- Pruners: Plant trimming\n- Irrigation system: Water delivery\n- Tractor: Large operations",
  "irrigation systems" = "💧 Irrigation types:\n- Drip: Water-efficient, precise\n- Sprinkler: Even coverage\n- Flood: Simple but wasteful\n- Center pivot: Large fields\nChoose based on crop, soil, water availability",
  "farming costs" = "💰 Main farming costs:\n- Seeds/seedlings\n- Fertilizers & pesticides\n- Irrigation water\n- Labor\n- Equipment maintenance\n- Land rent/taxes",
  "how to increase profit" = "💰 Profit improvement:\n✅ Higher yields through better practices\n✅ Value-added products (processing)\n✅ Direct marketing to consumers\n✅ Crop diversification\n✅ Cost control & efficiency",
  "thank you" = "😊 You're welcome! Ask anytime!",
  "thanks" = "😊 Happy to help! More questions?",
  "bye" = "👋 Goodbye! Good luck farming!",
  "goodbye" = "👋 Goodbye! Good luck farming!",
  "see you" = "👋 See you later! Happy farming!"
)

QUALITY_LABELS <- c("low", "moderate", "good", "excellent")
MODEL_NAMES <- c("random_forest", "gradient_boosting", "stacking")

parse_json_body <- function(req) {
  body_text <- req$postBody %||% ""
  if (!nzchar(body_text)) return(list())
  jsonlite::fromJSON(body_text, simplifyVector = FALSE)
}

normalize_prediction_payload <- function(payload) {
  if (!is.null(payload$features) && is.list(payload$features)) {
    model <- payload$model %||% "gradient_boosting"
    features <- payload$features
  } else {
    model <- "gradient_boosting"
    features <- payload
  }

  data <- list(
    pluviometrie = as.numeric(features$pluviometrie %||% NA_real_),
    temperature = as.numeric(features$temperature %||% NA_real_),
    humidite = as.numeric(features$humidite %||% NA_real_),
    ph = as.numeric(features$ph %||% NA_real_),
    azote = as.numeric(features$azote %||% NA_real_),
    phosphore = as.numeric(features$phosphore %||% NA_real_),
    potassium = as.numeric(features$potassium %||% NA_real_),
    surface = as.numeric(features$surface %||% NA_real_)
  )

  missing_fields <- names(data)[vapply(data, function(value) is.na(value) || !is.finite(value), logical(1))]
  if (length(missing_fields) > 0) {
    stop(structure(
      list(message = paste0("Please provide valid numeric values for: ", paste(missing_fields, collapse = ", ")), status = 400),
      class = "vigorterra_api_error"
    ))
  }

  if (!(model %in% MODEL_NAMES)) {
    stop(structure(
      list(message = paste0("Modèle non supporté: ", model), status = 400),
      class = "vigorterra_api_error"
    ))
  }

  list(model = model, features = data)
}

compute_prediction_random_forest <- function(data) {
  base <- 2.5
  pluie_effect <- min(data$pluviometrie / 400, 1.5) * 0.8
  temp_effect <- if (data$temperature >= 15 && data$temperature <= 25) 0.3 else 0.1
  ph_effect <- if (data$ph >= 6 && data$ph <= 8) 0.4 else 0.1
  nutriments <- (data$azote * 10 + data$phosphore / 50 + data$potassium / 200) * 0.1
  round(base + pluie_effect + temp_effect + ph_effect + nutriments + 0.08, 2)
}

compute_prediction_gradient_boosting <- function(data) {
  rf <- compute_prediction_random_forest(data)
  round(rf + 0.18 + (data$phosphore * 0.0012) + (data$temperature - 22) * 0.01, 2)
}

compute_prediction_stacking <- function(data) {
  rf <- compute_prediction_random_forest(data)
  gb <- compute_prediction_gradient_boosting(data)
  round((0.3 * rf) + (0.7 * gb), 2)
}

evaluate_rendement_quality <- function(rendement) {
  if (rendement < 2.5) return("low")
  if (rendement < 4.0) return("moderate")
  if (rendement < 6.0) return("good")
  "excellent"
}

detect_anomaly <- function(data, rendement) {
  feature_issues <- character(0)

  if (!(data$ph >= 5.5 && data$ph <= 8.5)) feature_issues <- c(feature_issues, "pH out of agronomic range")
  if (data$temperature < 5 || data$temperature > 40) feature_issues <- c(feature_issues, "temperature out of expected range")
  if (data$humidite < 20 || data$humidite > 95) feature_issues <- c(feature_issues, "humidity out of expected range")
  if (data$pluviometrie < 80 || data$pluviometrie > 1200) feature_issues <- c(feature_issues, "rainfall out of expected range")
  if (rendement < 0.5 || rendement > 15) feature_issues <- c(feature_issues, "predicted yield outlier")

  if (length(feature_issues) > 0) {
    return(list(TRUE, paste(feature_issues, collapse = "; ")))
  }

  list(FALSE, NULL)
}

get_local_response <- function(question) {
  q_lower <- tolower(trimws(question %||% ""))

  if (nzchar(q_lower) && !is.null(LOCAL_RESPONSES[[q_lower]])) {
    return(LOCAL_RESPONSES[[q_lower]])
  }

  for (key in names(LOCAL_RESPONSES)) {
    if (nzchar(key) && (grepl(key, q_lower, fixed = TRUE) || grepl(q_lower, key, fixed = TRUE))) {
      return(LOCAL_RESPONSES[[key]])
    }
  }

  keyword_map <- list(
    wheat = LOCAL_RESPONSES[["what is wheat"]],
    barley = LOCAL_RESPONSES[["what is barley"]],
    olive = LOCAL_RESPONSES[["olive farming"]],
    tomato = LOCAL_RESPONSES[["how to grow tomatoes"]],
    rain = LOCAL_RESPONSES[["how does rain affect crops"]],
    temperature = LOCAL_RESPONSES[["what temperature is best for crops"]],
    sun = LOCAL_RESPONSES[["how does sun affect plants"]],
    soil = LOCAL_RESPONSES[["what is soil ph"]],
    nitrogen = LOCAL_RESPONSES[["what is nitrogen"]],
    phosphorus = LOCAL_RESPONSES[["what is phosphorus"]],
    potassium = LOCAL_RESPONSES[["what is potassium"]],
    yield = LOCAL_RESPONSES[["how to increase yield"]],
    water = LOCAL_RESPONSES[["how often to water crops"]],
    plant = LOCAL_RESPONSES[["best time to plant"]]
  )

  for (word in names(keyword_map)) {
    if (grepl(word, q_lower, fixed = TRUE) && !is.null(keyword_map[[word]])) {
      return(keyword_map[[word]])
    }
  }

  NULL
}

format_gemini_request <- function(question) {
  list(
    systemInstruction = list(
      parts = list(list(text = "You are Terra, a helpful agricultural assistant. Answer farming questions concisely. Keep responses under 100 words."))
    ),
    contents = list(
      list(
        role = "user",
        parts = list(list(text = question))
      )
    )
  )
}

call_gemini <- function(question) {
  api_key <- Sys.getenv("GEMINI_API_KEY")
  if (!nzchar(api_key) || api_key == "your_gemini_api_key_here") {
    stop(structure(list(message = "API key not configured", status = 401), class = "vigorterra_api_error"))
  }

  url <- sprintf(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%s",
    api_key
  )

  response <- httr::POST(url, body = format_gemini_request(question), encode = "json", httr::timeout(60))
  status <- httr::status_code(response)
  parsed <- httr::content(response, as = "parsed", type = "application/json", encoding = "UTF-8")

  if (status == 401 || status == 403) {
    stop(structure(list(message = "Invalid API key", status = 401), class = "vigorterra_api_error"))
  }
  if (status == 429) {
    stop(structure(list(message = "API busy. Please try again in 30 seconds.", status = 429), class = "vigorterra_api_error"))
  }
  if (status >= 400) {
    api_message <- parsed$error$message %||% paste0("Gemini request failed with status ", status)
    stop(structure(list(message = api_message, status = 502), class = "vigorterra_api_error"))
  }

  answer <- parsed$candidates[[1]]$content$parts[[1]]$text %||% ""
  if (!nzchar(answer)) {
    stop(structure(list(message = "No response from AI", status = 500), class = "vigorterra_api_error"))
  }

  answer
}

explain_yield_prediction <- function(req) {
  result <- sprintf("📊 **Yield Prediction Analysis**\n\n🎯 **Predicted Yield**: %s %s\n", req$predicted_yield, req$unit %||% "t/ha")

  if (req$predicted_yield < 2) {
    result <- paste0(result, "⚠️ **Low Yield** - Below optimal production levels\n\n")
  } else if (req$predicted_yield < 3.5) {
    result <- paste0(result, "⚠️ **Moderate Yield** - Decent but can improve\n\n")
  } else {
    result <- paste0(result, "✅ **Good Yield** - Solid production level\n\n")
  }

  result <- paste0(
    result,
    "📈 **Model Used**: ", req$model_used %||% "Gradient Boosting", "\n",
    "**Quality**: ", req$yield_quality %||% "Moderate", "\n"
  )

  if ((req$yield_quality %||% "Moderate") == "Moderate") {
    result <- paste0(result, "(Predictions are reasonable, some risk factors present)\n\n")
  } else if ((req$yield_quality %||% "Moderate") == "High") {
    result <- paste0(result, "(Predictions are very reliable)\n\n")
  } else if ((req$yield_quality %||% "Moderate") == "Low") {
    result <- paste0(result, "(Predictions have higher uncertainty)\n\n")
  }

  if (isTRUE(req$anomaly_detected)) {
    result <- paste0(result, "⚠️ **Anomalies Detected** (Conditions Outside Normal Ranges):\n")

    anomaly_list <- character(0)
    if (!is.null(req$anomaly_reasons) && length(req$anomaly_reasons) > 0) {
      for (reason in req$anomaly_reasons) {
        reason_lower <- tolower(reason)
        if (grepl("ph", reason_lower, fixed = TRUE)) {
          anomaly_list <- c(anomaly_list, "🥔 **Soil pH** - Outside agronomic range (optimal: 6-7.5)")
        } else if (grepl("temperature", reason_lower, fixed = TRUE)) {
          anomaly_list <- c(anomaly_list, "🌡️ **Temperature** - Outside expected range for crop")
        } else if (grepl("humidity", reason_lower, fixed = TRUE)) {
          anomaly_list <- c(anomaly_list, "💧 **Humidity** - Outside optimal range (ideal: 40-70%)")
        } else if (grepl("rainfall", reason_lower, fixed = TRUE)) {
          anomaly_list <- c(anomaly_list, "🌧️ **Rainfall** - Outside expected amount")
        }
      }
    }

    if (length(anomaly_list) > 0) {
      result <- paste0(result, paste0("- ", anomaly_list, collapse = "\n"), "\n\n💡 **How to Fix**:\n", "✅ Adjust irrigation to match rainfall needs\n", "✅ Consider soil amendments for pH correction\n", "✅ Monitor temperature-sensitive growth stages\n", "✅ Fine-tune watering for humidity control\n", "✅ Choose crop varieties suited to your climate\n")
    }
  } else {
    result <- paste0(result, "✅ **No Anomalies** - All conditions are within normal ranges!\nYour farming conditions are well-optimized.\n")
  }

  result
}

api_error_response <- function(err, res) {
  status <- err$status %||% 500
  res$status <- status
  list(detail = err$message %||% "Unexpected error")
}

general_error_response <- function(err, res) {
  res$status <- 500
  list(detail = conditionMessage(err))
}

#* @serializer json
#* @get /health
function(req, res) {
  service_payload()
}

#* @serializer json
#* @get /api/health
function(req, res) {
  service_payload()
}

#* @serializer json
#* @post /api/predict
function(req, res) {
  tryCatch({
    payload <- parse_json_body(req)
    normalized <- normalize_prediction_payload(payload)

    model <- normalized$model
    features <- normalized$features

    predictor <- switch(
      model,
      random_forest = compute_prediction_random_forest,
      gradient_boosting = compute_prediction_gradient_boosting,
      stacking = compute_prediction_stacking,
      NULL
    )

    if (is.null(predictor)) {
      stop(structure(list(message = paste0("Modèle non supporté: ", model), status = 400), class = "vigorterra_api_error"))
    }

    rendement <- predictor(features)
    rendement_quality <- evaluate_rendement_quality(rendement)
    anomaly <- detect_anomaly(features, rendement)

    list(
      rendement_t_ha = rendement,
      unit = "t/ha",
      model = model,
      rendement_quality = rendement_quality,
      anomaly_detected = anomaly[[1]],
      anomaly_reason = anomaly[[2]]
    )
  }, vigorterra_api_error = function(err) api_error_response(err, res), error = function(err) general_error_response(err, res))
}

#* @serializer json
#* @post /api/ask
function(req, res) {
  tryCatch({
    payload <- parse_json_body(req)
    question <- payload$question %||% ""

    if (!nzchar(trimws(question))) {
      stop(structure(list(message = "Please ask me something!", status = 400), class = "vigorterra_api_error"))
    }

    local_response <- get_local_response(question)
    if (!is.null(local_response)) {
      return(list(answer = local_response))
    }

    current_time <- as.numeric(Sys.time())
    last_request_time <- getOption("vigorterra.last_request_time", default = 0)
    time_since_last <- current_time - last_request_time
    if (time_since_last < 15) {
      wait_time <- as.integer(15 - time_since_last) + 1
      stop(structure(list(message = paste0("Please wait ", wait_time, "s before next question"), status = 429), class = "vigorterra_api_error"))
    }
    options(vigorterra.last_request_time = current_time)

    answer <- call_gemini(question)
    list(answer = answer)
  }, vigorterra_api_error = function(err) api_error_response(err, res), error = function(err) general_error_response(err, res))
}

#* @serializer json
#* @post /api/explain-yield
function(req, res) {
  tryCatch({
    payload <- parse_json_body(req)
    list(answer = explain_yield_prediction(payload))
  }, vigorterra_api_error = function(err) api_error_response(err, res), error = function(err) general_error_response(err, res))
}
