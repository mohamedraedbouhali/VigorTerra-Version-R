# Guide du projet – Prédiction du rendement agricole (Tunisie)

Ce document résume le projet et sert de **guide de référence** pour comprendre, lancer et exploiter la collecte de données.

---

## 1. Vue d’ensemble

| Élément | Description |
|--------|-------------|
| **Titre** | Prédiction du rendement agricole à partir des conditions climatiques et des caractéristiques du sol en Tunisie |
| **Objectif** | Prévoir le **rendement agricole** (tonnes/hectare) en utilisant des **données climatiques et pédologiques** en Tunisie |
| **Domaine** | Agriculture intelligente, Machine Learning, Analyse de données |
| **Variable cible** | **Rendement agricole** (t/ha) |

---

## 2. Données utilisées (pour le modèle ML)

Toutes les variables sont **numériques** :

| Variable | Unité | Source(s) |
|----------|--------|-----------|
| Pluviométrie | mm | Agridata.tn, Open-Meteo |
| Température moyenne | °C | Open-Meteo, INM meteo.tn |
| Humidité | % | Open-Meteo |
| pH du sol | — | Données générées (à remplacer si dispo) |
| Azote (N) | % | Données générées |
| Phosphore (P) | mg/kg | Données générées |
| Potassium (K) | mg/kg | Données générées |
| Surface cultivée | ha | FAOSTAT |
| Année | — | Toutes sources |
| **Rendement agricole** | **t/ha** | **FAOSTAT (variable cible)** |

---

## 3. Sources de données (sites / APIs)

| # | Source | Lien | Données récupérées |
|---|--------|------|--------------------|
| 1 | **Agridata Tunisie** | https://www.agridata.tn | Pluviométrie par région, production, statistiques agricoles |
| 2 | **INM (Météo Tunisie)** | http://www.meteo.tn | Températures, pluies, données climatiques |
| 3 | **FAOSTAT** | https://www.fao.org/faostat | Rendement, production, surface cultivée |
| 4 | **Open-Meteo** | https://open-meteo.com | Température, précipitations, humidité (API) |
| 5 | **Données sol** | — | pH, N, P, K (générées par région dans le code) |

---

## 4. Comment lancer le projet

### Prérequis

- **Python 3.10+** installé
- Connexion internet (pour télécharger les données)

### Étapes

1. **Ouvrir un terminal** dans le dossier du projet :
   ```text
   d:\Documents\agriculture_scraping
   ```

2. **Activer l’environnement virtuel** (Windows PowerShell) :
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```
   En **cmd** : `.\venv\Scripts\activate.bat`

3. **Installer les dépendances** (une seule fois) :
   ```bash
   pip install -r requirements.txt
   ```

4. **Lancer la collecte complète** :
   ```bash
   python scripts/main_collector.py
   ```
   Les fichiers sont créés dans le dossier **`data/`**.

5. **(Optionnel)** Données dans un autre dossier :
   ```bash
   python scripts/main_collector.py C:\chemin\vers\sortie
   ```

---

## 5. Où trouver les données (fichiers générés)

Tous les fichiers sont dans le dossier **`data/`** à la racine du projet.

### Fichier principal pour le modèle ML

| Fichier | Rôle |
|---------|------|
| **`data/dataset_ml_rendement_tunisie.csv`** | **Dataset fusionnée** : année, culture, rendement (cible), surface, production, pluviométrie, température, humidité, pH, N, P, K. **À utiliser pour entraîner le modèle.** |

### Fichiers par source

| Fichier | Contenu |
|---------|--------|
| `faostat_crops_tunisia.csv` | Rendement, production, surface (FAOSTAT, Tunisie) |
| `openmeteo_tunisia.csv` | Climat quotidien (plusieurs villes) |
| `openmeteo_tunisia_annual.csv` | Climat annuel (pour la fusion) |
| `soil_tunisia.csv` | pH, azote, phosphore, potassium par région/année |
| `agridata_pluviometry_combined.csv` | Pluviométrie Agridata (combinée) |
| `agridata_production_combined.csv` | Production Agridata (combinée) |
| `agridata_donnee-climatique_*.csv` | Données climatiques Agridata (précipitations, etc.) |
| `meteo_tn_links.txt` | Liens trouvés sur meteo.tn |

### Consulter la dataset

- **Excel** : Ouvrir `data/dataset_ml_rendement_tunisie.csv`
- **Explorateur Windows** : Aller dans `d:\Documents\agriculture_scraping\data\` et double-cliquer sur le fichier CSV

---

## 6. Structure du projet

```text
agriculture_scraping/
├── data/                                    # ← Toutes les données (CSV)
│   ├── dataset_ml_rendement_tunisie.csv     # ← Dataset pour le ML
│   ├── faostat_crops_tunisia.csv
│   ├── openmeteo_tunisia.csv
│   ├── openmeteo_tunisia_annual.csv
│   ├── soil_tunisia.csv
│   └── agridata_*.csv, meteo_tn_*.txt, ...
│
├── scripts/
│   ├── main_collector.py                    # ← Script principal (tout lancer)
│   ├── scraping/
│   │   ├── faostat_api.py                   # FAOSTAT
│   │   ├── openmeteo_api.py                 # Open-Meteo
│   │   ├── agridata_scraper.py              # Agridata.tn
│   │   ├── meteo_scraper.py                 # INM meteo.tn
│   │   └── soil_data_generator.py           # Données sol (générées)
│   └── preprocessing/
│       └── data_merger.py                   # Fusion → dataset ML
│
├── requirements.txt
├── README.md
└── GUIDE_PROJET.md                          # ← Ce guide
```

---

## 7. Lancer une source seule (sans tout le pipeline)

Si tu veux uniquement une source :

```bash
# FAOSTAT (rendement, production, surface)
python -m scripts.scraping.faostat_api data

