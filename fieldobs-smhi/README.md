### Pushing to the openshift image registry
Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.

    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag fieldobs-smhi default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-smhi

Push the image to the Openshift's image registry
**NOTE:** Check that the imageStream for this exists.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-smhi

### Deploy to Openshift

    $ oc apply -f fieldobs-smhi-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec" : {"suspend" : true }}'

