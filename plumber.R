# =============================================================================
# VigorTerra — API de prédiction du rendement agricole (Tunisie)
# Langage : R  |  Framework web : plumber
#
# Comment lancer ce fichier dans RStudio :
#   library(plumber)
#   plumb("plumber.R")$run(port = 8001)
#
# L'API sera disponible sur : http://localhost:8001
# Documentation interactive  : http://localhost:8001/__docs__
# =============================================================================


# -----------------------------------------------------------------------------
# 1. CHARGEMENT DES BIBLIOTHÈQUES
# -----------------------------------------------------------------------------

# plumber  : transforme les fonctions R en endpoints HTTP (comme Flask en Python)
library(plumber)

# jsonlite : lit et écrit le format JSON (le format d'échange avec le frontend)
library(jsonlite)


# =============================================================================
# 2. FONCTIONS DE PRÉDICTION
#    Chaque fonction reçoit un objet "f" qui contient les données du sol/climat.
#    Elle retourne un nombre : le rendement estimé en tonnes par hectare (t/ha).
# =============================================================================

# -----------------------------------------------------------------------------
# MODÈLE 1 — Random Forest (approximation)
#
# Principe : on part d'une base fixe, puis on ajoute ou retire des points
# selon chaque condition climatique/sol.
# -----------------------------------------------------------------------------
compute_rf <- function(f) {

  # Point de départ : rendement moyen de référence en Tunisie
  base <- 2.5

  # Effet de la pluie :
  #   - on divise par 400 pour ramener à une échelle 0-1
  #   - min(..., 1.5) : plafonné à 1.5 pour éviter les valeurs trop élevées
  #   - multiplié par 0.8 : la pluie peut ajouter au maximum +1.2 t/ha
  pluie_effect <- min(f$pluviometrie / 400, 1.5) * 0.8

  # Effet de la température :
  #   - +0.3 si la température est dans la plage idéale (15°C à 25°C)
  #   - +0.1 sinon (trop froid ou trop chaud = mauvaise croissance)
  temp_effect <- if (f$temperature >= 15 && f$temperature <= 25) 0.3 else 0.1

  # Effet du pH du sol :
  #   - +0.4 si le pH est neutre (6 à 8) — idéal pour la plupart des céréales
  #   - +0.1 sinon (sol trop acide ou trop basique)
  ph_effect <- if (f$ph >= 6 && f$ph <= 8) 0.4 else 0.1

  # Effet des nutriments du sol (NPK) :
  #   - azote    : très impactant, multiplié par 10
  #   - phosphore: divisé par 50 pour normaliser son unité (mg/kg)
  #   - potassium: divisé par 200 pour normaliser son unité (mg/kg)
  #   - le tout multiplié par 0.1 pour garder une contribution raisonnable
  nutriments <- (f$azote * 10 + f$phosphore / 50 + f$potassium / 200) * 0.1

  # Correction de calibration (+0.08) pour ajuster le modèle sur les données réelles
  # On arrondit le résultat à 2 décimales
  round(base + pluie_effect + temp_effect + ph_effect + nutriments + 0.08, 2)
}


# -----------------------------------------------------------------------------
# MODÈLE 2 — Gradient Boosting (approximation)
#
# Principe : on part du résultat Random Forest et on ajoute des corrections
# non-linéaires pour affiner la prédiction.
# -----------------------------------------------------------------------------
compute_gb <- function(f) {

  # On récupère d'abord la prédiction du modèle Random Forest
  rf <- compute_rf(f)

  # On y ajoute :
  #   +0.18                      : correction générale (le GB est légèrement meilleur)
  #   f$phosphore * 0.0012       : le phosphore a un effet supplémentaire en GB
  #   (f$temperature - 22) * 0.01: correction fine autour de 22°C (optimum céréalier)
  round(rf + 0.18 + (f$phosphore * 0.0012) + (f$temperature - 22) * 0.01, 2)
}


# -----------------------------------------------------------------------------
# MODÈLE 3 — Stacking (combinaison des deux modèles)
#
# Principe : on fait une moyenne pondérée des deux modèles.
# Le GB est plus précis, donc on lui donne un poids plus élevé (70%).
# -----------------------------------------------------------------------------
compute_stacking <- function(f) {

  # Calcul des deux prédictions de base
  rf <- compute_rf(f)
  gb <- compute_gb(f)

  # Combinaison : 30% Random Forest + 70% Gradient Boosting
  round(0.3 * rf + 0.7 * gb, 2)
}


# =============================================================================
# 3. FONCTIONS D'ÉVALUATION
#    Ces fonctions analysent le résultat de la prédiction.
# =============================================================================

