# Deploy to Openshift

Generic notes
**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.


## Cronjobs

    # Datasense #############
    $ oc apply -f fieldobs-datasense-cronjob.yml
    # ECsites ###############
    $ oc apply -f fieldobs-ecsites-run-gapfilling-cronjob.yml
    $ oc apply -f fieldobs-ecsites-update-ec-data-to-ui-cronjob.yml
    $ oc apply -f fieldobs-ecsites-update-smear-flux-to-observations-cronjob.yml
    # Radobs ################
    $ oc apply -f fieldobs-radobs-cronjob.yml
    # Satobs ################
    $ oc apply -f fieldobs-satobs-cronjob.yml
    # SMHI ##################
    $ oc apply -f fieldobs-smhi-cronjob.yml
    # Update geojsons #######
    $ oc apply -f fieldobs-update-ui-geojsons-cronjob.yaml
    # FMI meteo #############
    $ oc apply -f fmi-meteo-downloader-cronjob.yml
    # HY rclone #############
    $ oc apply -f hy-rclone-cronjob.yaml
    # ICOS download #########
    $ oc apply -f icos-downloader-cronjob.yaml

## Hatakka template

    $ oc apply -f hatakkaj-receiver-deployment-configuration.yaml

    $ oc process hatakkaj-receiver | oc create -f-

    # or if changes are needed
    $ oc process hatakkaj-receiver -p STORAGESIZE=5Gi -p CPUREQUEST=100m -p CPULIMIT=1000m -p MEMORYREQUEST=128Mi -p MEMORYLIMIT=400Mi | oc create -f-

# Patching 

## Change the schedule 

    # Datasense #############
    $ oc patch cronjob fieldobs-datasense-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    # ECsites ###############
    $ oc patch cronjob fieldobs-ecsites-run-gapfilling-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    $ oc patch cronjob fieldobs-ecsites-update-ec-data-to-ui-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    $ oc patch cronjob fieldobs-ecsites-update-smearflux-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    # Radobs ################
    $ oc patch cronjob fieldobs-radobs-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    # Satobs ################
    $ oc patch cronjob fieldobs-satobs-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    # SMHI ##################
    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    # Update geojsons #######
    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'
    # FMI meteo #############
    $ oc patch cronjob fmi-meteo-downloader-cronjob -p '{"spec": {"schedule": "1 */1 * * *"}}'
    # HY rclone #############
    $ oc patch cronjob hy-rclone-cronjob -p '{"spec": {"schedule": "1 3 * * *"}}'
    # ICOS download #########
    $ oc patch cronjob icos-downloader-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

## Suspending a cronjob

    # Datasense #############
    $ oc patch cronjob fieldobs-datasense-cronjob -p '{"spec" : {"suspend" : true }}'
    # ECsites ###############
    $ oc patch cronjob fieldobs-ecsites-run-gapfilling-cronjob -p '{"spec" : {"suspend" : true }}'
    $ oc patch cronjob fieldobs-ecsites-update-ec-data-to-ui-cronjob -p '{"spec" : {"suspend" : true }}'
    $ oc patch cronjob fieldobs-ecsites-update-smearflux-cronjob -p '{"spec" : {"suspend" : true }}'
    # Radobs ################
    $ oc patch cronjob fieldobs-radobs-cronjob -p '{"spec" : {"suspend" : true }}'
    # Satobs ################
    $ oc patch cronjob fieldobs-satobs-cronjob -p '{"spec" : {"suspend" : true }}'
    # SMHI ##################
    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec" : {"suspend" : true }}'
    # Update geojsons #######
    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec" : {"suspend" : true }}'
    # FMI meteo #############
    $ oc patch cronjob fmi-meteo-downloader-cronjob -p '{"spec" : {"suspend" : true }}'
    # HY rclone #############
    $ oc patch cronjob hy-rclone-cronjob -p '{"spec" : {"suspend" : true }}'
    # ICOS download #########
    $ oc patch cronjob icos-downloader-cronjob -p '{"spec" : {"suspend" : true }}'

# Other 

## Force reinit of all Radobs

**NOTE:** Suspend the cronjob for radobs or remove it when trying to do this...

    $ oc apply -f fieldobs-radobs-init-job.yml

## Usefull address to monitor radobs jobs

[Atmoshpere Data Store API](https://ads.atmosphere.copernicus.eu/api)

### Config map for rclone

**NOTE:** The uh_datacloud is nextcloud but the new (~1.63 or later) version of rclone
introduced chunked uploads and changed the URL. Changing the vendor to owncloud in the
configuration file still works similarly as nextcloud in older versions.

Conf for old versions of rclone:

```
[uh_datacloud]
type = webdav
url = https://datacloud.helsinki.fi/public.php/webdav
vendor = nextcloud
user = Ce5kQ9KL9wBeY3K
```

For new versions:

```
[uh_datacloud]
type = webdav
url = https://datacloud.helsinki.fi/public.php/webdav
vendor = owncloud
user = Ce5kQ9KL9wBeY3K
```

This needs to be done before deploying the cronjob. 
This containes the information needed to configure the rclone for the UH site.

    $ oc apply -f hy-rclone-configmap.yaml

To check the contents

    $ oc get configmaps rclone-conf -o yaml

