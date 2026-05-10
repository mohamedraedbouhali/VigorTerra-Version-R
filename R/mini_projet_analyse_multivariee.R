# ============================================================================
# Mini-projet d'analyse multivariée - VigorTerra
# Analyse factorielle et segmentation de données agricoles tunisiennes
# ============================================================================
# Auteur: Mini-projet Analyse Multivariée
# Module: Méthodes statistiques et étude de données
# Date: Mai 2026
# ============================================================================

# Libraries
library(tidyverse)
library(FactoMineR)
library(factoextra)
library(cluster)
library(ggplot2)

# ============================================================================
# 1. CHARGEMENT ET EXPLORATION DES DONNÉES
# ============================================================================

find_dataset <- function() {
  candidates <- c(
    "DATA/dataset_filtré.csv",
    "DATA/dataset_ml_rendement_tunisie.csv",
    "../DATA/dataset_filtré.csv",
    "../DATA/dataset_ml_rendement_tunisie.csv",
    "agriculture_scraping/data/dataset_ml_rendement_tunisie.csv",
    "../agriculture_scraping/data/dataset_ml_rendement_tunisie.csv"
  )
  found <- candidates[file.exists(candidates)][1]
  if (is.na(found) || length(found) == 0) {
    stop("Aucun fichier dataset trouvé.")
  }
  found
}

# Charger le dataset
data_path <- find_dataset()
cat("Dataset chargé depuis:", data_path, "\n")
df_raw <- readr::read_csv(data_path, show_col_types = FALSE)

cat("\nDimensions du dataset:", nrow(df_raw), "lignes,", ncol(df_raw), "colonnes\n")
glimpse(df_raw)
summary(df_raw)

# ============================================================================
# 2. PRÉPARATION DES DONNÉES
# ============================================================================

# Variables numériques à traiter
core_numeric <- c(
  "annee", "surface_cultivee_ha", "production_tonnes", "rendement_tonnes_ha",
  "pluviometrie_mm", "temperature_moyenne_c", "humidite_pct",
  "ph", "azote_N", "phosphore_P_mg_kg", "potassium_K_mg_kg"
)

# Fonction de classification des cultures
classify_crop_family <- function(item) {
  item <- str_to_lower(coalesce(as.character(item), ""))
  out <- case_when(
    str_detect(item, "wheat|barley|oats|sorghum|maize|rice|triticale|cereals|dur|tendre|orge") ~ "Cereales",
    str_detect(item, "tomato|potato|onion|garlic|cabbage|lettuce|vegetable|melon|cucumber|pumpkin|spinach|carrot") ~ "Legumes",
    str_detect(item, "apple|pear|grape|orange|lemon|dates|fig|apricot|peach|plum|almond|pistachio|hazelnut|fruit") ~ "Fruits",
    str_detect(item, "olive|cotton|sunflower|sesame|linseed|oil|tobacco|sugar|beet") ~ "Industrie",
    str_detect(item, "pea|bean|lentil|chick|pulse") ~ "Legumineuses",
    TRUE ~ "Autres"
  )
  factor(out, levels = c("Cereales", "Legumineuses", "Legumes", "Fruits", "Industrie", "Autres"))
}

# Fonctions d'imputation et de traitement des outliers
impute_median <- function(x) {
  if (!is.numeric(x)) return(x)
  x[is.na(x)] <- median(x, na.rm = TRUE)
  x
}

cap_iqr <- function(x) {
  if (!is.numeric(x)) return(x)
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower <- q1 - 1.5 * iqr
  upper <- q3 + 1.5 * iqr
  x <- pmax(x, lower)
  x <- pmin(x, upper)
  x
}

# Appliquer le prétraitement
df_prep <- df_raw %>%
  mutate(across(any_of(core_numeric), ~ readr::parse_number(as.character(.x)))) %>%
  mutate(
    annee = as.integer(annee),
    famille_culture = classify_crop_family(Item)
  ) %>%
  filter(!is.na(rendement_tonnes_ha)) %>%
  filter(annee >= 2015) %>%
  mutate(across(any_of(core_numeric), impute_median)) %>%
  mutate(across(all_of(setdiff(core_numeric, "annee")), cap_iqr))

cat("\nRésumé après préparation:\n")
cat("Nombre de lignes:", nrow(df_prep), "\n")
cat("Nombre de cultures:", n_distinct(df_prep$Item), "\n")
cat("Période:", min(df_prep$annee), "-", max(df_prep$annee), "\n")

# Normaliser les variables numériques pour l'ACP
numeric_vars <- c(
  "surface_cultivee_ha", "production_tonnes", "rendement_tonnes_ha",
  "pluviometrie_mm", "temperature_moyenne_c", "humidite_pct",
  "ph", "azote_N", "phosphore_P_mg_kg", "potassium_K_mg_kg"
)

df_model <- df_prep %>%
  select(all_of(numeric_vars), annee, famille_culture, Item)

df_scaled <- df_model %>%
  select(all_of(numeric_vars)) %>%
  scale() %>%
  as.data.frame()

# ============================================================================
# 3. ANALYSE EN COMPOSANTES PRINCIPALES (ACP)
# ============================================================================

cat("\n--- ACP (Analyse en Composantes Principales) ---\n")

# Préparer les données pour l'ACP
pca_input <- df_model %>%
  select(all_of(numeric_vars), annee, famille_culture)

# Exécuter l'ACP
res_pca <- PCA(
  pca_input,
  scale.unit = TRUE,
  ncp = 5,
  graph = FALSE,
  quanti.sup = length(numeric_vars) + 1,
  quali.sup = length(numeric_vars) + 2
)

# Afficher la variance expliquée
cat("\nVariance expliquée par les axes:\n")
print(res_pca$eig)

