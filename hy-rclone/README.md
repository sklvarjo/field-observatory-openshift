 
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
