### Deploy on Openshift

Upload the cronjob

    $ oc apply -f fieldobs-update-ui-geojsons-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-update-ui-geojsons-cronjob -p '{"spec" : {"suspend" : true }}'