# Contributions des variables aux axes
cat("\nContributions aux axes (Axe 1):\n")
print(head(res_pca$var$contrib[, 1], 10))

# Tracer les graphiques ACP
png("R/figures/pca_scree.png", width = 800, height = 600)
fviz_eig(res_pca, addlabels = TRUE, ylim = c(0, 100))
dev.off()

png("R/figures/pca_var.png", width = 800, height = 600)
fviz_pca_var(res_pca, col.var = "contrib", gradient.cols = c("#2c7bb6", "#ffffbf", "#d7191c"))
dev.off()

png("R/figures/pca_ind.png", width = 800, height = 600)
fviz_pca_ind(
  res_pca,
  repel = TRUE,
  habillage = df_model$famille_culture,
  addEllipses = TRUE,
  palette = "Dark2"
)
dev.off()

cat("Graphiques ACP sauvegardés dans R/figures/\n")

# ============================================================================
# 4. CLASSIFICATION: K-MEANS ET CAH
# ============================================================================

cat("\n--- Classification par K-means et CAH ---\n")

# Récupérer les scores PCA
pca_scores <- as.data.frame(res_pca$ind$coord[, 1:3, drop = FALSE])
colnames(pca_scores) <- c("Dim1", "Dim2", "Dim3")

set.seed(42)

# Déterminer le nombre de clusters optimal
png("R/figures/kmeans_wss.png", width = 800, height = 600)
fviz_nbclust(pca_scores, kmeans, method = "wss")
dev.off()

png("R/figures/kmeans_silhouette.png", width = 800, height = 600)
fviz_nbclust(pca_scores, kmeans, method = "silhouette")
dev.off()

# K-means avec k=3 (choix basé sur la méthode du coude et silhouette)
k_final <- 3
km_res <- kmeans(pca_scores, centers = k_final, nstart = 50)
df_model$cluster_km <- factor(km_res$cluster)

cat("\nCentres des clusters K-means:\n")
print(km_res$centers)

# CAH (Classification Ascendante Hiérarchique)
cah_dist <- dist(scale(pca_scores))
cah_res <- hclust(cah_dist, method = "ward.D2")
df_model$cluster_cah <- factor(cutree(cah_res, k = k_final))

png("R/figures/cah_dendrogram.png", width = 800, height = 600)
fviz_dend(cah_res, k = k_final, rect = TRUE, cex = 0.7)
dev.off()

# Tracer les clusters K-means
png("R/figures/kmeans_clusters.png", width = 800, height = 600)
fviz_cluster(km_res, data = pca_scores, geom = "point", ellipse.type = "norm")
dev.off()

cat("Graphiques de clustering sauvegardés dans R/figures/\n")

# ============================================================================
# 5. ANALYSE COMBINÉE: ACP ET SEGMENTATION
# ============================================================================

cat("\n--- Analyse combinée ACP-Clustering ---\n")

# Créer le dataframe clustérisé
df_clustered <- bind_cols(
  df_model,
  pca_scores,
  tibble(
    cluster_km = factor(km_res$cluster),
    cluster_cah = factor(cutree(cah_res, k = k_final))
  )
)

# Résumé des centres de clusters sur le plan PCA
cluster_pca_summary <- df_clustered %>%
  group_by(cluster_km) %>%
  summarise(
    across(c(Dim1, Dim2, Dim3), mean),
    .groups = "drop"
  )

cat("\nCentres des clusters sur le plan PCA:\n")
print(cluster_pca_summary)

# Profils des clusters
cluster_profile <- df_clustered %>%
  group_by(cluster_km) %>%
  summarise(
    n = n(),
    part_fruits = mean(famille_culture == "Fruits"),
    part_cereales = mean(famille_culture == "Cereales"),
    part_legumes = mean(famille_culture == "Legumes"),
    rendement_moyen = mean(rendement_tonnes_ha),
    pluie_moyenne = mean(pluviometrie_mm),
    temperature_moyenne = mean(temperature_moyenne_c),
    humidite_moyenne = mean(humidite_pct),
    ph_moyen = mean(ph),
    .groups = "drop"
  )

cat("\nProfils des clusters:\n")
print(cluster_profile)

# Tableau de comparaison K-means vs CAH
cat("\nComparaison K-means vs CAH:\n")
print(table(df_clustered$cluster_km, df_clustered$cluster_cah))

# Tracer les clusters sur le plan PCA
png("R/figures/combined_analysis.png", width = 800, height = 600)
fviz_pca_ind(
  res_pca,
  repel = TRUE,
  habillage = df_clustered$cluster_km,
  addEllipses = TRUE,
  palette = "Set1"
)
dev.off()

# ============================================================================
# 6. STATISTIQUES DESCRIPTIVES PAR CLUSTER
# ============================================================================

cat("\n--- Statistiques descriptives par cluster ---\n")

for (clust in 1:k_final) {
  cat("\n### Cluster", clust, "###\n")
  subset_data <- df_clustered %>% filter(cluster_km == clust)
  cat("Nombre d'observations:", nrow(subset_data), "\n")
  cat("Familles de cultures:\n")
  print(table(subset_data$famille_culture))
  cat("\nStatistiques des variables numériques:\n")
  print(summary(subset_data[, numeric_vars]))
}

# ============================================================================
# 7. CONCLUSION
# ============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("CONCLUSION\n")
cat("============================================================================\n")
cat("\nL'ACP a réduit", ncol(pca_input), "variables à", k_final, "axes principaux.\n")
cat("La segmentation a identifié", k_final, "profils distincts de cultures.\n")
cat("\nLes graphiques et résumés statistiques sont dans R/figures/\n")
cat("Le rapport complet est disponible dans R/mini_projet_analyse_multivariee.Rmd\n")
cat("============================================================================\n")
