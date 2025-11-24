### Pushing to the openshift image registry
Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.

    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag fieldobs-ecsites default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-ecsites

Push the image to the Openshift's image registry
**NOTE:** Check that the imageStream for this exists.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-ecsites

### Deploy to Openshift

    $ oc apply -f fieldobs-ecsites-run-gapfilling-cronjob.yml
    $ oc apply -f fieldobs-ecsites-update-ec-data-to-ui-cronjob.yml
    $ oc apply -f fieldobs-ecsites-update-smear-flux-to-observations-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** update ec site allows also "--recompute-all true --site_filter viikki --data_type_filter meteo,precipitation"

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-ecsites-run-gapfilling-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    $ oc patch cronjob fieldobs-ecsites-update-ec-data-to-ui-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    $ oc patch cronjob fieldobs-ecsites-update-smearflux-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-ecsites-run-gapfilling-cronjob -p '{"spec" : {"suspend" : true }}'
    $ oc patch cronjob fieldobs-ecsites-update-ec-data-to-ui-cronjob -p '{"spec" : {"suspend" : true }}'
    $ oc patch cronjob fieldobs-ecsites-update-smearflux-cronjob -p '{"spec" : {"suspend" : true }}'

### Parallel memo

When sequential

993m core, 1600mi mem
