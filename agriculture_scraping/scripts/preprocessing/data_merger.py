# -*- coding: utf-8 -*-
"""
Fusion des données collectées en un jeu unique pour le ML.
Colonnes cibles du projet: pluviométrie, température moyenne, humidité, pH, N, P, K,
surface cultivée, année, rendement agricole (variable cible).
"""

from pathlib import Path

import pandas as pd


def load_sources(data_dir: Path) -> dict[str, pd.DataFrame]:
    """Charge les CSV disponibles dans data_dir."""
    data_dir = Path(data_dir)
    out = {}
    # FAOSTAT
    p = data_dir / "faostat_crops_tunisia.csv"
    if p.exists():
        out["faostat"] = pd.read_csv(p, encoding="utf-8-sig", low_memory=False)
    # Open-Meteo annuel
    p = data_dir / "openmeteo_tunisia_annual.csv"
    if p.exists():
        out["openmeteo_annual"] = pd.read_csv(p, encoding="utf-8-sig")
    # Open-Meteo brut
    p = data_dir / "openmeteo_tunisia.csv"
    if p.exists():
        out["openmeteo"] = pd.read_csv(p, encoding="utf-8-sig")
    # Sol
    p = data_dir / "soil_tunisia.csv"
    if p.exists():
        out["soil"] = pd.read_csv(p, encoding="utf-8-sig")
    return out


def faostat_to_yield_table(df: pd.DataFrame) -> pd.DataFrame:
    """Transforme le brut FAOSTAT en table (year, item, area_harvested_ha, production_tonnes, yield_tonnes_per_ha)."""
    if df.empty:
        return pd.DataFrame()
    # FAOSTAT CSV a parfois des colonnes dupliquées : Element (code) et Element.1 (libellé)
    element_col = "Element.1" if "Element.1" in df.columns else "Element"
    if element_col not in df.columns:
        return pd.DataFrame()
    year_col = "Year"  # première colonne Year
    elements = ["Yield", "Production", "Area harvested"]
    sub = df[df[element_col].astype(str).str.strip().isin(elements)].copy()
    cols = [c for c in [year_col, "Item", element_col, "Value"] if c in sub.columns]
    if len(cols) < 4:
        return pd.DataFrame()
    sub = sub[cols].drop_duplicates()
    sub = sub.rename(columns={element_col: "Element", year_col: "Year"})
    piv = sub.pivot_table(index=["Year", "Item"], columns="Element", values="Value", aggfunc="first").reset_index()
    piv = piv.rename(columns={
        "Area harvested": "area_harvested_ha",
        "Production": "production_tonnes",
        "Yield": "yield_value",
    })
    if "yield_value" in piv.columns:
        piv["yield_tonnes_per_ha"] = piv["yield_value"] / 10000.0  # hg/ha -> t/ha
    return piv


