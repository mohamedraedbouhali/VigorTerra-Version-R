from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

payload = {
    "model": "random_forest",
    "features": {
        "pluviometrie": 320,
        "temperature": 21.4,
        "humidite": 64,
        "ph": 6.9,
        "azote": 0.18,
        "phosphore": 42,
        "potassium": 165,
        "surface": 8.5,
    },
}

health = client.get("/health")
predict = client.post("/api/predict", json=payload)

print("HEALTH", health.status_code, health.json())
print("PREDICT", predict.status_code, predict.json())
