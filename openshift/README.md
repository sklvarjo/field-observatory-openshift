
# Deploy to Openshift

    $ oc apply -f fieldobs-datasense-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-datasense-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-datasense-cronjob -p '{"spec" : {"suspend" : true }}'

=========================

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

===================================================================

    $ oc apply -f fieldobs-radobs-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-radobs-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-radobs-cronjob -p '{"spec" : {"suspend" : true }}'

#### Force reinit of all

    $ oc apply -f fieldobs-radobs-init-job.yml

#### Usefull address

[Atmoshpere Data Store API](https://ads.atmosphere.copernicus.eu/api)

================================================

    $ oc apply -f fieldobs-satobs-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-satobs-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-satobs-cronjob -p '{"spec" : {"suspend" : true }}'

=========================================================

    $ oc apply -f fieldobs-smhi-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec" : {"suspend" : true }}'
========================================

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f fieldobs-update-ui-geojsons-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec" : {"suspend" : true }}'

===================================================

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f fmi-meteo-downloader-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

See below the running outside of a container section for the command line switches, these can be used in the cronjob yaml's 
args section to change the behaviour of the script. 

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fmi-meteo-downloader-cronjob -p '{"spec": {"schedule": "1 */1 * * *"}}'

**NOTE:** suspending a cronjob
    $ oc patch cronjob fmi-meteo-downloader-cronjob -p '{"spec" : {"suspend" : true }}'

=========================================

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

=============================================================


### Config map for rclone

**NOTE:** The uh_datacloud is nextcloud but the new (~1.63 or later) version of rclone
introduced chunked uploads and changed the URL. Changing the vendor to owncloud in the
configuration file still works similarly as nextcloud in older versions.

Conf for old versions of rclone:
    [uh_datacloud]
    type = webdav
    url = https://datacloud.helsinki.fi/public.php/webdav
    vendor = nextcloud
    user = Ce5kQ9KL9wBeY3K

For new versions:
    [uh_datacloud]
    type = webdav
    url = https://datacloud.helsinki.fi/public.php/webdav
    vendor = owncloud
    user = Ce5kQ9KL9wBeY3K

This needs to be done before deploying the cronjob. 
This containes the information needed to configure the rclone for the UH site.

    $ oc create configmap rclone-conf --from-file rclone.conf

To check the contents

    $ oc get configmaps rclone-conf -o yaml

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f hy-rclone-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob hy-rclone-cronjob -p '{"spec": {"schedule": "1 3 * * *"}}'

**NOTE:** suspending a cronjob
    $ oc patch cronjob hy-rclone-cronjob -p '{"spec" : {"suspend" : true }}'

===================================================================

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f icos-downloader-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob icos-downloader-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob
    $ oc patch cronjob icos-downloader-cronjob -p '{"spec" : {"suspend" : true }}'

