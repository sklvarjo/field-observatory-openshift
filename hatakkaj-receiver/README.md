#### Pushing the image to openshift integrated repository

Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.

    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag hatakkaj-receiver default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/hatakkaj-receiver

**NOTE:** Check that the imageStream for this exists.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/hatakkaj-receiver

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
