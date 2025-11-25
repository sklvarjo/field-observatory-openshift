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
