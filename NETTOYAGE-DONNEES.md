# Nettoyage des données — Projet VigorTerra

---

## 1. État initial du dataset brut

Avant tout traitement, le dataset brut (`dataset_avant_traite.csv`) contient **9 029 lignes** issues de la fusion directe des quatre sources (FAOSTAT, OpenMeteo, Agridata, Ministère de l'Agriculture).

### Valeurs manquantes dans le dataset brut

| Variable | Manquantes | Taux |
|---|---|---|
| `pluviometrie_mm` | 7 577 | **83.9%** |
| `temperature_moyenne_c` | 7 577 | **83.9%** |
| `humidite_pct` | 7 577 | **83.9%** |
| `ph` | 6 973 | **77.2%** |
| `azote_N` | 6 973 | **77.2%** |
| `phosphore_P_mg_kg` | 6 973 | **77.2%** |
| `potassium_K_mg_kg` | 6 973 | **77.2%** |
| `rendement_tonnes_ha` | 4 391 | **48.6%** |
| `yield_value` | 4 391 | **48.6%** |
| `surface_cultivee_ha` | 4 269 | **47.3%** |
| `production_tonnes` | 0 | 0% |
| `Item` | 0 | 0% |

Le taux de manquants est critique : plus de **80%** des données climatiques et **77%** des données pédologiques sont absentes dans le dataset brut, ce qui rend le dataset inexploitable en l'état pour la modélisation.

---

## 2. Étapes de nettoyage appliquées

### Étape 1 — Correction de l'encodage (BOM UTF-8)

**Problème détecté :** la première colonne du fichier brut porte le nom `tannee` au lieu de `annee`, à cause d'un caractère BOM (`﻿`) en tête du fichier CSV généré sous Windows.

**Correction :** lecture du fichier avec l'encodage `utf-8-sig` qui supprime automatiquement le BOM, puis renommage de la colonne en `annee`.

```python
df = pd.read_csv("dataset_avant_traite.csv", encoding="utf-8-sig")
df = df.rename(columns={"tannee": "annee"})
```

---

### Étape 2 — Conversion des unités de rendement

**Problème détecté :** la variable `yield_value` fournie par FAOSTAT est exprimée en **hectogrammes par hectare (hg/ha)**, une unité peu lisible et incompatible avec les références agronomiques tunisiennes.

**Correction :** conversion en **tonnes par hectare (t/ha)** en divisant par 10 000.

```python
df["rendement_tonnes_ha"] = df["yield_value"] / 10000.0
```

| Exemple | Avant | Après |
|---|---|---|
| Blé, 2018 | 31 990 hg/ha | 3.20 t/ha |
| Orge, 2020 | 18 450 hg/ha | 1.85 t/ha |

---

### Étape 3 — Fusion et alignement des sources par année

**Problème détecté :** les données climatiques (OpenMeteo) et pédologiques (sol) sont disponibles par **année**, tandis que les données de production (FAOSTAT) sont disponibles par **année × culture**. Une jointure simple crée un produit cartésien avec beaucoup de lignes vides.

**Correction :** agrégation des données climatiques et pédologiques à l'échelle annuelle (moyenne nationale), puis jointure `LEFT JOIN` sur la colonne `annee`.

```python
# Agrégation climatique par année
climate = openmeteo.groupby("year").agg({
    "precipitation_mm"     : "mean",
    "temperature_mean_c"   : "mean",
    "relative_humidity_pct": "mean",
}).reset_index()

# Fusion avec la table de rendement
df = df.merge(climate, on="annee", how="left")
```

---

### Étape 4 — Suppression des lignes inexploitables

**Problème détecté :** de nombreuses lignes du dataset brut n'ont aucune valeur pour la variable cible (`rendement_tonnes_ha`) ou pour les variables climatiques essentielles. Ces lignes ne peuvent pas être utilisées pour entraîner ni évaluer un modèle.

**Correction :** suppression de toutes les lignes où la variable cible est manquante **ET** où les variables climatiques principales sont toutes absentes.

**Résultat :**

| | Lignes | Perte |
|---|---|---|
| Dataset brut | 9 029 | — |
| Dataset filtré | 2 182 | **- 6 847 lignes (−75.8%)** |

---

### Étape 5 — Normalisation des noms de colonnes

Les noms de colonnes ont été uniformisés en français avec des conventions claires pour faciliter la lecture dans les notebooks et le code R.

| Ancien nom (FAOSTAT/API) | Nouveau nom (dataset final) |
|---|---|
| `Year` | `annee` |
| `Item` | `Item` (conservé en anglais, source FAO) |
| `area_harvested_ha` | `surface_cultivee_ha` |
| `yield_tonnes_per_ha` | `rendement_tonnes_ha` |
| `nitrogen_N` | `azote_N` |
| `phosphorus_P_mg_kg` | `phosphore_P_mg_kg` |
| `precipitation_mm` | `pluviometrie_mm` |
| `temperature_mean_c` | `temperature_moyenne_c` |
| `relative_humidity_pct` | `humidite_pct` |

---

### Étape 6 — Pivot des données FAOSTAT

**Problème détecté :** FAOSTAT fournit les données en format **long** : chaque mesure (surface, production, rendement) occupe une ligne séparée avec une colonne `Element` indiquant le type.

**Correction :** transformation en format **large** via un pivot, pour obtenir une seule ligne par combinaison `année × culture`.

```
Format long (FAOSTAT brut) :
Year | Item  | Element         | Value
2018 | Wheat | Area harvested  | 583000
2018 | Wheat | Production      | 1286000
2018 | Wheat | Yield           | 22039

Format large (après pivot) :
annee | Item  | surface_ha | production_t | rendement_t_ha
2018  | Wheat | 583000     | 1286000      | 2.20
```

---

## 3. Comparaison avant / après nettoyage

| Variable | Manquantes avant | Manquantes après | Amélioration |
|---|---|---|---|
| `pluviometrie_mm` | 83.9% | 33.5% | **−50.4 pts** |
| `temperature_moyenne_c` | 83.9% | 33.5% | **−50.4 pts** |
| `humidite_pct` | 83.9% | 33.5% | **−50.4 pts** |
| `ph` | 77.2% | 5.8% | **−71.4 pts** |
| `azote_N` | 77.2% | 5.8% | **−71.4 pts** |
| `phosphore_P_mg_kg` | 77.2% | 5.8% | **−71.4 pts** |
| `potassium_K_mg_kg` | 77.2% | 5.8% | **−71.4 pts** |
| `rendement_tonnes_ha` | 48.6% | 41.8% | −6.8 pts |
| `surface_cultivee_ha` | 47.3% | 42.3% | −5.0 pts |

---

## 4. Valeurs manquantes résiduelles et stratégie d'imputation

Après nettoyage, des valeurs manquantes subsistent encore sur certaines variables. La stratégie appliquée dépend du rôle de chaque variable :

| Variable | Taux résiduel | Stratégie |
|---|---|---|
| `rendement_tonnes_ha` | 41.8% | **Suppression** — variable cible, non imputable |
| `surface_cultivee_ha` | 42.3% | **Ignorée** — non utilisée dans le modèle |
| `pluviometrie_mm` | 33.5% | **Imputation KNN** |
| `temperature_moyenne_c` | 33.5% | **Imputation KNN** |
| `humidite_pct` | 33.5% | **Imputation KNN** |
| `ph` | 5.8% | **Imputation KNN** |
| `azote_N` | 5.8% | **Imputation KNN** |
| `phosphore_P_mg_kg` | 5.8% | **Imputation KNN** |
| `potassium_K_mg_kg` | 5.8% | **Imputation KNN** |

---

## 5. Imputation par KNN (K-Nearest Neighbors)

### Pourquoi KNN plutôt que la moyenne ou la médiane ?

Les méthodes simples comme la **moyenne** ou la **médiane** remplacent toutes les valeurs manquantes par une seule valeur globale, sans tenir compte du contexte de chaque observation. Dans un dataset agricole, cette approche est insuffisante : le rendement d'une culture en 2010 avec une faible pluviométrie n'a pas les mêmes caractéristiques qu'une culture en 2022 dans des conditions humides.

**L'imputation KNN** résout ce problème en cherchant les lignes les plus similaires à la ligne incomplète (les K voisins les plus proches), puis en estimant la valeur manquante à partir de leurs valeurs connues.

### Principe de fonctionnement

```
Ligne incomplète :
  annee=2015 | Item=Wheat | pluviometrie=??? | temperature=19.8 | ph=7.7 | azote=0.12

Étape 1 — Trouver les K lignes les plus proches (sur les variables connues) :
  → 2014 | Wheat | 315 mm | 19.6 | 7.71 | 0.11
  → 2016 | Wheat | 298 mm | 19.9 | 7.72 | 0.12
  → 2015 | Barley| 308 mm | 19.7 | 7.75 | 0.12

Étape 2 — Calculer la moyenne pondérée des K voisins :
  → pluviometrie estimée = (315 + 298 + 308) / 3 = 307 mm
```

La distance entre les lignes est calculée avec la **distance euclidienne** sur les variables numériques disponibles.

### Implémentation Python

```python
import pandas as pd
from sklearn.impute import KNNImputer

# Chargement du dataset après suppression des lignes sans variable cible
df = pd.read_csv("DATA/dataset_filtré.csv", encoding="utf-8-sig")
df = df.dropna(subset=["rendement_tonnes_ha"])

# Sélection des variables numériques à imputer
variables_a_imputer = [
    "pluviometrie_mm",
    "temperature_moyenne_c",
    "humidite_pct",
    "ph",
    "azote_N",
    "phosphore_P_mg_kg",
    "potassium_K_mg_kg",
]

# Initialisation de l'imputeur KNN avec K=5 voisins
# K=5 est un bon compromis : assez de voisins pour lisser les erreurs,
# pas trop pour ne pas perdre la spécificité locale
imputer = KNNImputer(n_neighbors=5, weights="distance")

# Application de l'imputation
df[variables_a_imputer] = imputer.fit_transform(df[variables_a_imputer])

# Sauvegarde du dataset final imputé
df.to_csv("DATA/dataset_filtré.csv", index=False, encoding="utf-8-sig")
print(f"Dataset final : {len(df)} lignes, 0 valeur manquante sur les variables du modèle")
```

### Choix du paramètre K = 5

| Valeur de K | Comportement | Risque |
|---|---|---|
| K = 1 | Copie exacte du voisin le plus proche | Surapprentissage, sensible aux outliers |
| K = 5 | Moyenne pondérée des 5 voisins les plus proches | **Bon équilibre** — choix retenu |
| K = 10+ | Moyenne sur beaucoup de voisins | Lissage excessif, perd la variabilité locale |

Le paramètre `weights="distance"` donne plus de poids aux voisins les plus proches : un voisin à distance 0.5 contribue plus qu'un voisin à distance 3.0.

### Avantages de KNN dans ce contexte agricole

- **Respecte les relations entre variables** : si la température est élevée et la pluviométrie faible, KNN trouvera des années similaires (années sèches) plutôt que d'utiliser une moyenne générale qui mélangerait toutes les saisons.
- **Adapté aux données climatiques** : les variables climatiques sont corrélées entre elles (années chaudes = humidité plus faible), ce que KNN exploite naturellement.
- **Pas de distorsion de la distribution** : contrairement à l'imputation par la moyenne qui compresse la distribution vers le centre, KNN préserve mieux la variance originale des données.

---

## 6. Résultat final

Le dataset nettoyé `dataset_filtré.csv` est constitué de :

- **2 182 lignes** utilisables (contre 9 029 lignes brutes)
- **148 cultures** différentes
- **Période** : 2010 – 2024
- **13 variables** propres et correctement typées
- **Variable cible** : `rendement_tonnes_ha` (t/ha) — plage valide : 0.01 à 10.84

Ce dataset constitue la base d'entrée pour la phase de modélisation avec les trois algorithmes R (Random Forest, Gradient Boosting, Stacking).
