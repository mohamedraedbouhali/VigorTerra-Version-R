# Statistiques Descriptives — Projet VigorTerra

---

## 1. Aperçu général du dataset

| Caractéristique | Valeur |
|---|---|
| Nombre d'observations | 2 182 |
| Nombre de variables | 13 |
| Nombre de cultures | 148 |
| Période | 2010 – 2024 |

---

## 2. Tableau récapitulatif des statistiques

| Variable | N valide | Min | Max | Moyenne | Médiane | Manquants |
|---|---|---|---|---|---|---|
| rendement_tonnes_ha | 1 271 | 0.01 | 10.84 | 0.99 | 0.51 | 41.8% |
| pluviometrie_mm | 1 452 | 242.76 | 422.41 | 331.69 | 324.96 | 33.5% |
| temperature_moyenne_c | 1 452 | 19.25 | 20.41 | 19.78 | 19.57 | 33.5% |
| humidite_pct | 1 452 | 62.57 | 66.74 | 64.65 | 64.77 | 33.5% |
| ph | 2 056 | 7.71 | 7.79 | 7.75 | 7.75 | 5.8% |
| azote_N | 2 056 | 0.11 | 0.13 | 0.12 | 0.12 | 5.8% |
| phosphore_P_mg_kg | 2 056 | 33.30 | 40.53 | 36.93 | 37.70 | 5.8% |
| potassium_K_mg_kg | 2 056 | 199.42 | 232.98 | 216.86 | 217.57 | 5.8% |
| surface_cultivee_ha | 1 260 | 0 | 3 622 842 | 87 725 | 6 520 | 42.3% |
| production_tonnes | 2 182 | 0 | 3 219 344 | 148 566 | 11 074 | 0% |

---

## 3. Analyse par variable

### Rendement agricole (variable cible)

Le rendement varie de **0.01 à 10.84 t/ha** avec une moyenne de **0.99 t/ha** et une médiane de **0.51 t/ha**. L'écart important entre ces deux mesures révèle une distribution asymétrique à droite : la majorité des cultures produisent moins de 1 t/ha, tandis que quelques cultures à haute valeur tirent la moyenne vers le haut.

| Classe | Observations | Part |
|---|---|---|
| Faible < 1 t/ha | 838 | 65.9% |
| Moyen 1–2 t/ha | 201 | 15.8% |
| Bon 2–4 t/ha | 168 | 13.2% |
| Excellent > 4 t/ha | 64 | 5.0% |

---

### Pluviométrie

La pluviométrie moyenne de **331.69 mm/an** confirme le caractère semi-aride de la Tunisie. Elle constitue la variable climatique la plus discriminante du modèle : un écart de **180 mm** entre les années sèches (242 mm) et les années humides (422 mm) se traduit directement par des différences de rendement significatives.

---

### Température et humidité

La température moyenne nationale reste stable entre **19.25°C et 20.41°C** sur toute la période, soit une variation inférieure à 1.2°C en 15 ans. L'humidité relative oscille entre **62.57% et 66.74%**. Ces deux variables présentent une faible variabilité interannuelle à l'échelle nationale et ont donc un pouvoir discriminant limité dans le modèle.

---

### pH du sol

Le pH moyen de **7.75** (plage : 7.71–7.79) indique des sols uniformément alcalins, caractéristiques des zones semi-arides méditerranéennes tunisiennes. Cette plage reste favorable aux céréales mais peut réduire la disponibilité de certains micronutriments comme le fer et le manganèse.

---

### NPK — Nutriments du sol

- **Azote (N) : 0.12%** — en dessous du seuil acceptable de 0.2%, révélant une carence azotée généralisée qui constitue le principal facteur limitant du rendement
- **Phosphore (P) : 36.93 mg/kg** — dans la plage acceptable (20–50 mg/kg), sans carence ni excès
- **Potassium (K) : 216.86 mg/kg** — niveau satisfaisant, au-delà du seuil minimum de 150 mg/kg recommandé pour les céréales

---

### Surface cultivée et production

L'écart entre la médiane (**6 520 ha**) et la moyenne (**87 725 ha**) de la surface cultivée traduit la coexistence de petites exploitations familiales et de grandes cultures céréalières nationales. La même dualité s'observe sur la production totale, avec une médiane de **11 074 tonnes** contre une moyenne de **148 566 tonnes**.

---

## 4. Synthèse

Le dataset VigorTerra présente trois caractéristiques majeures à retenir pour la modélisation : une **variable cible fortement asymétrique** qui nécessite des modèles robustes aux valeurs extrêmes, une **pluviométrie très variable** qui constitue le principal facteur explicatif du rendement, et une **carence azotée** généralisée qui représente le levier d'amélioration le plus accessible pour les agriculteurs tunisiens.
