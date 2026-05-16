# Conclusion Générale — Projet VigorTerra

VigorTerra représente une réponse concrète aux défis de la modernisation agricole en Tunisie. En combinant des données climatiques, pédologiques et agronomiques avec des algorithmes de machine learning implémentés en R, le projet démontre qu'il est possible de prédire le rendement agricole à partir de variables terrain mesurables, et de mettre ces prédictions à disposition des utilisateurs via une interface web simple et accessible. La méthodologie CRISP-DM adoptée a permis de structurer rigoureusement chaque étape, depuis la compréhension du problème métier jusqu'au déploiement de l'application, en passant par la collecte, le nettoyage et l'analyse des données.

Les résultats obtenus montrent que le modèle Stacking, combinant Random Forest et Gradient Boosting, offre les meilleures performances avec un R² de 0.71, confirmant la faisabilité de la prédiction du rendement à partir de données agro-climatiques. L'analyse a également révélé que la pluviométrie est le facteur le plus déterminant dans un contexte semi-aride, et que la carence azotée des sols tunisiens constitue le levier d'amélioration le plus accessible pour les agriculteurs.

### Tableau comparatif des modèles

| Modèle | MAE (t/ha) | RMSE (t/ha) | R² | Interprétation |
|---|---|---|---|---|
| Random Forest | 0.48 | 0.74 | 0.61 | Robuste aux outliers, moins précis |
| Gradient Boosting | 0.41 | 0.65 | 0.68 | Plus précis, capte les effets non-linéaires |
| **Stacking (RF + GB)** | **0.39** | **0.62** | **0.71** | **Meilleur compromis précision / stabilité** |

**Random Forest (MAE = 0.48 — RMSE = 0.74 — R² = 0.61)**
- Se trompe en moyenne de **0.48 t/ha** sur chaque prédiction
- Le R² de 0.61 signifie qu'il explique **61%** de la variabilité du rendement
- Le RMSE de 0.74 indique qu'il est sensible aux **valeurs extrêmes** du dataset
- C'est le modèle le moins précis mais le plus stable face aux données bruitées

**Gradient Boosting (MAE = 0.41 — RMSE = 0.65 — R² = 0.68)**
- Réduit l'erreur moyenne à **0.41 t/ha**, soit un gain de 0.07 t/ha par rapport au RF
- Le R² de 0.68 explique **68%** de la variance — meilleure capture des effets non-linéaires
- Le RMSE de 0.65 confirme une meilleure gestion des cas extrêmes que le RF
- Plus sensible au surapprentissage si les données sont insuffisantes

**Stacking RF + GB (MAE = 0.39 — RMSE = 0.62 — R² = 0.71)**
- Erreur moyenne de seulement **0.39 t/ha** — la plus faible des trois modèles
- R² de 0.71 : le modèle explique **71%** de la variabilité du rendement agricole
- RMSE de 0.62 : les grandes erreurs de prédiction sont les mieux maîtrisées
- La combinaison 30% RF + 70% GB équilibre robustesse et précision
- **Modèle retenu** pour la production dans l'application VigorTerra

Ce projet pose les fondations d'un outil d'aide à la décision agricole évolutif. Des améliorations futures — intégration de données satellitaires, application de l'ACP, collecte à l'échelle parcellaire — permettront de renforcer la précision et l'utilité de la plateforme, au service d'une agriculture tunisienne plus productive, plus résiliente et mieux outillée face aux incertitudes climatiques.
