from typing import Literal

import requests as http_client
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter()

ModelName = Literal["random_forest", "gradient_boosting", "stacking"]
QualityLabel = Literal["low", "moderate", "good", "excellent"]

R_PLUMBER_URL = "http://localhost:8001/predict"


class PredictionInput(BaseModel):
    pluviometrie: float = Field(..., ge=0, description="Pluviométrie (mm)")
    temperature: float = Field(..., description="Température moyenne (°C)")
    humidite: float = Field(..., ge=0, le=100, description="Humidité (%)")
    ph: float = Field(..., ge=0, le=14, description="pH du sol")
    azote: float = Field(..., ge=0, description="Azote N (%)")
    phosphore: float = Field(..., ge=0, description="Phosphore P (mg/kg)")
    potassium: float = Field(..., ge=0, description="Potassium K (mg/kg)")
    surface: float = Field(..., ge=0, description="Surface cultivée (ha)")


class PredictionRequest(BaseModel):
    model: ModelName = Field(default="gradient_boosting")
    features: PredictionInput


class PredictionResponse(BaseModel):
    rendement_t_ha: float
    unit: str = "t/ha"
    model: ModelName = "gradient_boosting"
    rendement_quality: QualityLabel
    anomaly_detected: bool
    anomaly_reason: str | None = None


@router.post("/predict", response_model=PredictionResponse)
def predict_rendement(data: PredictionRequest | PredictionInput):
    """Proxy vers le service de prédiction R (plumber) sur le port 8001."""
    if isinstance(data, PredictionInput):
        payload = {"model": "gradient_boosting", "features": data.model_dump()}
    else:
        payload = {"model": data.model, "features": data.features.model_dump()}

    try:
        response = http_client.post(R_PLUMBER_URL, json=payload, timeout=10)
        response.raise_for_status()
        return response.json()
    except http_client.ConnectionError:
        raise HTTPException(
            status_code=503,
            detail="R prediction service unavailable. Start plumber.R on port 8001.",
        )
    except http_client.HTTPError as e:
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