# Open-Meteo (climat)
python -m scripts.scraping.openmeteo_api data

# Agridata (pluviométrie + production)
python -m scripts.scraping.agridata_scraper data

# INM meteo.tn
python -m scripts.scraping.meteo_scraper data

# Données sol (générées)
python -m scripts.scraping.soil_data_generator data
```

**Fusion seule** (si les CSV sont déjà dans `data/`) :

```bash
python -c "from pathlib import Path; from scripts.preprocessing.data_merger import merge_all_to_ml_dataset; merge_all_to_ml_dataset(Path('data'))"
```

---

## 8. Pipeline du projet (fiche projet)

| Étape | Contenu | Statut dans ce repo |
|-------|--------|----------------------|
| 1. Collecte | Scraping / téléchargement (Agridata, INM, FAOSTAT, Open-Meteo) | ✅ Fait |
| 2. Prétraitement | Nettoyage, normalisation, fusion | ✅ Début dans `data_merger.py` |
| 3. EDA | Statistiques descriptives, visualisations | À faire (Jupyter, etc.) |
| 4. ML | Clustering (K-Means, DBSCAN), PCA, régression (Random Forest, régression linéaire) | À faire |
| 5. Évaluation | RMSE, MAE, R² | À faire |
| 6. Interprétation | Importance des variables, analyse des clusters | À faire |
| 7. API / Front | FastAPI, React (optionnel) | Hors scope de ce dépôt |

---

## 9. Technologies et outils (fiche projet)

- **Langages** : Python
- **Data & ML** : pandas, numpy, scikit-learn, matplotlib/seaborn, MLflow
- **Scraping** : requests, beautifulsoup4, APIs REST (Open-Meteo, FAOSTAT)
- **Backend (futur)** : FastAPI, Uvicorn, Pydantic
- **Frontend (futur)** : React, Chart.js / Recharts

---

## 10. Points d’attention

- **FAOSTAT** : gros fichier ZIP ; le premier téléchargement peut prendre 1–2 minutes.
- **Open-Meteo** : pas de clé API nécessaire pour l’usage de base.
- **Agridata / INM** : selon la disponibilité des jeux de données, certains appels peuvent être lents ou vides.
- **Données sol** : N, P, K, pH sont **générés** par le script ; à remplacer par de vraies données si disponibles.

---

## 11. Résumé en une page

1. **Objectif** : Prédire le rendement agricole (t/ha) en Tunisie à partir du climat et du sol.
2. **Lancer** : `python scripts/main_collector.py` (après `pip install -r requirements.txt` et activation du venv).
3. **Dataset pour le modèle** : `data/dataset_ml_rendement_tunisie.csv`.
4. **Consulter** : Ouvrir ce CSV avec Excel ou un autre outil depuis le dossier `data/`.
5. **Suite** : Prétraitement, EDA, entraînement des modèles (Random Forest, régression linéaire, etc.) et évaluation (RMSE, MAE, R²).

---

*Ce guide résume le projet « Prédiction du rendement agricole à partir des conditions climatiques et des caractéristiques du sol en Tunisie » et sert de référence pour l’utilisation du dépôt.*
