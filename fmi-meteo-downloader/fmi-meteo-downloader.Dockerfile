# syntax=docker/dockerfile:1
FROM python:3.11.1

RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install python-dateutil requests

WORKDIR /project

# Use BuildKit secret to access GIT_TOKEN
RUN --mount=type=secret,id=git_token \
    GIT_TOKEN=$(cat /run/secrets/git_token) && \
    git clone https://oauth2:${GIT_TOKEN}@github.com/sklvarjo/fieldobs-fmi-meteo-downloader.git /project/src/

CMD ["python3", "-u", "/project/src/main.py"]
