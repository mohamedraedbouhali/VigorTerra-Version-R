# Compréhension des données — Projet VigorTerra

---

## 1. Sources de données

Les données du projet ont été collectées auprès de quatre sources complémentaires, combinant des statistiques nationales officielles, des données climatiques satellitaires et des mesures pédologiques régionales.

| Source | Type de données | Période |
|---|---|---|
| FAOSTAT (FAO) | Production et rendement par culture | 2010 – 2024 |
| OpenMeteo API | Climat historique (T°, pluie, humidité) | 2010 – 2024 |
| Agridata Tunisia | Statistiques agricoles nationales | 2010 – 2023 |
| Ministère de l'Agriculture (Tunisie) | Données pédologiques (pH, NPK) | régionales |

Les scripts de collecte automatisée se trouvent dans `agriculture_scraping/scripts/scraping/`.

---

## 2. Description du dataset

Deux versions du dataset ont été produites au cours du projet :

| Dataset | Fichier | Nombre de lignes |
|---|---|---|
| Avant traitement (brut) | `DATA/dataset_avant_traite.csv` | **9 029 lignes** |
| Après filtrage (final) | `DATA/dataset_filtré.csv` | **2 182 lignes** |

Le dataset final couvre **148 cultures différentes** sur la période **2010 à 2024**.

### Variables du dataset

| Variable | Type | Unité | Description |
|---|---|---|---|
| `annee` | Entier | — | Année d'observation |
| `Item` | Texte | — | Nom de la culture (blé, orge, tomates...) |
| `surface_cultivee_ha` | Décimal | ha | Surface exploitée |
| `production_tonnes` | Décimal | tonnes | Production totale récoltée |
| `yield_value` | Décimal | hg/ha | Rendement brut FAO (hectogrammes/hectare) |
| `rendement_tonnes_ha` | Décimal | t/ha | **Variable cible** — rendement converti en t/ha |
| `pluviometrie_mm` | Décimal | mm | Pluviométrie annuelle moyenne |
| `temperature_moyenne_c` | Décimal | °C | Température moyenne annuelle |
| `humidite_pct` | Décimal | % | Humidité relative moyenne |
| `ph` | Décimal | 0–14 | pH moyen du sol |
| `azote_N` | Décimal | % | Teneur en azote du sol |
| `phosphore_P_mg_kg` | Décimal | mg/kg | Teneur en phosphore du sol |
| `potassium_K_mg_kg` | Décimal | mg/kg | Teneur en potassium du sol |

---

## 3. Statistiques descriptives

### Variable cible — Rendement (t/ha)

| Indicateur | Valeur |
|---|---|
| Minimum | 0.01 t/ha |
| Maximum | 10.84 t/ha |
| Moyenne | 0.99 t/ha |
| Médiane | 0.51 t/ha |

La forte différence entre la moyenne (0.99) et la médiane (0.51) indique une **distribution asymétrique** : la majorité des cultures ont un faible rendement, mais quelques cultures à haute valeur tirent la moyenne vers le haut.

### Variables climatiques

| Variable | Minimum | Maximum | Moyenne | Médiane |
|---|---|---|---|---|
| Pluviométrie (mm) | 242.76 | 422.41 | 331.69 | 324.96 |
| Température (°C) | 19.25 | 20.41 | 19.78 | 19.57 |
| Humidité (%) | 62.57 | 66.74 | 64.65 | 64.77 |

La plage de température (19–20°C) est typique du climat méditerranéen tunisien. La pluviométrie reste faible (242–422 mm/an), ce qui confirme la pression hydrique sur les cultures.

### Variables pédologiques (sol)

| Variable | Minimum | Maximum | Moyenne | Médiane |
|---|---|---|---|---|
| pH | 7.71 | 7.79 | 7.75 | 7.75 |
| Azote N (%) | 0.11 | 0.13 | 0.12 | 0.12 |
| Phosphore P (mg/kg) | 33.30 | 40.53 | 36.93 | 37.70 |
| Potassium K (mg/kg) | 199.42 | 232.98 | 216.86 | 217.57 |

Le pH moyen de **7.75** indique des sols légèrement alcalins — caractéristique des sols tunisiens, en particulier dans les zones semi-arides du centre et du nord.

### Surface et production

| Variable | Minimum | Maximum | Moyenne | Médiane |
|---|---|---|---|---|
| Surface cultivée (ha) | 0 | 3 622 842 | 87 725 | 6 520 |
| Production (tonnes) | 0 | 3 219 344 | 148 566 | 11 074 |

L'écart très important entre la moyenne et la médiane de surface révèle la coexistence de **petites exploitations familiales** (< 10 ha) et de **grandes cultures céréalières nationales** (> 1 million ha).

---

## 4. Qualité des données — Valeurs manquantes

| Variable | Valeurs manquantes | Taux |
|---|---|---|
| `surface_cultivee_ha` | 922 | **42.3%** |
| `rendement_tonnes_ha` | 911 | **41.8%** |
| `yield_value` | 911 | **41.8%** |
| `pluviometrie_mm` | 730 | **33.5%** |
| `temperature_moyenne_c` | 730 | **33.5%** |
| `humidite_pct` | 730 | **33.5%** |
| `ph` | 126 | 5.8% |
| `azote_N` | 126 | 5.8% |
| `phosphore_P_mg_kg` | 126 | 5.8% |
| `potassium_K_mg_kg` | 126 | 5.8% |
| `annee` | 0 | 0% |
| `Item` | 0 | 0% |
| `production_tonnes` | 0 | 0% |

### Analyse des manques

- **Rendement (41.8%)** : certaines cultures ne disposent pas de données FAO complètes pour toutes les années, notamment les cultures mineures ou les données récentes (2023–2024).
- **Variables climatiques (33.5%)** : les données OpenMeteo sont disponibles à partir de certaines années seulement et ne couvrent pas toutes les cultures individuellement.
- **Variables pédologiques (5.8%)** : les données de sol sont agrégées par région et non par culture, ce qui crée des lignes sans correspondance directe.

---

## 5. Observations clés

**Distribution du rendement**
La variable cible présente une forte asymétrie à droite. Les cultures comme les céréales (blé, orge) se situent dans la plage 1–4 t/ha, tandis que certaines cultures maraîchères ou fruitières peuvent dépasser 8 t/ha.

**Stabilité climatique**
Les variables climatiques (température, humidité) varient peu d'une année à l'autre dans le dataset, ce qui reflète le comportement stable du climat méditerranéen à l'échelle nationale. Les variations inter-annuelles de pluviométrie (242–422 mm) sont en revanche significatives et constituent le facteur climatique le plus discriminant.

**Sols alcalins**
Le pH systématiquement compris entre 7.71 et 7.79 est caractéristique des sols tunisiens. Cette plage reste favorable à la majorité des céréales, mais limite la disponibilité de certains micronutriments (fer, manganèse).

**Hétérogénéité des cultures**
Le dataset contient 148 cultures très différentes (amandes, blé, tomates, viande bovine...). Pour la modélisation du rendement céréalier, un filtrage sur les cultures cibles (blé, orge, sorgho) est nécessaire afin de réduire le bruit et améliorer la cohérence du modèle.

---

## 6. Conclusion

Le dataset VigorTerra présente une richesse thématique réelle (13 variables, 148 cultures, 15 années) mais nécessite un travail important de préparation en raison des taux élevés de valeurs manquantes (jusqu'à 42%) et de l'hétérogénéité des cultures. Ces constats orientent directement la phase suivante : la **préparation des données**, qui consistera à filtrer, imputer et normaliser le dataset pour le rendre exploitable par les modèles de prédiction.
