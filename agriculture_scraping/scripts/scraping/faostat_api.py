# -*- coding: utf-8 -*-
"""
FAOSTAT - Récupération rendement agricole, production et surface cultivée (Tunisie).
Source: https://www.fao.org/faostat
Données: rendement (hg/ha), production (tonnes), surface récoltée (ha).
"""

import io
import zipfile
from pathlib import Path

import pandas as pd
import requests

# Tunisie = Area Code 222 dans FAOSTAT
TUNISIA_AREA_CODE = "222"

# Dataset "Production: Crops and livestock products" (QCL) - bulk URL
FAOSTAT_CATALOG_URL = "http://fenixservices.fao.org/faostat/static/bulkdownloads/datasets_E.json"
# Liens possibles pour Production Crops / Crops and Livestock (format normalisé)
FAOSTAT_CROPS_BULK_URL = "https://bulks-faostat.fao.org/production/Production_Crops_Livestock_E_All_Data_(Normalized).zip"
FAOSTAT_CROPS_FALLBACK = "https://fenixservices.fao.org/faostat/static/bulkdownloads/Production_Crops_Livestock_E_All_Data_(Normalized).zip"


def _get_crops_bulk_url() -> str:
    """Récupère l'URL du ZIP Production Crops depuis le catalogue si disponible."""
    try:
        r = requests.get(FAOSTAT_CATALOG_URL, timeout=30)
        r.raise_for_status()
        data = r.json()
        for ds in data.get("Datasets", {}).get("Dataset", []) or []:
            if isinstance(ds, dict):
                code = ds.get("DatasetCode") or ""
                name = (ds.get("DatasetName") or "").lower()
                if code == "QCL" or "crop" in name and "production" in name:
                    loc = ds.get("FileLocation")
                    if loc:
                        return loc
    except Exception:
        pass
    return FAOSTAT_CROPS_BULK_URL


def _download_zip(url: str) -> bytes:
    """Télécharge le ZIP avec un fallback d'URL."""
    for u in (url, FAOSTAT_CROPS_FALLBACK):
        try:
            r = requests.get(u, timeout=120, stream=True)
            r.raise_for_status()
            return r.content
        except Exception:
            continue
    raise RuntimeError("Impossible de télécharger les données FAOSTAT.")


def download_faostat_crops_tunisia(output_dir: str | Path) -> pd.DataFrame:
    """
    Télécharge les données FAOSTAT Production Crops/Livestock,
    filtre pour la Tunisie (Area Code 222) et retourne un DataFrame.
    Colonnes utiles: Area, Item, Element (Yield/Production/Area harvested), Year, Value, Unit.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    url = _get_crops_bulk_url()
    content = _download_zip(url)

    with zipfile.ZipFile(io.BytesIO(content)) as z:
        # Fichier normalisé: *_Normalized*.csv
        csv_name = None
        for name in z.namelist():
            if "Normalized" in name and name.endswith(".csv"):
                csv_name = name
                break
        if not csv_name:
            csv_name = z.namelist()[0] if z.namelist() else ""

        with z.open(csv_name) as f:
            df = pd.read_csv(f, encoding="utf-8", low_memory=False)

    # Filtre Tunisie (Area Code 222 ou Area = Tunisia)
    if "Area Code (ISO3)" in df.columns:
        df = df[df["Area Code (ISO3)"].astype(str).str.strip() == "TUN"]
    elif "Area Code" in df.columns:
        df = df[df["Area Code"].astype(str) == TUNISIA_AREA_CODE]
    elif "Area" in df.columns:
        df = df[df["Area"].astype(str).str.strip().str.lower().eq("tunisia")]

    # Harmoniser noms de colonnes (FAO utilise parfois "Year" ou "Année")
    rename = {}
    for c in df.columns:
        if "year" in c.lower():
            rename[c] = "Year"
        if "element" in c.lower():
            rename[c] = "Element"
        if "item" in c.lower() and "code" not in c.lower():
            rename[c] = "Item"
        if "value" in c.lower():
            rename[c] = "Value"
        if "unit" in c.lower():
            rename[c] = "Unit"
    df = df.rename(columns=rename)

    out_path = output_dir / "faostat_crops_tunisia.csv"
    df.to_csv(out_path, index=False, encoding="utf-8-sig")
    return df


def get_yield_production_area_df(df: pd.DataFrame) -> pd.DataFrame:
    """
    Transforme le DataFrame FAOSTAT en table avec colonnes:
    year, item (culture), area_harvested_ha, production_tonnes, yield (tonnes/ha ou hg/ha selon Unit).
    """
    if df.empty or "Element" not in df.columns:
        return pd.DataFrame()

    # Garder Yield, Production, Area harvested
    elements = ["Yield", "Production", "Area harvested"]
    df = df[df["Element"].astype(str).str.strip().isin(elements)].copy()

    # Pivot: une ligne par (Year, Item) avec colonnes Area harvested, Production, Yield
    cols = [c for c in ["Year", "Item", "Element", "Value", "Unit"] if c in df.columns]
    df = df[cols].drop_duplicates()

    piv = df.pivot_table(
        index=["Year", "Item"],
        columns="Element",
        values="Value",
        aggfunc="first",
    ).reset_index()

    piv = piv.rename(columns={
        "Area harvested": "area_harvested_ha",
        "Production": "production_tonnes",
        "Yield": "yield_value",
    })

    # Convertir yield: FAOSTAT donne souvent yield en hg/ha → tonnes/ha = value/10000
    if "yield_value" in piv.columns and "Unit" in df.columns:
        unit = df["Unit"].dropna().iloc[0] if "Unit" in df.columns else ""
        if "hg" in str(unit).lower():
            piv["yield_tonnes_per_ha"] = piv["yield_value"] / 10000.0
        else:
            piv["yield_tonnes_per_ha"] = piv["yield_value"]

    return piv


if __name__ == "__main__":
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else "data"
    df = download_faostat_crops_tunisia(out)
    print(f"Lignes Tunisie: {len(df)}")
    if not df.empty:
        summary = get_yield_production_area_df(df)
        print(summary.head(20))
