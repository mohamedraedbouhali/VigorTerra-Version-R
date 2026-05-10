# -*- coding: utf-8 -*-
"""
Open-Meteo API - Température, précipitations, humidité pour la Tunisie.
Source: https://open-meteo.com
Utilise l'API Archive pour données historiques et Forecast pour données récentes.
"""

from pathlib import Path

import pandas as pd
import requests

# Tunis (capitale) - coordonnées
TUNISIA_COORDS = [
    {"name": "Tunis", "lat": 36.8065, "lon": 10.1815},
    {"name": "Sfax", "lat": 34.7406, "lon": 10.7603},
    {"name": "Sousse", "lat": 35.8256, "lon": 10.6346},
    {"name": "Kairouan", "lat": 35.6781, "lon": 10.0963},
    {"name": "Bizerte", "lat": 37.2744, "lon": 9.8739},
    {"name": "Gabes", "lat": 33.8815, "lon": 10.0982},
    {"name": "Beja", "lat": 36.7256, "lon": 9.1817},
]

BASE_FORECAST = "https://api.open-meteo.com/v1/forecast"
ARCHIVE_API = "https://archive-api.open-meteo.com/v1/archive"


def fetch_openmeteo_daily(
    latitude: float,
    longitude: float,
    start_date: str,
    end_date: str,
    timezone: str = "Africa/Tunis",
) -> pd.DataFrame:
    """
    Récupère les données quotidiennes (température, pluie, humidité) pour une période.
    start_date / end_date: format YYYY-MM-DD.
    """
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start_date,
        "end_date": end_date,
        "timezone": timezone,
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "temperature_2m_mean",
            "precipitation_sum",
            "relative_humidity_2m_mean",
        ],
    }
    r = requests.get(ARCHIVE_API, params=params, timeout=30)
    r.raise_for_status()
    data = r.json()
    daily = data.get("daily", {})
    if not daily:
        return pd.DataFrame()
    mean_t = daily.get("temperature_2m_mean")
    if mean_t is None and "temperature_2m_max" in daily and "temperature_2m_min" in daily:
        mean_t = [(a + b) / 2 for a, b in zip(daily["temperature_2m_max"], daily["temperature_2m_min"])]
    df = pd.DataFrame({
        "date": pd.to_datetime(daily["time"]),
        "temperature_max_c": daily["temperature_2m_max"],
        "temperature_min_c": daily["temperature_2m_min"],
        "temperature_mean_c": mean_t,
        "precipitation_mm": daily["precipitation_sum"],
        "relative_humidity_pct": daily["relative_humidity_2m_mean"],
    })
    df["latitude"] = latitude
    df["longitude"] = longitude
    return df


def fetch_openmeteo_forecast_past_days(
    latitude: float,
    longitude: float,
    past_days: int = 92,
    timezone: str = "Africa/Tunis",
) -> pd.DataFrame:
    """
    Données des N derniers jours via l'API forecast (past_days).
    Utile quand l'archive n'est pas disponible pour les dates très récentes.
    """
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "past_days": past_days,
        "forecast_days": 0,
        "timezone": timezone,
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "temperature_2m_mean",
            "precipitation_sum",
            "relative_humidity_2m_mean",
        ],
    }
    r = requests.get(BASE_FORECAST, params=params, timeout=30)
    r.raise_for_status()
    data = r.json()
    daily = data.get("daily", {})
    if not daily:
        return pd.DataFrame()
    mean_t = daily.get("temperature_2m_mean")
    if mean_t is None and "temperature_2m_max" in daily and "temperature_2m_min" in daily:
        mean_t = [(a + b) / 2 for a, b in zip(daily["temperature_2m_max"], daily["temperature_2m_min"])]
    df = pd.DataFrame({
        "date": pd.to_datetime(daily["time"]),
        "temperature_max_c": daily["temperature_2m_max"],
        "temperature_min_c": daily["temperature_2m_min"],
        "temperature_mean_c": mean_t,
        "precipitation_mm": daily["precipitation_sum"],
        "relative_humidity_pct": daily["relative_humidity_2m_mean"],
    })
    df["latitude"] = latitude
    df["longitude"] = longitude
    return df


def collect_tunisia_climate(
    start_date: str = "2015-01-01",
    end_date: str | None = None,
    use_archive: bool = True,
    locations: list[dict] | None = None,
) -> pd.DataFrame:
    """
    Agrège les données climatiques pour plusieurs points en Tunisie.
    Si use_archive=True, utilise l'API archive (si disponible);
    sinon utilise forecast avec past_days pour les ~3 derniers mois.
    """
    import datetime
    if end_date is None:
        end_date = datetime.date.today().isoformat()
    locations = locations or TUNISIA_COORDS
    all_dfs = []

    for loc in locations:
        lat, lon = loc["lat"], loc["lon"]
        name = loc.get("name", "point")
        try:
            if use_archive:
                df = fetch_openmeteo_daily(lat, lon, start_date, end_date)
            else:
                df = fetch_openmeteo_forecast_past_days(lat, lon, past_days=90)
            df["location"] = name
            all_dfs.append(df)
        except Exception as e:
            print(f"Open-Meteo {name}: {e}")
            continue

    if not all_dfs:
        return pd.DataFrame()
    out = pd.concat(all_dfs, ignore_index=True)
    return out


def save_openmeteo_tunisia(output_dir: str | Path) -> pd.DataFrame:
    """
    Récupère les données Open-Meteo pour la Tunisie et les enregistre en CSV.
    Tente d'abord l'archive (historique), puis forecast (données récentes) si besoin.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Essayer archive (données historiques)
    try:
        df = collect_tunisia_climate(
            start_date="2015-01-01",
            end_date=None,
            use_archive=True,
        )
    except Exception:
        df = pd.DataFrame()

    if df.empty:
        # Fallback: dernières semaines via forecast
        df = collect_tunisia_climate(use_archive=False)

    if not df.empty:
        out_path = output_dir / "openmeteo_tunisia.csv"
        df.to_csv(out_path, index=False, encoding="utf-8-sig")
        # Agrégation annuelle pour fusion avec FAOSTAT (année, pluviométrie, T° moyenne, humidité)
        df["year"] = pd.to_datetime(df["date"]).dt.year
        annual = df.groupby(["year", "location"]).agg({
            "precipitation_mm": "sum",
            "temperature_mean_c": "mean",
            "relative_humidity_pct": "mean",
        }).reset_index()
        annual_path = output_dir / "openmeteo_tunisia_annual.csv"
        annual.to_csv(annual_path, index=False, encoding="utf-8-sig")
    return df


if __name__ == "__main__":
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else "data"
    df = save_openmeteo_tunisia(out)
    print(f"Lignes Open-Meteo: {len(df)}")
    if not df.empty:
        print(df.head(10))
