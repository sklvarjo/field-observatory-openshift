#!/usr/bin/env bash
#
# Building and pushing images
# Author: Varjonen
#

# Setting pipefail to stop the script when docker fails etc.
set -euo pipefail

# --- Colors ------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LPURPLE='\033[1;35m'
NC='\033[0m' # No Color

# --- Default values ----------------------------------------------------------
FILES="dockerfiles"
EXPORT="export DOCKER_BUILDKIT=1;"
SECRET="--secret id=git_token,src="
CACHE="--no-cache"
REGISTRY="default-route-openshift-image-registry.apps.ock.fmi.fi"
NAMESPACE="field-observatory"
SECRET_PATH="../secret_token.txt"
TAG="latest"
DO_BUILD_DATASENSE=false
DO_BUILD_ECSITES=false
DO_BUILD_RADOBS=false
DO_BUILD_SATOBS=false
DO_BUILD_SMHI=false
DO_BUILD_UPDATE_GEOJSONS=false
DO_BUILD_FMI=false
DO_BUILD_HATAKKA=false
DO_BUILD_HY_RCLONE=false
DO_BUILD_ICOS=false
DO_ALL=false
DRY_RUN=false
PUSH_IMAGES=false
PUSH_ONLY=false
VERBOSE=false

COLS=$(tput cols)
LINE=$(printf -- '-%.0s' $(seq $COLS); printf "\n")

# --- Helper functions --------------------------------------------------------
print_line() {
    echo -e ${BLUE}${LINE}${NC}
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --datasense         Build datasense image
  --ecsites           Build ecsites image
  --radobs            Build radobs image
  --satobs            Build satobs image
  --smhi              Build smhi image
  --geojsons          Build update geojsons image
  --fmi               Build FMI meteo download image
  --hatakka           Build Hatakkaj receiver image
  --hy                Build HY rclone image
  --icos              Build ICOS downloader image
  --build-all         Build all images
  --push              Push the images to registry
  --push-only         Skip building and just push
  --verbose           Verbose printing when possible
  --tag <tag>         Set environment (default: latest)
  --secret <path>     Set where the secret token (PAT) file is
  --dry-run           Print actions without executing them
  -h, --help          Show this help and exit

Examples:
  $0 --datasense
  $0 --build-all --tag dev
  $0 --build-all --secret ../secret_token.txt
  $0 --build-all --dry-run
EOF
}

log() {
    local level="$1"; shift
    local color="${GREEN}"
    case "$level" in
        INFO) color="${GREEN}" ;;
        WARN) color="${YELLOW}" ;;
        ERROR) color="${RED}" ;;
        OC) color="${LPURPLE}" ;;
        *) color="${BLUE}" ;;
    esac
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level]${NC} $1"
    # if we have the second argument and we want more output
    if [[ $# == 2 ]]; then
        if $VERBOSE; then echo "$2"; fi
    fi
}

run_cmd() {
    # Helper that respects dry-run
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        log INFO "${YELLOW}[BUILD CMD]${NC} $*"
        eval "$@"
    fi
}

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --datasense) DO_BUILD_DATASENSE=true ;;
        --ecsites) DO_BUILD_ECSITES=true ;;
        --radobs) DO_BUILD_RADOBS=true ;;
        --satobs) DO_BUILD_SATOBS=true ;;
        --smhi) DO_BUILD_SMHI=true ;;
        --geojsons) DO_BUILD_UPDATE_GEOJSONS=true ;;
        --fmi) DO_BUILD_FMI=true ;;
        --hatakka) DO_BUILD_HATAKKA=true ;;
        --hy) DO_BUILD_HY_RCLONE=true ;;
        --icos) DO_BUILD_ICOS=true ;;
        --build-all) DO_ALL=true ;;
        --push) PUSH_IMAGES=true ;;
        --push-only) PUSH_ONLY=true ;;
        --verbose) VERBOSE=true ;;
        --env)
            shift
            TAG="${1:-tag}"
            ;;
        --secret)
           shift
           SECRET_PATH="${1:-secret}"
           echo Reading GIT PAT from $SECRET_PATH
           ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED} Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
    shift
done

# --- Actions -----------------------------------------------------------------

check_oc() {
    # oc commands fail upon error so disabling pipefail
    set +euo pipefail

    OC_PATH=$(which oc)

    if test -z $OC_PATH; then
        log ERROR "No OC command found!"
        exit
    fi
    log OC "OC command found ${OC_PATH}"
    # Check if you are logged in
    OUTPUT=$(oc whoami 2>&1 | cat)
    if [[ $OUTPUT == error* ]]; then
        log ERROR "OC: Log in to Openshift!" "$OUTPUT"
        exit
    fi
    log OC "Logged in as $OUTPUT"

    # Check for a correct project
    OUTPUT=$(oc project field-observatory 2>&1)
    if [[ $OUTPUT == error* ]]; then
        log ERROR "OC: Cannot find correct project" "$OUTPUT"
        exit
    fi
    log OC "Project is $(echo $OUTPUT | cut -d" " -f4-)"

    # Reset pipefail
    set -euo pipefail
}