def merge_all_to_ml_dataset(data_dir: str | Path) -> Path:
    """
    Fusionne FAOSTAT (rendement, surface, production), climat (Open-Meteo annuel)
    et sol (pH, N, P, K) en un CSV pour le ML.
    Une ligne = une combinaison année × culture (et éventuellement région si agrégation).
    """
    data_dir = Path(data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)
    sources = load_sources(data_dir)

    # Base: rendements FAOSTAT par année et culture
    if "faostat" not in sources or sources["faostat"].empty:
        # Créer un dataset minimal pour test
        ml_df = pd.DataFrame({
            "year": [],
            "item": [],
            "yield_tonnes_per_ha": [],
            "area_harvested_ha": [],
            "production_tonnes": [],
        })
    else:
        ml_df = faostat_to_yield_table(sources["faostat"])
        if ml_df.empty and "Item" in sources["faostat"].columns:
            # Pivot manuel de secours (colonnes Element.1 / Year si doublons)
            df = sources["faostat"]
            element_col = "Element.1" if "Element.1" in df.columns else "Element"
            year_col = "Year"
            if element_col in df.columns:
                elem = df[element_col].astype(str).str.strip()
                for el, name in [("Yield", "yield_tonnes_per_ha"), ("Area harvested", "area_harvested_ha"), ("Production", "production_tonnes")]:
                    sub = df[elem == el][[year_col, "Item", "Value"]].drop_duplicates()
                    sub = sub.rename(columns={year_col: "year", "Item": "item", "Value": name})
                    if ml_df.empty and name == "yield_tonnes_per_ha":
                        ml_df = sub.copy()
                    elif not sub.empty and not ml_df.empty:
                        ml_df = ml_df.merge(sub, on=["year", "item"], how="outer")
        if "yield_value" in ml_df.columns and "yield_tonnes_per_ha" not in ml_df.columns:
            ml_df["yield_tonnes_per_ha"] = ml_df["yield_value"] / 10000.0  # hg/ha -> t/ha

    # Climat annuel moyen (Tunisie): une ligne par année
    if "openmeteo_annual" in sources and not sources["openmeteo_annual"].empty:
        om = sources["openmeteo_annual"]
        if "year" in om.columns:
            climate = om.groupby("year").agg({
                "precipitation_mm": "mean",
                "temperature_mean_c": "mean",
                "relative_humidity_pct": "mean",
            }).reset_index()
            climate = climate.rename(columns={
                "precipitation_mm": "pluviometrie_mm",
                "temperature_mean_c": "temperature_moyenne_c",
                "relative_humidity_pct": "humidite_pct",
            })
            merge_year = "year" if "year" in ml_df.columns else "Year"
            ml_df = ml_df.merge(climate, left_on=merge_year, right_on="year", how="left")
            if "year" in ml_df.columns and merge_year != "year":
                ml_df = ml_df.drop(columns=["year"])
        elif "openmeteo" in sources and not sources["openmeteo"].empty:
            om = sources["openmeteo"]
            om["year"] = pd.to_datetime(om["date"]).dt.year
            climate = om.groupby("year").agg({
                "precipitation_mm": "sum",
                "temperature_mean_c": "mean",
                "relative_humidity_pct": "mean",
            }).reset_index()
            climate = climate.rename(columns={
                "precipitation_mm": "pluviometrie_mm",
                "temperature_mean_c": "temperature_moyenne_c",
                "relative_humidity_pct": "humidite_pct",
            })
            merge_year = "year" if "year" in ml_df.columns else "Year"
            climate = climate.rename(columns={"year": merge_year})
            ml_df = ml_df.merge(climate, on=merge_year, how="left")

    # Sol: moyenne par année (toutes régions)
    if "soil" in sources and not sources["soil"].empty:
        soil = sources["soil"]
        if "year" in soil.columns:
            soil_agg = soil.groupby("year").agg({
                "ph": "mean",
                "nitrogen_N": "mean",
                "phosphorus_P_mg_kg": "mean",
                "potassium_K_mg_kg": "mean",
            }).reset_index()
            soil_agg = soil_agg.rename(columns={
                "phosphorus_P_mg_kg": "phosphore_P_mg_kg",
                "potassium_K_mg_kg": "potassium_K_mg_kg",
                "nitrogen_N": "azote_N",
            })
            merge_year = "year" if "year" in ml_df.columns else "Year"
            soil_agg = soil_agg.rename(columns={"year": merge_year})
            ml_df = ml_df.merge(soil_agg, on=merge_year, how="left")

    # Uniformiser "Year" -> "year" pour le renommage final
    if "Year" in ml_df.columns and "year" not in ml_df.columns:
        ml_df = ml_df.rename(columns={"Year": "year"})
    # Nommage final pour la fiche projet
    rename_final = {
        "yield_tonnes_per_ha": "rendement_tonnes_ha",
        "area_harvested_ha": "surface_cultivee_ha",
        "year": "annee",
    }
    for old, new in rename_final.items():
        if old in ml_df.columns:
            ml_df = ml_df.rename(columns={old: new})

    out_path = data_dir / "dataset_ml_rendement_tunisie.csv"
    ml_df.to_csv(out_path, index=False, encoding="utf-8-sig")
    return out_path
