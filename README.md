# field-observatory-openshift
Scripts etc. for deploying field observatory in openshift

## Openshift 
- project name: field-observatory
- owner: nevalaio
- uid: 1002860000

## Secret TOKEN for cloning the private repo

All of the **fieldobs-** starting folders look for secret_token.txt from the main folder (where this README is).

This is gitignored and given to the builder as a secret so it is not included in the final image. 

Get the correct token from any user with rights to read the repository. 
The token is classic. 
In Github go to users settings->developer options -> personal access tokens -> Tokens (classic)
Create a new classic token with full rights to repos.

Copy paste the token into file secret_token.txt (same folder as this README.md) or
 
    echo "ghp_XXXXXXXXXXXXXXXXXXXX" > secret_token.txt

## Dummy container

Useful for checking out the nfs mount...

```
oc apply -f dummy-container-with-nfs-mount/dummy-busybox-with-nfs-mount.yaml
```

This is also used as the rsync point for the BARData from hatakkaj.fmi.fi

## Quay.io

Not used at the moment for FO.

List of all the available containers for [org FMI](https://quay.io/organization/fmi)

## Might be useful notes...

### Alias for login

Add an alias to either ~/.bashrc or ~/.bash_aliases, depending on which you use.
For example: 
```
alias ocdevlogin='oc login https://api.ock.fmi.fi:6443 -u $USER'
```
This will simplify the login to simply **ocdevlogin** ... 
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

    # Run in teh same folder as the chart.yaml
    helm lint . 
    # And you'll see possibly things that the helm does not understand

    # Run in the same folder as the chart.yaml
    helm template testing . --debug
    # And you'll see what Helm creates

### Temporary pods

How to run an interacive temporary pod (bash).
```
oc run pod-name-temporary -it --rm --image=bash --restart=Never
```
How to run an interactive temporary pod (python but start it in bash prompt)
```
oc run pod-name-temporary -it --rm --image=python --restart=Never -- bash 
```

