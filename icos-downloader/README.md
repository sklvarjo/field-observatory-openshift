#### Local build and pushing the image to openshift integrated repository

Podman would also work and in some cases it is a wiser option. 
Docker allows you to create things that are not allowed in openshift but for this project it does not matter.

    $ docker build -t icos-downloader -f icos-downloader.Dockerfile . 

Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.


    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag icos-downloader default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/icos-downloader

**NOTE:** Every time you build a new image remember to tag the image again as the tag will still point to the old IMAGE ID after the build.
**NOTE:** Usually it is needed to delete the deployment from openshift and create it again to get the new image to get loaded as that also points to the last IMAGE ID.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/icos-downloader

**NOTE:** YOU HAVE TO CHANGE THE IMAGESTREAMS LOOKUP POLICY TO TRUE BY HAND IN CONSOLE. **Only after first push**
Administrator side -> builds -> ImageStreams -> hatakkaj-receiver -> YAML -> "spec: lookupPolicy: local: true" -> save
or run this in oc
    $ oc patch is icos-downloader -p '{"spec": {"lookupPolicy": {"local": true}}}'

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f icos-downloader-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch is icos-downloader -p '{"spec": {"schedule": "3 */1 * * *"}}'

### When testing locally ...

#### local test build

    $ docker build -t icos-downloader -f icos-downloader.Dockerfile .

#### local test run

    $ docker run --rm -u $(id -u):$(id -g) -v $(pwd)/testdata:/data icos-downloader