# -----------------------------------------------------------------------------
# Qualité du rendement
# Convertit un nombre (t/ha) en étiquette lisible.
# -----------------------------------------------------------------------------
evaluate_quality <- function(rendement) {

  if      (rendement < 2.5) "low"       # Faible : moins de 2.5 t/ha
  else if (rendement < 4.0) "moderate"  # Moyen  : entre 2.5 et 4 t/ha
  else if (rendement < 6.0) "good"      # Bon    : entre 4 et 6 t/ha
  else                       "excellent" # Excellent : plus de 6 t/ha
}


# -----------------------------------------------------------------------------
# Détection d'anomalies
# Vérifie si les valeurs d'entrée ou le résultat sont hors des plages normales.
# Retourne une liste avec un booléen et une explication texte.
# -----------------------------------------------------------------------------
detect_anomaly <- function(f, rendement) {

  # On commence avec une liste vide de problèmes
  issues <- character(0)

  # Vérification de chaque variable :
  if (f$ph < 5.5          || f$ph > 8.5)           issues <- c(issues, "pH hors de la plage agronomique")
  if (f$temperature < 5   || f$temperature > 40)    issues <- c(issues, "température hors de la plage normale")
  if (f$humidite < 20     || f$humidite > 95)       issues <- c(issues, "humidité hors de la plage normale")
  if (f$pluviometrie < 80 || f$pluviometrie > 1200) issues <- c(issues, "pluviométrie hors de la plage normale")
  if (rendement < 0.5     || rendement > 15)        issues <- c(issues, "rendement prédit anormal")

  # On retourne une liste avec :
  #   - anomaly_detected : TRUE s'il y a au moins un problème, FALSE sinon
  #   - anomaly_reason   : les problèmes joints en une seule phrase, ou NULL
  list(
    anomaly_detected = length(issues) > 0,
    anomaly_reason   = if (length(issues) > 0) paste(issues, collapse = " ; ") else NULL
  )
}


# =============================================================================
# 4. ENDPOINT HTTP
#    La partie plumber : on définit une route POST /predict.
#    Les lignes qui commencent par #* sont des annotations plumber.
# =============================================================================

#* @apiTitle  Rendement Agricole API (R)
#* @apiDescription Prédiction du rendement agricole — Implémentation R / Plumber

#* Reçoit les données climatiques et du sol, retourne le rendement prédit
#* @post /predict
#* @serializer json
function(req, res) {

  # --- Lecture du corps de la requête ---
  # req$postBody contient le JSON envoyé par le frontend (ou par Python)
  # fromJSON le convertit en liste R
  body <- tryCatch(
    fromJSON(req$postBody, simplifyVector = FALSE),
    error = function(e) {
      res$status <- 400          # Code HTTP 400 = mauvaise requête
      stop("JSON invalide dans le corps de la requête")
    }
  )

  # --- Lecture du modèle demandé ---
  # Si le frontend n'envoie pas de modèle, on utilise gradient_boosting par défaut
  model    <- if (!is.null(body$model)) body$model else "gradient_boosting"

  # --- Lecture des données climatiques/sol ---
  features <- body$features

  # Vérification : les données sont-elles présentes ?
  if (is.null(features)) {
    res$status <- 400
    return(list(error = "Champ 'features' manquant dans la requête"))
  }

  # --- Calcul du rendement selon le modèle choisi ---
  # switch() en R fonctionne comme un if/else if/else, mais plus lisible
  rendement <- tryCatch(
    switch(model,
      random_forest     = compute_rf(features),        # Modèle 1
      gradient_boosting = compute_gb(features),        # Modèle 2
      stacking          = compute_stacking(features),  # Modèle 3
      {
        # Cas par défaut : modèle inconnu
        res$status <- 400
        stop(paste("Modèle non reconnu :", model))
      }
    ),
    error = function(e) {
      res$status <- 400
      stop(conditionMessage(e))
    }
  )

  # --- Analyse du résultat ---
  anomaly <- detect_anomaly(features, rendement)

  # --- Réponse JSON renvoyée au client ---
  # plumber convertit automatiquement cette liste en JSON
  list(
    rendement_t_ha    = rendement,                        # Rendement numérique (ex: 3.24)
    unit              = "t/ha",                           # Unité
    model             = model,                            # Modèle utilisé
    rendement_quality = evaluate_quality(rendement),      # Étiquette de qualité
    anomaly_detected  = anomaly$anomaly_detected,         # TRUE ou FALSE
    anomaly_reason    = anomaly$anomaly_reason            # Explication ou NULL
  )
}
