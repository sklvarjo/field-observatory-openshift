### Deploy on Openshift

Upload the cronjob

    $ oc apply -f icos-downloader-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob icos-downloader-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob
    $ oc patch cronjob icos-downloader-cronjob -p '{"spec" : {"suspend" : true }}'

