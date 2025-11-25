### Deploy to Openshift

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

