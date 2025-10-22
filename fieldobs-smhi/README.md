**TODO:** -

### Building the container

    export DOCKER_BUILDKIT=1;docker build --secret id=git_token,src=../secret_token.txt --no-cache -f fieldobs-smhi.Dockerfile -t fieldobs-smhi .

**NOTE:** Sometimes you may need to add **--no-cache** to the above, for example, when changing the Git repo. 

### Running the container locally

    $ docker run --rm -u $(id -u):$(id -g) -v $(pwd)/testdata:/data fieldobs-smhi

### Pushing to the openshift image registry
Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.

    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag fieldobs-smhi default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-smhi

Push the image to the Openshift's image registry

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fieldobs-smhi

### Deploy to Openshift

    $ oc apply -f fieldobs-smhi-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec": {"schedule": "3 */1 * * *"}}'

**NOTE:** suspending a cronjob

    $ oc patch cronjob fieldobs-smhi-cronjob -p '{"spec" : {"suspend" : true }}'

