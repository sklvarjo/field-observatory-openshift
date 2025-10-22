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

How to run an interacive temporary pod (bash).
```
oc run pod-name-temporary -it --rm --image=bash --restart=Never
```
How to run an interactive temporary pod (python but start it in bash prompt)
```
oc run pod-name-temporary -it --rm --image=python --restart=Never -- bash 
```


