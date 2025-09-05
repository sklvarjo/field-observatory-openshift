# field-observatory-openshift
Scripts etc. for deploying field observatory in openshift

## Openshift 
- project name: field-observatory
- owner: nevalaio
- uid: 1002860000

## External processes (not the automated FO scripts)

Mainly from Istem's scripts
- Lonzee: `/data/field-observatory/ui-data/lonzee`
  - ec/flux/ monthly csv, meteo monthly csv
- DE-Geb: `/data/field-observatory/ui-data/gebesee`
  - ec/flux/ monthly csv, meteo monthly csv
- DE-RuS: `/data/field-observatory/ui-data/selhausen`
  - ec/flux/ monthly csv, meteo monthly csv
- FR-Gri: `/data/field-observatory/ui-data/grignon`
  - ec/flux/ monthly csv, meteo monthly csv
- IT-BCi: `/data/field-observatory/ui-data/cioffi`
- ECMWF weather forecast `/data/field-observatory/ui-data/*/ecmwf_forecast/ecmwf_[15day|seasonal]_forecast.csv`
  - \* qvidja, ik ja et. but not the sites mentioned above

## Dummy container

Useful for checking out the nfs mount...

```
oc apply -f dummy-container-with-nfs-mount/dummy-busybox-with-nfs-mount.yaml
```

This is also used as the rsync point for the BARData from hatakkaj.fmi.fi

## Quay.io

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


