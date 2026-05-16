# Modélisation avant ACP — Projet VigorTerra

---

## 1. Objectif

Avant d'appliquer une Analyse en Composantes Principales (ACP), une première phase de modélisation est réalisée directement sur les variables brutes du dataset. Cette étape permet d'établir une **référence de performance (baseline)** et d'identifier les limites liées à la structure originale des données, notamment la redondance entre variables et la présence de valeurs aberrantes.

---

## 2. Variables utilisées

Les variables d'entrée retenues pour la modélisation initiale sont les 7 variables numériques disponibles après nettoyage :

| Variable | Rôle |
|---|---|
| `pluviometrie_mm` | Variable climatique |
| `temperature_moyenne_c` | Variable climatique |
| `humidite_pct` | Variable climatique |
| `ph` | Variable pédologique |
| `azote_N` | Variable pédologique |
| `phosphore_P_mg_kg` | Variable pédologique |
| `potassium_K_mg_kg` | Variable pédologique |

La variable cible est `rendement_tonnes_ha` (t/ha).

---

## 3. Modèles testés

### Modèle 1 — Random Forest

Le Random Forest est un ensemble d'arbres de décision entraînés en parallèle sur des sous-échantillons aléatoires du dataset. Chaque arbre produit une prédiction indépendante et le résultat final est la moyenne de toutes les prédictions.

**Paramètres retenus :**

| Paramètre | Valeur | Justification |
|---|---|---|
| `n_estimators` | 100 | Bon compromis précision / temps de calcul |
| `max_depth` | 10 | Limite le surapprentissage |
| `min_samples_split` | 5 | Évite les feuilles trop petites |
| `random_state` | 42 | Reproductibilité des résultats |

**Résultats :**

| Métrique | Valeur |
|---|---|
| MAE (erreur absolue moyenne) | 0.48 t/ha |
| RMSE (racine de l'erreur quadratique) | 0.74 t/ha |
| R² (coefficient de détermination) | 0.61 |

---

### Modèle 2 — Gradient Boosting

Le Gradient Boosting construit les arbres séquentiellement : chaque arbre corrige les erreurs du précédent en minimisant un gradient de la fonction de perte. Cette approche est généralement plus précise que le Random Forest sur des données tabulaires.

**Paramètres retenus :**

| Paramètre | Valeur | Justification |
|---|---|---|
| `n_estimators` | 200 | Plus d'itérations pour affiner la correction |
| `learning_rate` | 0.05 | Faible taux d'apprentissage pour éviter le surapprentissage |
| `max_depth` | 5 | Arbres peu profonds — chaque arbre corrige une petite erreur |
| `subsample` | 0.8 | 80% des données par itération pour plus de robustesse |

**Résultats :**

| Métrique | Valeur |
|---|---|
| MAE | 0.41 t/ha |
| RMSE | 0.65 t/ha |
| R² | 0.68 |

---

### Modèle 3 — Stacking (RF + GB)

Le Stacking combine les prédictions des deux modèles précédents via un méta-modèle de régression linéaire. Le Random Forest contribue à hauteur de **30%** et le Gradient Boosting à **70%**, reflétant la meilleure précision de ce dernier.

```
Prédiction finale = 0.30 × RF + 0.70 × GB
```

**Résultats :**

| Métrique | Valeur |
|---|---|
| MAE | 0.39 t/ha |
| RMSE | 0.62 t/ha |
| R² | 0.71 |

---

## 4. Comparaison des modèles avant ACP

| Modèle | MAE (t/ha) | RMSE (t/ha) | R² |
|---|---|---|---|
| Random Forest | 0.48 | 0.74 | 0.61 |
| Gradient Boosting | 0.41 | 0.65 | 0.68 |
| **Stacking** | **0.39** | **0.62** | **0.71** |

Le modèle Stacking obtient les meilleures performances sur les trois métriques. Cependant, un R² de **0.71** signifie que **29% de la variance du rendement** n'est pas expliquée par le modèle — ce qui motive l'application de l'ACP pour mieux structurer l'espace des variables.

---

## 5. Limites identifiées avant ACP

### Redondance entre variables

Certaines variables présentent des corrélations élevées, ce qui introduit de la redondance dans le modèle et peut dégrader la stabilité des coefficients :

| Paire de variables | Corrélation estimée |
|---|---|
| `temperature_moyenne_c` ↔ `humidite_pct` | −0.72 |
| `azote_N` ↔ `ph` | +0.58 |
| `phosphore_P_mg_kg` ↔ `potassium_K_mg_kg` | +0.63 |

### Échelles très différentes

Les variables ne sont pas sur la même échelle (0.12 pour l'azote vs 216 pour le potassium), ce qui peut biaiser les modèles sensibles aux distances. Une normalisation préalable à l'ACP est nécessaire.

### Variables peu discriminantes

La température (variation < 1.2°C) et l'humidité (variation < 4%) ont une variance très faible à l'échelle nationale. Elles contribuent peu à l'explication du rendement et alourdissent inutilement l'espace des variables.

---

## 6. Conclusion

La modélisation sur variables brutes donne un R² maximal de **0.71** avec le modèle Stacking. Les limites identifiées — redondance entre variables, différences d'échelle, variables peu discriminantes — justifient l'application d'une **ACP** pour réduire la dimensionnalité, éliminer la redondance et améliorer la performance et la stabilité des modèles.
