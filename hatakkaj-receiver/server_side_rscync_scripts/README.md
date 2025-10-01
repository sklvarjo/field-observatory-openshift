### Things needed on Openshift side

    $ oc create sa hatakkaj-external-pipeline

Create the following RoleBinding for the SA.

    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
     name: hatakkaj-external-pipeline
     namespace: field-observatory
     uid: df29d373-aef8-41f1-ba92-cd3bd682b9d9
     resourceVersion: '3831389449'
     creationTimestamp: '2025-09-05T10:03:31Z'
     managedFields:
       - manager: Mozilla
         operation: Update
         apiVersion: rbac.authorization.k8s.io/v1
         time: '2025-09-05T10:03:31Z'
         fieldsType: FieldsV1
         fieldsV1:
           'f:roleRef': {}
           'f:subjects': {}
    subjects:
     - kind: ServiceAccount
       name: hatakkaj-external-pipeline
       namespace: field-observatory
    roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: admin

Then create a token for the SA (default duration is really short so chose 25h).

    $ oc create token hatakkaj-external-pipeline --duration=25h

!Remember to save the token and copy it into a file called **token.secret** on the server
(same folder as the other scripts described in the next section).!

### Things needed on the server side

Currently in my (varjonen) home folder in fo-oc-rsync.

oc bin copied to hatakkaj.fmi.fi /home/varjonen/.local/bin/oc

As the token expires in 25h.
There is a script **recreate-token.sh** on the server. 
It needs to be run in cron at 

    10 0 * * *

This will create a new 25h token to be used for that day.

The **rsync_script.sh** reads the **syncs.txt** that containes the name of the exclude file, 
data source path, and the destination path on the container.
The exclude file is expected to be in $PATH/excludes/ folder. 

The **rsync_script.sh** is intended to run in cron every hour

    0 */1 * * *
