from collections.abc import Callable
from typing import Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter()

ModelName = Literal["random_forest", "gradient_boosting", "stacking"]
QualityLabel = Literal["low", "moderate", "good", "excellent"]


class PredictionInput(BaseModel):
    """Données météo et sol pour la prédiction du rendement."""

    pluviometrie: float = Field(..., ge=0, description="Pluviométrie (mm)")
    temperature: float = Field(..., description="Température moyenne (°C)")
    humidite: float = Field(..., ge=0, le=100, description="Humidité (%)")
    ph: float = Field(..., ge=0, le=14, description="pH du sol")
    azote: float = Field(..., ge=0, description="Azote N (%)")
    phosphore: float = Field(..., ge=0, description="Phosphore P (mg/kg)")
    potassium: float = Field(..., ge=0, description="Potassium K (mg/kg)")
    surface: float = Field(..., ge=0, description="Surface cultivée (ha)")


class PredictionRequest(BaseModel):
    model: ModelName = Field(default="gradient_boosting", description="Modèle sélectionné côté frontend")
    features: PredictionInput


class PredictionResponse(BaseModel):
    """Résultat de la prédiction du rendement."""

    rendement_t_ha: float = Field(..., description="Rendement prédit (t/ha)")
    unit: str = "t/ha"
    model: ModelName = "gradient_boosting"
    rendement_quality: QualityLabel = Field(..., description="Niveau de qualité du rendement")
    anomaly_detected: bool = Field(..., description="Indique si une anomalie est détectée")
    anomaly_reason: str | None = Field(default=None, description="Raison de l'anomalie")


def _compute_prediction_random_forest(data: PredictionInput) -> float:
    """Baseline Random Forest-style approximation for yield prediction."""
    base = 2.5
    pluie_effect = min(data.pluviometrie / 400, 1.5) * 0.8
    temp_effect = 0.3 if 15 <= data.temperature <= 25 else 0.1
    ph_effect = 0.4 if 6 <= data.ph <= 8 else 0.1
    nutriments = (data.azote * 10 + data.phosphore / 50 + data.potassium / 200) * 0.1
    tuned = base + pluie_effect + temp_effect + ph_effect + nutriments + 0.08
    return round(tuned, 2)


def _compute_prediction_gradient_boosting(data: PredictionInput) -> float:
    """Gradient Boosting-inspired approximation with stronger non-linear fit."""
    rf = _compute_prediction_random_forest(data)
    value = rf + 0.18 + (data.phosphore * 0.0012) + (data.temperature - 22) * 0.01
    return round(value, 2)


def _compute_prediction_stacking(data: PredictionInput) -> float:
    """Stacking approximation combining RF and GB predictions."""
    rf = _compute_prediction_random_forest(data)
    gb = _compute_prediction_gradient_boosting(data)
    value = (0.3 * rf) + (0.7 * gb)
    return round(value, 2)


MODEL_PREDICTORS: dict[ModelName, Callable[[PredictionInput], float]] = {
    "random_forest": _compute_prediction_random_forest,
    "gradient_boosting": _compute_prediction_gradient_boosting,
    "stacking": _compute_prediction_stacking,
}


def _evaluate_rendement_quality(rendement: float) -> QualityLabel:
    if rendement < 2.5:
        return "low"
    if rendement < 4.0:
        return "moderate"
    if rendement < 6.0:
        return "good"
    return "excellent"


def _detect_anomaly(data: PredictionInput, rendement: float) -> tuple[bool, str | None]:
    feature_issues: list[str] = []

    if not 5.5 <= data.ph <= 8.5:
        feature_issues.append("pH out of agronomic range")
    if data.temperature < 5 or data.temperature > 40:
        feature_issues.append("temperature out of expected range")
    if data.humidite < 20 or data.humidite > 95:
        feature_issues.append("humidity out of expected range")
    if data.pluviometrie < 80 or data.pluviometrie > 1200:
        feature_issues.append("rainfall out of expected range")

    if rendement < 0.5 or rendement > 15:
        feature_issues.append("predicted yield outlier")

    if feature_issues:
        return True, "; ".join(feature_issues)

    return False, None


@router.post("/predict", response_model=PredictionResponse)
def predict_rendement(data: PredictionRequest | PredictionInput):
    """Prédit le rendement selon le modèle sélectionné côté frontend."""
    try:
        if isinstance(data, PredictionInput):
            model = "gradient_boosting"
            features = data
        else:
            model = data.model
            features = data.features

        predictor = MODEL_PREDICTORS.get(model)
        if predictor is None:
            raise HTTPException(status_code=400, detail=f"Modèle non supporté: {model}")

        rendement = predictor(features)
        rendement_quality = _evaluate_rendement_quality(rendement)
        anomaly_detected, anomaly_reason = _detect_anomaly(features, rendement)

        return PredictionResponse(
            rendement_t_ha=rendement,
            model=model,
            rendement_quality=rendement_quality,
            anomaly_detected=anomaly_detected,
            anomaly_reason=anomaly_reason,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e
