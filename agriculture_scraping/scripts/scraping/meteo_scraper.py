# -*- coding: utf-8 -*-
"""
INM (Institut National de la Météorologie) - meteo.tn
Tentative de récupération des données climatiques (températures, pluies) pour la Tunisie.
Le site meteo.tn est principalement informatif; les données historiques peuvent
être limitées. On complète avec Open-Meteo pour les séries temporelles.
"""

from pathlib import Path

import pandas as pd
import requests
from bs4 import BeautifulSoup

INM_BASE = "https://www.meteo.tn"
# Page des données / climat (à adapter si le site propose des exports)
INM_FR = "https://www.meteo.tn/fr"


def scrape_inm_links() -> list[dict]:
    """
    Parcourt le site INM pour trouver des liens vers des données
    (fichiers CSV, Excel, ou pages avec tableaux).
    """
    found = []
    try:
        r = requests.get(INM_FR, timeout=15, headers={"User-Agent": "Mozilla/5.0 (compatible; AgriBot/1.0)"})
        r.raise_for_status()
        soup = BeautifulSoup(r.text, "lxml")
        for a in soup.find_all("a", href=True):
            href = a.get("href", "")
            text = (a.get_text() or "").strip().lower()
            if any(k in href.lower() or k in text for k in ["donnee", "data", "climat", "historique", "csv", "xls", "export"]):
                if not href.startswith("http"):
                    href = f"{INM_BASE.rstrip('/')}/{href.lstrip('/')}"
                found.append({"url": href, "text": text[:100]})
    except Exception as e:
        print(f"INM scrape: {e}")
    return found


def scrape_inm_tables(output_dir: str | Path) -> pd.DataFrame:
    """
    Tente d'extraire des tableaux HTML depuis les pages INM (températures, pluies).
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    all_tables = []
    try:
        r = requests.get(INM_FR, timeout=15, headers={"User-Agent": "Mozilla/5.0 (compatible; AgriBot/1.0)"})
        r.raise_for_status()
        soup = BeautifulSoup(r.text, "lxml")
        for i, table in enumerate(soup.find_all("table")):
            try:
                df = pd.read_html(str(table), encoding="utf-8")[0]
                if df.shape[0] > 1 and df.shape[1] > 1:
                    df["_source_page"] = "meteo_tn_fr"
                    df["_table_index"] = i
                    all_tables.append(df)
            except Exception:
                continue
    except Exception as e:
        print(f"INM tables: {e}")

    if all_tables:
        combined = pd.concat(all_tables, ignore_index=True)
        out_path = output_dir / "meteo_tn_tables.csv"
        combined.to_csv(out_path, index=False, encoding="utf-8-sig")
        return combined
    return pd.DataFrame()


def collect_inm_data(output_dir: str | Path) -> pd.DataFrame:
    """
    Point d'entrée: récupère les données disponibles sur meteo.tn.
    Si peu de données sont trouvées, le pipeline utilisera Open-Meteo pour le climat.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    links = scrape_inm_links()
    df_tables = scrape_inm_tables(output_dir)

    if links:
        (output_dir / "meteo_tn_links.txt").write_text(
            "\n".join(f"{x['url']}\t{x['text']}" for x in links[:50]),
            encoding="utf-8",
        )
    return df_tables
