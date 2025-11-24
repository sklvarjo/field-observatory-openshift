# build-images.sh

A simple script the simplifies the building of the images.

**NOTE:** To avoid download throttling and blocking, login to docker hub/docker desktop etc.

## Options

Build all or just some of the images

    Usage: build-images.sh [OPTIONS]

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
      --all               Build all images
      --tag <tag>         Set environment (default: latest)
      --secret <path>     Set where the secret token (PAT) file is
      --dry-run           Print actions without executing them
      -h, --help          Show this help and exit

    Examples:
      build-images.sh --datasense
      build-images.sh --all --tag dev
      build-images.sh --all --secret ../secret_token.txt
      build-images.sh --all --dry-run

## Running the containers locally

    $ docker run -it --rm -u $(id -u):$(id -g) -v $(pwd)/testdata:/data [image-name] /bin/bash



