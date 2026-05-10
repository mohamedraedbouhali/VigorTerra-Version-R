# -*- coding: utf-8 -*-
"""
Script principal de collecte des données pour le projet
"Prédiction du rendement agricole à partir des conditions climatiques et du sol en Tunisie".

Sources:
  - FAOSTAT: rendement, production, surface cultivée
  - Open-Meteo: température, précipitations, humidité
  - Agridata.tn: pluviométrie, production (si disponible)
  - INM meteo.tn: données climatiques (complément)
  - Données sol (générées): pH, N, P, K

Usage:
  python scripts/main_collector.py [dossier_sortie]
  Par défaut: data/
"""

import sys
from pathlib import Path

# Ajouter la racine du projet au path
ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.scraping import agridata_scraper, faostat_api, meteo_scraper, openmeteo_api, soil_data_generator


def run_collection(output_dir: str | Path) -> dict:
    """
    Lance toute la collecte et enregistre les CSV dans output_dir.
    Retourne un résumé par source.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    summary = {}

    # 1) FAOSTAT - rendement, production, surface
    print("--- FAOSTAT (rendement, production, surface) ---")
    try:
        df_fao = faostat_api.download_faostat_crops_tunisia(output_dir)
        summary["faostat"] = len(df_fao)
        print(f"  Lignes: {len(df_fao)}")
    except Exception as e:
        summary["faostat"] = 0
        print(f"  Erreur: {e}")

    # 2) Open-Meteo - climat
    print("--- Open-Meteo (température, pluie, humidité) ---")
    try:
        df_om = openmeteo_api.save_openmeteo_tunisia(output_dir)
        summary["openmeteo"] = len(df_om)
        print(f"  Lignes: {len(df_om)}")
    except Exception as e:
        summary["openmeteo"] = 0
        print(f"  Erreur: {e}")

    # 3) Agridata - pluviométrie / production
    print("--- Agridata (pluviométrie, production) ---")
    try:
        df_pluv = agridata_scraper.scrape_agridata_pluviometry(output_dir)
        df_prod = agridata_scraper.scrape_agridata_production(output_dir)
        summary["agridata_pluviometry"] = len(df_pluv)
        summary["agridata_production"] = len(df_prod)
        print(f"  Pluviométrie: {len(df_pluv)}, Production: {len(df_prod)}")
    except Exception as e:
        summary["agridata_pluviometry"] = summary["agridata_production"] = 0
        print(f"  Erreur: {e}")

    # 4) INM meteo.tn
    print("--- INM meteo.tn ---")
    try:
        df_inm = meteo_scraper.collect_inm_data(output_dir)
        summary["meteo_tn"] = len(df_inm)
        print(f"  Lignes: {len(df_inm)}")
    except Exception as e:
        summary["meteo_tn"] = 0
        print(f"  Erreur: {e}")

    # 5) Données sol (générées)
    print("--- Données sol (pH, N, P, K) ---")
    try:
        df_soil = soil_data_generator.save_soil_data(output_dir)
        summary["soil"] = len(df_soil)
        print(f"  Lignes: {len(df_soil)}")
    except Exception as e:
        summary["soil"] = 0
        print(f"  Erreur: {e}")

    # 6) Fusion pour ML (si preprocessing disponible)
    print("--- Fusion des données ---")
    try:
        from scripts.preprocessing.data_merger import merge_all_to_ml_dataset
        merged_path = merge_all_to_ml_dataset(output_dir)
        summary["merged_ml"] = str(merged_path)
        print(f"  Fichier fusionné: {merged_path}")
    except Exception as e:
        summary["merged_ml"] = None
        print(f"  Fusion: {e}")

    return summary


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "data")
    print(f"Sortie: {out}\n")
    run_collection(out)
    print("\nCollecte terminée.")