check_and_create_imagestream() {
    # oc commands fail upon error so disabling pipefail
    set +euo pipefail

    OUTPUT=$(oc get is --no-headers -o custom-columns=POD:.metadata.name 2>&1)
    FOUND=false
    for word in $OUTPUT
    do
        if [[ $word == $1 ]]; then FOUND=true; fi
    done
    if  ! $FOUND; then
        #Did not find creating...
        read -r -d '' IS_TEMPLATE <<- EOF
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: $1
  namespace: field-observatory
EOF
        log OC "Did not find imagestream for image creating it with:"
        log OC "$IS_TEMPLATE"
        if ! $DRY_RUN; then
            OUTPUT=$(echo "${IS_TEMPLATE}" | oc create -f- 2>&1)
            if [[ $OUTPUT == error* ]]; then
                log ERROR "OC: Cannot create imagestream" "$OUTPUT"
                exit
            fi
            log OC $OUTPUT
        else
            log OC "DRY RUN"
        fi
    else
        log OC "Found the corresponding imagestream for ${1^^}"
    fi

    # Reset pipefail
    set -euo pipefail
}

push_image() {
    # This asks about a passphrase in a GUI.
    # It is for a key that you do not remember doing.
    # You can find it by "gpg --list-secret-keys".
    # It is the local keyring's master key and the passhrase
    # is your local machines local password.
    OUTPUT=$(docker login -u $(oc whoami) -p $(oc whoami -t) ${REGISTRY} 2>&1)
    if [[ $OUTPUT = *Succeeded ]]; then
        log OC "Logged in to registry: ${REGISTRY}"
    else
        log ERROR "OC: Registry login" "$OUTPUT"
        exit
    fi
    run_cmd "docker push ${REGISTRY}/${NAMESPACE}/${IMAGE}:${TAG}"
}

build() {
    local IMAGE="$1"
    SECONDS=0
    print_line
    if ! $PUSH_ONLY; then
        log INFO "Started building ${IMAGE^^} image for TAG: ${TAG}"
        run_cmd "${EXPORT} docker build ${SECRET}${SECRET_PATH} ${CACHE}" \
                " -f ${FILES}/${IMAGE}.Dockerfile " \
                "-t ${REGISTRY}/${NAMESPACE}/${IMAGE}:${TAG} ."
    fi
    if $PUSH_IMAGES || $PUSH_ONLY; then
        log INFO "Pushing to the registry ${REGISTRY}"
        check_and_create_imagestream $IMAGE
        push_image $IMAGE
    fi
    duration=$SECONDS
    log INFO "Done with ${IMAGE^^} image in " \
             "$((duration / 60))m $((duration % 60))s."
}

# --- Main execution flow -----------------------------------------------------

if $PUSH_IMAGES || $PUSH_ONLY; then check_oc; fi

if $DO_ALL; then
    DO_BUILD_DATASENSE=true
    DO_BUILD_ECSITES=true
    DO_BUILD_RADOBS=true
    DO_BUILD_SATOBS=true
    DO_BUILD_SMHI=true
    DO_BUILD_UPDATE_GEOJSONS=true
    DO_BUILD_FMI=true
    DO_BUILD_HATAKKA=true
    DO_BUILD_HY_RCLONE=true
    DO_BUILD_ICOS=true
fi

if $DO_BUILD_DATASENSE; then build fieldobs-datasense; fi

if $DO_BUILD_ECSITES; then build fieldobs-ecsites; fi

if $DO_BUILD_RADOBS; then build fieldobs-radobs; fi

if $DO_BUILD_SATOBS; then build fieldobs-satobs; fi

if $DO_BUILD_SMHI; then build fieldobs-smhi; fi

if $DO_BUILD_UPDATE_GEOJSONS; then build fieldobs-update-ui-geojsons; fi

if $DO_BUILD_FMI; then build fmi-meteo-downloader; fi

if $DO_BUILD_HATAKKA; then build hatakkaj-receiver; fi

if $DO_BUILD_HY_RCLONE; then build hy-rclone; fi

if $DO_BUILD_ICOS; then build icos-downloader; fi

if ! $DO_BUILD_DATASENSE && \
   ! $DO_BUILD_ECSITES && \
   ! $DO_BUILD_RADOBS && \
   ! $DO_BUILD_SATOBS && \
   ! $DO_BUILD_SMHI && \
   ! $DO_BUILD_UPDATE_GEOJSONS && \
   ! $DO_BUILD_FMI && \
   ! $DO_BUILD_HATAKKA && \
   ! $DO_BUILD_HY_RCLONE && \
   ! $DO_BUILD_ICOS && \
   ! $DO_ALL; then
    usage
    exit
fi
