# Prédiction du rendement agricole (Tunisie)

Collecte de données pour construire un dataset et entraîner un modèle de **prédiction du rendement agricole** à partir des conditions climatiques et des caractéristiques du sol en Tunisie.

## Données collectées (selon la fiche projet)

| Variable | Source |
|----------|--------|
| **Pluviométrie** (mm) | Agridata.tn, Open-Meteo |
| **Température moyenne** (°C) | Open-Meteo, INM meteo.tn |
| **Humidité** (%) | Open-Meteo |
| **pH du sol** | Généré (à remplacer par données réelles si dispo) |
| **Azote (N), Phosphore (P), Potassium (K)** | Généré (idem) |
| **Surface cultivée** (ha) | FAOSTAT |
| **Année** | Toutes sources |
| **Rendement agricole** (t/ha) – *variable cible* | FAOSTAT |

## Sources de données

1. **FAOSTAT** – rendement, production, surface cultivée (Tunisie)  
2. **Open-Meteo** – température, précipitations, humidité (API gratuite)  
3. **Agridata Tunisie** – pluviométrie, production (portail CKAN)  
4. **INM (meteo.tn)** – données climatiques (complément)  
5. **Données sol** – pH, N, P, K (générées par région ; à remplacer si données réelles)

## Installation

```bash
cd agriculture_scraping
python -m venv venv
venv\Scripts\activate   # Windows
# ou: source venv/bin/activate   # Linux/Mac
pip install -r requirements.txt
```

## Utilisation

### Collecte complète (recommandé)

Depuis la racine du projet :

```bash
python scripts/main_collector.py
```

Les fichiers sont enregistrés dans le dossier `data/` par défaut. Pour préciser un autre dossier :

```bash
python scripts/main_collector.py chemin/vers/sortie
```

### Fichiers générés

- `data/faostat_crops_tunisia.csv` – FAOSTAT (Tunisie)
- `data/openmeteo_tunisia.csv` – climat quotidien
- `data/openmeteo_tunisia_annual.csv` – climat annuel (pour fusion)
- `data/soil_tunisia.csv` – sol (pH, N, P, K)
- `data/agridata_*.csv` – pluviométrie / production (si disponible)
- `data/meteo_tn_*.csv` – INM (si disponible)
- **`data/dataset_ml_rendement_tunisie.csv`** – **dataset fusionné pour le ML**

### Lancer une source seule

```bash
# FAOSTAT
python -m scripts.scraping.faostat_api data

# Open-Meteo
python -m scripts.scraping.openmeteo_api data

# Agridata (pluviométrie + production)
python -m scripts.scraping.agridata_scraper data

# INM meteo.tn
python -m scripts.scraping.meteo_scraper data

# Données sol (générées)
python -m scripts.scraping.soil_data_generator data
```

### Fusion uniquement (si les CSV sont déjà dans `data/`)

```bash
python -c "from pathlib import Path; from scripts.preprocessing.data_merger import merge_all_to_ml_dataset; merge_all_to_ml_dataset(Path('data'))"
```

## Structure du projet

```
agriculture_scraping/
├── data/                          # Données collectées (créé au premier run)
│   └── dataset_ml_rendement_tunisie.csv
├── scripts/
│   ├── main_collector.py          # Point d'entrée principal
│   ├── scraping/
│   │   ├── faostat_api.py         # FAOSTAT (rendement, production, surface)
│   │   ├── openmeteo_api.py       # Open-Meteo (climat)
│   │   ├── agridata_scraper.py    # Agridata.tn (pluviométrie, production)
│   │   ├── meteo_scraper.py       # INM meteo.tn
│   │   └── soil_data_generator.py # pH, N, P, K (généré)
│   └── preprocessing/
│       └── data_merger.py         # Fusion → dataset ML
├── requirements.txt
└── README.md
```

## Suite du pipeline (fiche projet)

1. **Collecte** – fait par ce dépôt  
2. **Prétraitement** – nettoyage, normalisation, fusion (début dans `data_merger.py`)  
3. **EDA** – statistiques, visualisations  
4. **ML** – clustering (K-Means, DBSCAN), PCA, régression (Random Forest, régression linéaire)  
5. **Évaluation** – RMSE, MAE, R²  
6. **API / Front** – FastAPI, React (hors scope de ce repo)

## Notes

- **FAOSTAT** : gros fichier ZIP ; premier téléchargement peut prendre 1–2 min.  
- **Open-Meteo** : pas de clé API pour l’usage standard. Données historiques via l’API Archive.  
- **Agridata / INM** : selon disponibilité des jeux de données et délais de réponse.  
- **Sol** : N, P, K, pH sont générés par région ; à remplacer par des données réelles si vous en avez.
