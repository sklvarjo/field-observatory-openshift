# syntax=docker/dockerfile:1.4
FROM python:3.12.1

# Install GIT
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /fieldobs

# Use BuildKit secret to access GIT_TOKEN
RUN --mount=type=secret,id=git_token \
    GIT_TOKEN=$(cat /run/secrets/git_token) && \
    git clone https://oauth2:${GIT_TOKEN}@github.com/ollinevalainen/fmiparceldb.git /fieldobs/fmiparceldb/

RUN --mount=type=secret,id=git_token \
    GIT_TOKEN=$(cat /run/secrets/git_token) && \
    git clone https://oauth2:${GIT_TOKEN}@github.com/ollinevalainen/fieldobs_utils.git /fieldobs/fieldobs_utils/

RUN --mount=type=secret,id=git_token \
    GIT_TOKEN=$(cat /run/secrets/git_token) && \
    git clone https://oauth2:${GIT_TOKEN}@github.com/ollinevalainen/fieldobs_satobs.git /fieldobs/fieldobs_satobs/


# poetry & uv
RUN pip3 install poetry uv

# FMI PARCEL DB
RUN cd /fieldobs/fmiparceldb && pip3 install .

# FIELDOBS UTILS
RUN cd /fieldobs/fieldobs_utils/ && poetry remove fmiparceldb --lock && pip3 install .

# FIELDOBS SATOBS
RUN cd /fieldobs/fieldobs_satobs/ && poetry remove fieldobs-utils --lock && pip3 install .

#Overridden in yaml for all three cases.
ENTRYPOINT ["tail", "-f", "/dev/null"]
