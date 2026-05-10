# -*- coding: utf-8 -*-
"""
Agridata Tunisie - Scraping pluviométrie et données agricoles depuis le portail CKAN.
Source: https://www.agridata.tn / https://catalog.agridata.tn
"""

import io
from pathlib import Path
from urllib.parse import urljoin

import pandas as pd
import requests
from bs4 import BeautifulSoup

CATALOG_API = "https://catalog.agridata.tn/api/3/action"
BASE_URL = "https://catalog.agridata.tn"


def _ckan_request(action: str, **params) -> dict:
    """Appel API CKAN (package_list, package_show, resource_show)."""
    url = f"{CATALOG_API}/{action}"
    try:
        r = requests.get(url, params=params, timeout=25)
        r.raise_for_status()
        return r.json()
    except Exception as e:
        print(f"CKAN {action}: {e}")
        return {"success": False, "result": None}


def list_datasets(query: str = "") -> list:
    """Liste les jeux de données (packages). query = filtre par mot-clé."""
    out = _ckan_request("package_list")
    if not out.get("success"):
        return []
    names = out.get("result") or []
    if query:
        q = query.lower()
        names = [n for n in names if q in n]
    return names


def get_package_resources(package_id: str) -> list[dict]:
    """Récupère les ressources (fichiers) d'un dataset."""
    out = _ckan_request("package_show", id=package_id)
    if not out.get("success"):
        return []
    pkg = out.get("result") or {}
    return pkg.get("resources") or []


def download_resource(url: str, output_path: Path | None = None) -> bytes | None:
    """Télécharge une ressource (CSV, XLS, etc.) et retourne le contenu binaire."""
    try:
        r = requests.get(url, timeout=60, stream=True)
        r.raise_for_status()
        content = r.content
        if output_path:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_bytes(content)
        return content
    except Exception as e:
        print(f"Download {url[:60]}...: {e}")
        return None


def load_resource_as_dataframe(url: str) -> pd.DataFrame:
    """Télécharge une ressource et la charge en DataFrame (CSV ou Excel)."""
    content = download_resource(url)
    if not content:
        return pd.DataFrame()

    ext = url.split(".")[-1].lower().split("?")[0]
    if ext in ("csv", "txt"):
        return pd.read_csv(io.BytesIO(content), encoding="utf-8", on_bad_lines="skip")
    if ext in ("xlsx", "xls"):
        return pd.read_excel(io.BytesIO(content))
    # Fallback: try CSV
    try:
        return pd.read_csv(io.BytesIO(content), encoding="utf-8", on_bad_lines="skip")
    except Exception:
        return pd.DataFrame()


def scrape_agridata_pluviometry(output_dir: str | Path) -> pd.DataFrame:
    """
    Tente de récupérer les données pluviométriques depuis Agridata.
    Cherche les datasets dont l'id ou le titre contient 'pluvio' ou 'pluviometr'.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    candidates = [
        "pluviometriques-journalieres-observees",
        "donnee-climatique",
        "donnees-climatiques-gouvernorat-de-siliana",
    ]
    all_dfs = []

    for package_id in candidates:
        resources = get_package_resources(package_id)
        if not resources:
            continue
        for res in resources:
            url = res.get("url") or res.get("resource_url")
            if not url or not (url.endswith(".csv") or "csv" in url or "xlsx" in url or "xls" in url):
                continue
            name = res.get("name") or res.get("format", "").lower()
            try:
                content = download_resource(url)
                if not content:
                    continue
                ext = (res.get("format") or "").lower() or url.split(".")[-1][:4]
                if "csv" in ext or url.endswith(".csv"):
                    df = pd.read_csv(io.BytesIO(content), encoding="utf-8", on_bad_lines="skip")
                else:
                    df = pd.read_excel(io.BytesIO(content))
                if not df.empty:
                    df["_source_dataset"] = package_id
                    all_dfs.append(df)
                    out_name = f"agridata_{package_id}_{name or 'data'}.csv".replace(" ", "_")[:80]
                    df.to_csv(output_dir / out_name, index=False, encoding="utf-8-sig")
            except Exception as e:
                print(f"Load {package_id} {url[:50]}: {e}")

    if not all_dfs:
        # Fallback: page HTML du catalogue pour extraire des liens de téléchargement
        try:
            r = requests.get(f"{BASE_URL}/fr/dataset/", timeout=20)
            r.raise_for_status()
            soup = BeautifulSoup(r.text, "lxml")
            for a in soup.select('a[href*="/dataset/"][href*="pluvio"]')[:5]:
                href = a.get("href") or ""
                if not href.startswith("http"):
                    href = urljoin(BASE_URL, href)
                # On pourrait suivre la page et chercher les ressources
                break
        except Exception as e:
            print(f"Fallback scrape: {e}")

    if all_dfs:
        combined = pd.concat(all_dfs, ignore_index=True)
        combined.to_csv(output_dir / "agridata_pluviometry_combined.csv", index=False, encoding="utf-8-sig")
        return combined
    return pd.DataFrame()


def scrape_agridata_production(output_dir: str | Path) -> pd.DataFrame:
    """
    Tente de récupérer des données de production agricole depuis Agridata.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    candidates = [
        "evolution-de-la-production-nationale-des-cereales",
        "evolution-de-la-production-vegetale",
        "evolution-des-cereales-pendant-la-periode-1980-2022",
    ]
    all_dfs = []

    for package_id in candidates:
        resources = get_package_resources(package_id)
        for res in resources:
            url = res.get("url") or res.get("resource_url")
            if not url:
                continue
            try:
                content = download_resource(url)
                if not content:
                    continue
                if ".csv" in url.lower() or (res.get("format") or "").lower() == "csv":
                    df = pd.read_csv(io.BytesIO(content), encoding="utf-8", on_bad_lines="skip")
                else:
                    df = pd.read_excel(io.BytesIO(content))
                if not df.empty:
                    df["_source_dataset"] = package_id
                    all_dfs.append(df)
                    safe_name = package_id.replace("-", "_")[:50]
                    df.to_csv(output_dir / f"agridata_production_{safe_name}.csv", index=False, encoding="utf-8-sig")
            except Exception as e:
                print(f"Load production {package_id}: {e}")

    if all_dfs:
        combined = pd.concat(all_dfs, ignore_index=True)
        combined.to_csv(output_dir / "agridata_production_combined.csv", index=False, encoding="utf-8-sig")
        return combined
    return pd.DataFrame()


if __name__ == "__main__":
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else "data"
    df_pluv = scrape_agridata_pluviometry(out)
    print(f"Pluviométrie Agridata: {len(df_pluv)} lignes")
    df_prod = scrape_agridata_production(out)
    print(f"Production Agridata: {len(df_prod)} lignes")
