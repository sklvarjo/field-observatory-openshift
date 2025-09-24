#### Local build and pushing the image to openshift integrated repository

Podman would also work and in some cases it is a wiser option. 
Docker allows you to create things that are not allowed in openshift but for this project it does not matter.

    $ docker build -t hatakkaj-receiver -f hatakkaj-receiver.Dockerfile . 
To avoid download throttling and blocking, login to docker hub/docker desktop etc. 

Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.

    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag hatakkaj-receiver default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/hatakkaj-receiver

**NOTE:** Every time you build a new image remember to tag the image again as the tag will still point to the old IMAGE ID after the build.
**NOTE:** Usually it is needed to delete the deployment from openshift and create it again to get the new image to get loaded as that also points to the last IMAGE ID.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/hatakkaj-receiver

**NOTE:** YOU HAVE TO CHANGE THE IMAGESTREAMS LOOKUP POLICY TO TRUE BY HAND IN CONSOLE.
Administrator side -> builds -> ImageStreams -> hatakkaj-receiver -> YAML -> "spec: lookupPolicy: local: true" -> save
or run this in oc
    $ oc patch is hatakkaj-receiver -p '{"spec": {"lookupPolicy": {"local": true}}}'

### Install everything...

Upload the template

    $ oc apply -f hatakkaj-receiver-deployment-configuration.yaml

Instantiate the configuration from the template
With the defaults: 
    $ oc process hatakkaj-receiver | oc create -f-

With changes (that are currently allowed and in the example are the default values used in the above):

    $ oc process hatakkaj-receiver -p STORAGESIZE=5Gi -p CPUREQUEST=100m -p CPULIMIT=1000m -p MEMORYREQUEST=128Mi -p MEMORYLIMIT=400Mi | oc create -f-

**NOTE:** Once the STORAGESIZE is set once and a PVC is created from it, it cannot be changed.

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.
