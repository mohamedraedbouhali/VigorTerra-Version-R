FROM rocker/r-ver:4.4.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages(c('plumber', 'jsonlite', 'httr'), repos='https://cloud.r-project.org')"

WORKDIR /app

COPY R /app/R

EXPOSE 8000

CMD ["Rscript", "-e", "pr <- plumber::plumb('/app/R/api.R'); pr$run(host = '0.0.0.0', port = 8000)"]
