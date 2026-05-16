# Méthodologie CRISP-DM — Projet VigorTerra

CRISP-DM (Cross-Industry Standard Process for Data Mining) est la méthodologie de référence pour conduire un projet de science des données. Elle structure le travail en 6 phases itératives, de la compréhension du problème métier jusqu'au déploiement du modèle en production.

---

## Phase 1 — Compréhension du métier (Business Understanding)

**Objectif :** définir clairement le problème à résoudre avant de toucher aux données.

Le secteur agricole tunisien souffre d'une forte imprévisibilité du rendement des cultures céréalières, causée par la variabilité climatique (sécheresses, irrégularité des pluies) et la dégradation progressive des sols. Les agriculteurs et les décideurs manquent d'outils numériques accessibles pour anticiper la production à partir de données terrain mesurables.

**Question métier :** peut-on estimer le rendement agricole (en t/ha) d'une parcelle à partir de ses conditions climatiques et pédologiques, avant la récolte ?

**Critère de succès :** un modèle capable de prédire le rendement avec une erreur acceptable, accompagné d'une interface utilisable sur le terrain sans compétences techniques.

---

## Phase 2 — Compréhension des données (Data Understanding)

**Objectif :** collecter, explorer et évaluer la qualité des données disponibles.

Les données ont été collectées auprès de plusieurs sources complémentaires :

| Source | Données fournies |
|---|---|
| Agridata Tunisia | Production et rendement par gouvernorat |
| FAOSTAT (FAO) | Statistiques agricoles nationales 1980–2023 |
| OpenMeteo API | Données climatiques historiques (T°, pluie, humidité) |
| Ministère de l'Agriculture | Fiches techniques et données pédologiques régionales |

Une analyse exploratoire (EDA) a été réalisée dans les notebooks `DATA/EDA_AGRC.ipynb` et `DATA/data.apres_trait.ipynb` pour identifier :
- les distributions des variables (pH, NPK, pluviométrie)
- les corrélations entre conditions climatiques et rendement
- les valeurs manquantes et les outliers à traiter
- les gouvernorats les plus représentés dans les données

---

## Phase 3 — Préparation des données (Data Preparation)

**Objectif :** construire le dataset final propre et exploitable pour la modélisation.

Les étapes de préparation effectuées (scripts dans `agriculture_scraping/scripts/preprocessing/`) :

- **Fusion des sources** : jointure des données climatiques, pédologiques et de production par gouvernorat et par année
- **Nettoyage** : suppression des lignes avec valeurs manquantes critiques, correction des unités incohérentes
- **Filtrage** : sélection des cultures céréalières les plus représentées (blé, orge)
- **Feature engineering** : calcul de ratios NPK, normalisation des unités (mg/kg, mm, °C)
- **Détection des anomalies** : exclusion des rendements physiquement impossibles (< 0.1 t/ha ou > 15 t/ha)

Le dataset final est disponible dans `DATA/dataset_filtré.csv` et `MLflow/dataset_filtré.csv`.

---

## Phase 4 — Modélisation (Modeling)

**Objectif :** entraîner et comparer plusieurs algorithmes de prédiction du rendement.

Trois modèles ont été retenus après expérimentation, tous implémentés en **R** dans `plumber.R` :

### Random Forest
- Ensemble de centaines d'arbres de décision entraînés sur des sous-échantillons aléatoires
- Prédiction finale = moyenne de tous les arbres
- Avantage : robuste aux outliers, pas de normalisation nécessaire, stable sur données hétérogènes

### Gradient Boosting
- Arbres construits séquentiellement : chaque arbre corrige les erreurs du précédent
- Avantage : plus précis que RF sur données tabulaires, capte mieux les interactions non-linéaires (ex : pH × azote)
- Choisi comme modèle principal grâce à ses meilleures performances sur les données tunisiennes

### Stacking (30% RF + 70% GB)
- Combinaison pondérée des deux modèles précédents
- Le poids de 70% accordé à GB reflète sa meilleure précision
- Le poids de 30% accordé à RF apporte de la robustesse face aux données bruitées du terrain
- Recommandé en production pour réduire la variance globale des prédictions

Les notebooks d'expérimentation se trouvent dans `MLflow/Yield_Prediction.ipynb` et `MLflow/Productivity_Classification.ipynb`.

---

## Phase 5 — Évaluation (Evaluation)

**Objectif :** mesurer les performances des modèles et vérifier qu'ils répondent au besoin métier.

Les modèles ont été évalués sur les métriques suivantes :

| Métrique | Description |
|---|---|
| MAE (Mean Absolute Error) | Erreur moyenne absolue en t/ha |
| RMSE (Root Mean Square Error) | Sensible aux grandes erreurs de prédiction |
| R² (coefficient de détermination) | Part de variance expliquée par le modèle |

**Résultats observés :**
- Le Gradient Boosting obtient le meilleur R² et le MAE le plus faible
- Le Random Forest est plus stable sur les jeux de données avec outliers
- Le Stacking offre le meilleur compromis général en conditions réelles

**Validation métier :** les prédictions ont été confrontées aux rendements historiques des gouvernorats de Béja et Jendouba (zones céréalières majeures), confirmant la cohérence agronomique des résultats.

---

## Phase 6 — Déploiement (Deployment)

**Objectif :** rendre le modèle accessible aux utilisateurs finaux via une application en production.

L'architecture de déploiement de VigorTerra :

```
Utilisateur (navigateur)
        │
        ▼
  Frontend React (Vite) — port 3000
        │  /api/* proxifié
        ▼
  Backend FastAPI (Python) — port 8000
        │  POST /predict
        ▼
  Moteur R Plumber — port 8001
  (Random Forest / Gradient Boosting / Stacking)
```

- Le modèle R est servi en temps réel via l'API `plumber` sur le port 8001
- Le backend Python FastAPI joue le rôle de passerelle entre le frontend et le moteur R
- L'application est containerisée avec Docker et Docker Compose pour un déploiement reproductible
- Un assistant conversationnel (Terra, basé sur Gemini) permet de répondre aux questions agronomiques des utilisateurs

**Déploiement local :**
```bash
# Service R (RStudio)
plumb("plumber.R")$run(port = 8001)

# Backend Python
uvicorn app.main:app --reload --port 8000

# Frontend
bun run dev
```

**Déploiement conteneurisé :**
```bash
docker compose up --build
```

---

## Cycle CRISP-DM dans VigorTerra

```
┌─────────────────────────────────────────────┐
│                                             │
│   Compréhension    ──▶   Compréhension      │
│      métier               des données       │
│        ▲                      │             │
│        │                      ▼             │
│   Déploiement        Préparation des        │
│        ▲               données             │
│        │                      │             │
│   Évaluation   ◀──   Modélisation           │
│                                             │
│          (cycle itératif)                   │
└─────────────────────────────────────────────┘
```

Chaque phase alimente la suivante, et les résultats de l'évaluation peuvent conduire à revisiter la préparation des données ou la modélisation pour améliorer les performances du système.
