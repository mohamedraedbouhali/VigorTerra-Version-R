library(plumber)

script_dir <- tryCatch(
  dirname(sys.frame(1)$ofile),
  error = function(e) getwd()
)

api_file <- file.path(script_dir, "api.R")
if (!file.exists(api_file)) {
  api_file <- file.path(getwd(), "R", "api.R")
}

pr <- plumb(api_file)
pr$run(host = "127.0.0.1", port = 8000, docs = TRUE)
