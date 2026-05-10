# INM (Institut National de la Météorologie) - meteo.tn
# Récupération des données climatiques (températures, pluies) pour la Tunisie.

library(httr)
library(rvest)
library(dplyr)
library(readr)

INM_BASE <- "https://www.meteo.tn"
INM_FR   <- "https://www.meteo.tn/fr"

.USER_AGENT <- "Mozilla/5.0 (compatible; AgriBot/1.0)"


scrape_inm_links <- function() {
  found <- list()
  tryCatch({
    resp <- httr::GET(INM_FR, httr::timeout(15), httr::user_agent(.USER_AGENT))
    if (httr::status_code(resp) != 200) return(found)

    page  <- rvest::read_html(httr::content(resp, as = "text", encoding = "UTF-8"))
    nodes <- rvest::html_nodes(page, "a[href]")
    hrefs <- rvest::html_attr(nodes, "href")
    texts <- trimws(rvest::html_text(nodes))

    keywords <- c("donnee", "data", "climat", "historique", "csv", "xls", "export")
    for (i in seq_along(hrefs)) {
      href <- hrefs[i]
      text <- tolower(texts[i])
      href_lower <- tolower(href %||% "")
      if (any(sapply(keywords, function(k) grepl(k, href_lower) || grepl(k, text)))) {
        if (!startsWith(href, "http")) {
          href <- paste0(sub("/$", "", INM_BASE), "/", sub("^/", "", href))
        }
        found[[length(found) + 1]] <- list(url = href, text = substr(text, 1, 100))
      }
    }
  }, error = function(e) cat(sprintf("INM scrape: %s\n", conditionMessage(e))))
  found
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x


scrape_inm_tables <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  all_tables <- list()
  tryCatch({
    resp <- httr::GET(INM_FR, httr::timeout(15), httr::user_agent(.USER_AGENT))
    if (httr::status_code(resp) != 200) return(data.frame())

    page   <- rvest::read_html(httr::content(resp, as = "text", encoding = "UTF-8"))
    tables <- rvest::html_table(page, fill = TRUE)

    for (i in seq_along(tables)) {
      tbl <- tables[[i]]
      if (nrow(tbl) > 1 && ncol(tbl) > 1) {
        tbl$`_source_page`  <- "meteo_tn_fr"
        tbl$`_table_index`  <- i
        all_tables[[length(all_tables) + 1]] <- tbl
      }
    }
  }, error = function(e) cat(sprintf("INM tables: %s\n", conditionMessage(e))))

  if (length(all_tables) > 0) {
    combined <- dplyr::bind_rows(all_tables)
    readr::write_csv(combined, file.path(output_dir, "meteo_tn_tables.csv"))
    return(invisible(combined))
  }
  data.frame()
}


collect_inm_data <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  links    <- scrape_inm_links()
  df_tables <- scrape_inm_tables(output_dir)

  if (length(links) > 0) {
    link_lines <- sapply(links[seq_len(min(50, length(links)))], function(x) {
      paste0(x$url, "\t", x$text)
    })
    writeLines(link_lines, file.path(output_dir, "meteo_tn_links.txt"))
  }

  invisible(df_tables)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  out  <- if (length(args) >= 1) args[1] else "data"
  df   <- collect_inm_data(out)
  cat(sprintf("Lignes INM: %d\n", nrow(df)))
}
