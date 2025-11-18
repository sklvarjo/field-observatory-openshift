This clones the Viikki flux data from datacloud.helsinki.fi to the 
**/data/hy-eddy2/data/** which is then used in Henriikka's gapfilling.
 
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

### Local build and pushing the image to openshift integrated repository

Podman would also work and in some cases it is a wiser option. 
Docker allows you to create things that are not allowed in openshift but for this project it does not matter.

    $ docker build -t hy-rclone -f hy-rclone.Dockerfile . 

Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.


    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag hy-rclone default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/hy-rclone

**NOTE:** Check that the imageStream for this exists.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/hy-rclone

**NOTE:** YOU HAVE TO CHANGE THE IMAGESTREAMS LOOKUP POLICY TO TRUE BY HAND IN CONSOLE. **Only after first push**
Administrator side -> builds -> ImageStreams -> hatakkaj-receiver -> YAML -> "spec: lookupPolicy: local: true" -> save
or run this in oc
    $ oc patch is hy-rclone -p '{"spec": {"lookupPolicy": {"local": true}}}'

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f hy-rclone-cronjob.yaml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob hy-rclone-cronjob -p '{"spec": {"schedule": "1 3 * * *"}}'

**NOTE:** suspending a cronjob
    $ oc patch cronjob hy-rclone-cronjob -p '{"spec" : {"suspend" : true }}'
