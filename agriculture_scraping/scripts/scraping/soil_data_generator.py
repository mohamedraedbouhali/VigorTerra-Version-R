# -*- coding: utf-8 -*-
"""
Génération de données pédologiques (pH, N, P, K) pour la Tunisie.
Les données réelles N/P/K/pH par parcelle sont rarement disponibles en open data.
Ce module produit des valeurs réalistes par région/gouvernorat pour compléter
le dataset (à remplacer par de vraies données si disponibles).
"""

from pathlib import Path

import numpy as np
import pandas as pd

# Gouvernorats tunisiens (approximatif) avec plages typiques pour sols méditerranéens
REGIONS_SOIL = [
    {"region": "Nord", "gov": "Tunis", "ph_min": 7.2, "ph_max": 8.2, "n_min": 0.05, "n_max": 0.25, "p_min": 15, "p_max": 80, "k_min": 120, "k_max": 400},
    {"region": "Nord", "gov": "Bizerte", "ph_min": 7.0, "ph_max": 8.0, "n_min": 0.06, "n_max": 0.28, "p_min": 18, "p_max": 85, "k_min": 130, "k_max": 420},
    {"region": "Nord", "gov": "Beja", "ph_min": 6.8, "ph_max": 7.8, "n_min": 0.05, "n_max": 0.22, "p_min": 12, "p_max": 70, "k_min": 100, "k_max": 350},
    {"region": "Nord", "gov": "Jendouba", "ph_min": 6.5, "ph_max": 7.5, "n_min": 0.06, "n_max": 0.26, "p_min": 15, "p_max": 75, "k_min": 110, "k_max": 380},
    {"region": "Nord", "gov": "Nabeul", "ph_min": 7.2, "ph_max": 8.3, "n_min": 0.04, "n_max": 0.20, "p_min": 14, "p_max": 72, "k_min": 115, "k_max": 360},
    {"region": "Centre", "gov": "Sousse", "ph_min": 7.3, "ph_max": 8.4, "n_min": 0.04, "n_max": 0.18, "p_min": 12, "p_max": 65, "k_min": 100, "k_max": 320},
    {"region": "Centre", "gov": "Sfax", "ph_min": 7.5, "ph_max": 8.5, "n_min": 0.03, "n_max": 0.16, "p_min": 10, "p_max": 58, "k_min": 90, "k_max": 300},
    {"region": "Centre", "gov": "Kairouan", "ph_min": 7.2, "ph_max": 8.2, "n_min": 0.04, "n_max": 0.19, "p_min": 11, "p_max": 62, "k_min": 95, "k_max": 310},
    {"region": "Centre", "gov": "Kef", "ph_min": 6.8, "ph_max": 7.8, "n_min": 0.05, "n_max": 0.22, "p_min": 14, "p_max": 68, "k_min": 105, "k_max": 340},
    {"region": "Sud", "gov": "Gabes", "ph_min": 7.6, "ph_max": 8.6, "n_min": 0.03, "n_max": 0.14, "p_min": 8, "p_max": 50, "k_min": 85, "k_max": 280},
    {"region": "Sud", "gov": "Medenine", "ph_min": 7.5, "ph_max": 8.5, "n_min": 0.03, "n_max": 0.15, "p_min": 9, "p_max": 52, "k_min": 88, "k_max": 290},
    {"region": "Sud", "gov": "Tozeur", "ph_min": 7.8, "ph_max": 8.8, "n_min": 0.02, "n_max": 0.12, "p_min": 7, "p_max": 45, "k_min": 80, "k_max": 260},
    {"region": "Sud", "gov": "Kebili", "ph_min": 7.7, "ph_max": 8.7, "n_min": 0.02, "n_max": 0.13, "p_min": 8, "p_max": 48, "k_min": 82, "k_max": 270},
]


def generate_soil_data(
    years: list[int] | None = None,
    rows_per_region_year: int = 5,
    seed: int = 42,
) -> pd.DataFrame:
    """
    Génère un DataFrame avec colonnes: year, region, governorate, ph, nitrogen_N, phosphorus_P, potassium_K.
    nitrogen en % (rapport massique typique), P et K en mg/kg (ou ppm).
    """
    np.random.seed(seed)
    if years is None:
        years = list(range(2010, 2024))

    rows = []
    for rec in REGIONS_SOIL:
        for year in years:
            for _ in range(rows_per_region_year):
                ph = np.random.uniform(rec["ph_min"], rec["ph_max"])
                n = np.random.uniform(rec["n_min"], rec["n_max"])
                p = np.random.uniform(rec["p_min"], rec["p_max"])
                k = np.random.uniform(rec["k_min"], rec["k_max"])
                rows.append({
                    "year": year,
                    "region": rec["region"],
                    "governorate": rec["gov"],
                    "ph": round(ph, 2),
                    "nitrogen_N": round(n, 4),
                    "phosphorus_P_mg_kg": round(p, 1),
                    "potassium_K_mg_kg": round(k, 1),
                })
    return pd.DataFrame(rows)


def save_soil_data(output_dir: str | Path) -> pd.DataFrame:
    """Génère et enregistre les données sol dans data/soil_tunisia.csv."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    df = generate_soil_data()
    out_path = output_dir / "soil_tunisia.csv"
    df.to_csv(out_path, index=False, encoding="utf-8-sig")
    return df


if __name__ == "__main__":
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else "data"
    df = save_soil_data(out)
    print(f"Lignes sol: {len(df)}")
    print(df.head(10))
