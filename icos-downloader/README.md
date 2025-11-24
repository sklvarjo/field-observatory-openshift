#### Pushing the image to openshift integrated repository

Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.


    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag icos-downloader default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/icos-downloader

**NOTE:** Check that the imageStream for this exists.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/icos-downloader

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f icos-downloader-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob icos-downloader-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob
    $ oc patch cronjob icos-downloader-cronjob -p '{"spec" : {"suspend" : true }}'

