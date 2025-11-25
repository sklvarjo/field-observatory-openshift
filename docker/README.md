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
      --build-all         Build all images
      --push              Push the images to registry
      --push-only         Skip building and just push
      --verbose           Verbose printing when possible
      --tag <tag>         Set environment (default: latest)
      --secret <path>     Set where the secret token (PAT) file is
      --dry-run           Print actions without executing them
      -h, --help          Show this help and exit

    Examples:
      build-images.sh --datasense
      build-images.sh --build-all --tag dev
      build-images.sh --build-all --secret ../secret_token.txt
      build-images.sh --build-all --dry-run


## Commands that the script runs 

### Secrets 

This file should contain the PAT that you can access the fieldobs-* repositories in GIT

This is gitignored and given to the builder as a secret so it is not included in the final image. 

Or just go to the github 
-> settings (main settings from your avatar right upper corner not the repository settings)
-> developer settings (left side last item in list)
-> personal access tokens
-> Tokens (classic)
-> create new token
-> generate new token classic
-> asks authentication
-> Write a note for it, e.g., oc-ldndc
-> Check full rights to repos.
-> Generate in the end of the page.
-> Copy the "ghp_" starting string. *NOTE:* this is the only change to copy it.
-> Paste it to the secret-token.txt file. 

Copy paste the token into file secret_token.txt (same folder as this README.md) or
 
    echo "ghp_XXXXXXXXXXXXXXXXXXXX" > secret_token.txt

### Building

If for some reason one wants to run these manually. 
Change the <IMAGE> with the correspoding image name, i.e., the Dockerfile name.

Building the image.

    $ export DOCKER_BUILDKIT=1; docker build --secret id=git_token,src=../secret_token.txt --no-cache  -f dockerfiles/<IMAGE>.Dockerfile -t default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/<IMAGE>:latest .

Getting the registry info. This is 

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Log into the openshift internal registry with docker.

    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

    $ docker tag <IMAGE> default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/<IMAGE>

Check that the imageStream for this exists. 
Run the following and check if the <IMAGE> is in the list.

    $ oc get is

if not create a file with the following example
    ---
    apiVersion: image.openshift.io/v1
    kind: ImageStream
    metadata:
      name: <IMAGE>
      namespace: field-observatory

and by running the following

    $ oc apply -f <FILENAME>

Push the image to the Openshift's image registry.
This asks about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/<IMAGE>

## Misc

Running the containers locally and overwriting the entrypoint/CMD and just run bash.

    $ docker run -it --rm -u $(id -u):$(id -g) -v $(pwd)/testdata:/data [image-name] /bin/bash



