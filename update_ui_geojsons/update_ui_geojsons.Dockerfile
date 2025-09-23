# syntax=docker/dockerfile:1.4
FROM python:3.12.1

# Install GIT
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use BuildKit secret to access GIT_TOKEN
RUN --mount=type=secret,id=git_token \
    GIT_TOKEN=$(cat /run/secrets/git_token) && \
    git clone https://oauth2:${GIT_TOKEN}@github.com/ollinevalainen/fieldobs_utils.git 

# By default run the main script
#CMD ["python3", "-m", fieldobs_utils.bucket", "update_metadata","field-observatory.yml", "--update_ui_geojsons"]
# For debugging
ENTRYPOINT ["tail", "-f", "/dev/null"]
