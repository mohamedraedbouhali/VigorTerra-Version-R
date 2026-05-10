import json
import urllib.request

payload = {
    "model": "stacking",
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

req = urllib.request.Request(
    "http://127.0.0.1:8000/api/predict",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"},
    method="POST",
)

with urllib.request.urlopen(req) as resp:
    body = resp.read().decode("utf-8")
    print(resp.status)
    print(body)
