FROM rocker/r-ver:4.3.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl libcurl4-openssl-dev libssl-dev libudunits2-dev \
 && rm -rf /var/lib/apt/lists/*

# Install dependencies
RUN R -e "install.packages(c('httr', 'lubridate', 'units', 'udunits2'), repos='https://cloud.r-project.org')"

RUN --mount=type=secret,id=git_token \
    GIT_TOKEN=$(cat /run/secrets/git_token) && \
    git clone https://oauth2:${GIT_TOKEN}@github.com/sklvarjo/fieldobs-icos-downloader.git /app

WORKDIR /app

# By default run the main script
CMD ["Rscript", "download_and_process.R"]
# For debugging
#ENTRYPOINT ["tail", "-f", "/dev/null"]
