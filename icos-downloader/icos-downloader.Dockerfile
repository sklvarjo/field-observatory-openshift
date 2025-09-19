FROM rocker/r-ver:4.3.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl libcurl4-openssl-dev libssl-dev libudunits2-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies
RUN R -e "install.packages(c('httr', 'lubridate', 'units', 'udunits2'), repos='https://cloud.r-project.org')"

COPY src_R/ .

# By default run the main script
#CMD ["Rscript", "download_and_process.R"]
# For debugging
ENTRYPOINT ["tail", "-f", "/dev/null"]
