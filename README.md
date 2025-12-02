# field-observatory-openshift
Scripts etc. for deploying field observatory in openshift

## Openshift 
- project name: field-observatory
- owner: nevalaio
- uid: 1002860000

## Secret TOKEN for cloning the private repo

The building script by default is looking for `secret_token.txt` from the main folder (where this README is). 
It contains the PAT for the private repositories that contain the actual code for the jobs.
This file gitignored and given to the builder as a secret so it is not included in the final image. 

Ask access to the repository and create a PAT or ask that a PAT is created for you.

In Github go to: 
1. settings (personal not organization)
2. developer options 
3. personal access tokens 
4. Tokens (classic)
5. Create a new classic token with full rights to repos.

Copy-paste the token into file `secret_token.txt` (same folder as this README.md).
**NOTE:** if you do not do it now you will have to create another one.
 
## Dummy container

Useful for checking out the nfs mount...

```
oc apply -f dummy-container-with-nfs-mount/dummy-busybox-with-nfs-mount.yaml
```

This is also used as the rsync point for the BARData from hatakkaj.fmi.fi

## Quay.io

Not used at the moment for FO.
Only internal Openshift registry is in use.

List of all the available containers for [org FMI](https://quay.io/organization/fmi)

## Might be useful notes...

### Alias for login

Add an alias to either ~/.bashrc or ~/.bash_aliases, depending on which you use.

For example: 
```
alias ocdevlogin='oc login https://api.ock.fmi.fi:6443 -u $USER'
```

This will simplify the login to simply `ocdevlogin` ... 
as then it will ask only the password and use the current terminals username.

### Install HELM

Download needed version from [HELM releases](https://github.com/helm/helm/releases).

    $ tar xzf helm-v4.0.0-beta.1-linux-amd64.tar.gz

Or what ever you downloaded. Then

    $ cp linux-amd64/helm ~/.local/bin/

or if all users on machine need to use it

    $ cp linux-amd64/helm /usr/local/bin/

So you can use it in your terminals. 

Remove unnecessary files (helm-v4.0.0-beta.1-linux-amd64.tar.gz, linux-amd64/)

#### HELM debug things 

    # Run in the same folder as the chart.yaml
    helm lint . 
    # And you'll see possibly things that the helm does not understand

    # Run in the same folder as the chart.yaml
    helm template release-name . --debug
    # And you'll see what Helm creates

    # Following will render everything including notes to stdout
    $ helm install --dry-run release-name .

    # if a separate values file is needed it can be overridden
    $ helm template -f second.values.yaml release-name . --debug
    # or
    $ helm install --dry-run -f second.values.yaml release-name .

    # simple value substitution
    $ helm template release-name . --set namespace=new-namespace
    # setting the key to null will remove it

### Temporary pods

How to run an interacive temporary pod (bash).
```
oc run pod-name-temporary -it --rm --image=bash --restart=Never
```
How to run an interactive temporary pod (python but start it in bash prompt)
```
oc run pod-name-temporary -it --rm --image=python --restart=Never -- bash 
```

