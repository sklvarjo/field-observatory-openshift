# Deploy to Openshift

Generic notes
**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.


## Cronjobs

    $ oc apply -f fieldobs-datasense-cronjob.yaml
    $ oc apply -f fieldobs-ecsites-run-gapfilling-cronjob.yaml
    $ oc apply -f fieldobs-ecsites-update-ec-data-to-ui-cronjob.yaml
    $ oc apply -f fieldobs-ecsites-update-smear-flux-to-observations-cronjob.yaml
    $ oc apply -f fieldobs-radobs-cronjob.yaml
    $ oc apply -f fieldobs-satobs-cronjob.yaml
    $ oc apply -f fieldobs-smhi-cronjob.yaml
    $ oc apply -f fieldobs-update-ui-geojsons-cronjob.yaml
    $ oc apply -f fmi-meteo-downloader-cronjob.yaml
    $ oc apply -f hy-rclone-cronjob.yaml
    $ oc apply -f icos-downloader-cronjob.yaml

## Hatakka template

This is just a container that is waiting for the rsyncs from the Hatakkaj server.

    $ oc apply -f hatakkaj-receiver-deployment-configuration.yaml

    $ oc process hatakkaj-receiver | oc create -f-

    # or if changes are needed
    $ oc process hatakkaj-receiver -p STORAGESIZE=5Gi -p CPUREQUEST=100m -p CPULIMIT=1000m -p MEMORYREQUEST=128Mi -p MEMORYLIMIT=400Mi | oc create -f-

    # This needs a service account to work 
    $ oc apply -f service-account-hatakkaj-external.yaml

Create the initial token for the account.
The token is renewed from the server everyday.
The duration is set to longer just in case of shorter network problems.

    $ oc create token hatakkaj-external-pipeline --duration=49h

See the GIT repository for [https://github.com/sklvarjo/hatakkaj-receiver-serverside-scipts](hatakkaj server side scripts)

# Patching 

cronjob names:
- fieldobs-datasense-cronjob
- fieldobs-ecsites-run-gapfilling-cronjob
- fieldobs-ecsites-update-ec-data-to-ui-cronjob
- fieldobs-ecsites-update-smearflux-cronjob
- fieldobs-radobs-cronjob
- fieldobs-satobs-cronjob
- fieldobs-smhi-cronjob
- fieldobs-update-ui-geojsons-cronjob
- fmi-meteo-downloader-cronjob
- hy-rclone-cronjob
- icos-downloader-cronjob

## Change the schedule example

    $ oc patch cronjob <cronjob-name> -p '{"spec": {"schedule": "3 */1 * * *"}}'

## Suspending a cronjob example

    $ oc patch cronjob <cronjob-name> -p '{"spec" : {"suspend" : true }}'

# Other 

## Force reinit of all Radobs

**NOTE:** Suspend the cronjob for radobs or remove it when trying to do this...

    $ oc apply -f fieldobs-radobs-init-job.yaml

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

