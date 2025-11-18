
**TODO: FINISH THIS**

### Building the container

    export DOCKER_BUILDKIT=1;docker build --secret id=git_token,src=../secret_token.txt -f fieldobs-update-ui-geojsons.Dockerfile -t fieldobs-update-ui-geojsons .

### Local build and pushing the image to openshift integrated repository

Podman would also work and in some cases it is a wiser option. 
Docker allows you to create things that are not allowed in openshift but for this project it does not matter.

    $ docker build -t fieldobs-update-ui-geojsons -f fieldobs-update-ui-geojsons.Dockerfile . 

Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.

    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag fieldobs-update-ui-geojsons default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-update-ui-geojsons

**NOTE:** Check that the imageStream for this exists.
    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-update-ui-geojsons

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f fieldobs-update-ui-geojsons-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec" : {"suspend" : true }}'


