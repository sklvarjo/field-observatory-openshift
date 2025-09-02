# field-observatory-openshift
Scripts etc. for deploying field observatory in openshift

## Openshift 
- project name: field-observatory
- owner: nevalaio
- uid: 1002860000

## External processes (not the automated FO scripts)

Mainly from Istem's scripts
- Lonzee:  /data/field-observatory/ui-data/lonzee
  - ec/flux/ monthly csv, meteo monthly csv
- DE-Geb:  /data/field-observatory/ui-data/gebesee
  - ec/flux/ monthly csv, meteo monthly csv
- DE-RuS: /data/field-observatory/ui-data/selhausen
  - ec/flux/ monthly csv, meteo monthly csv
- FR-Gri: /data/field-observatory/ui-data/grignon
  - ec/flux/ monthly csv, meteo monthly csv
- IT-BCi: /data/field-observatory/ui-data/cioffi
- ECMWF weather forecast /data/field-observatory/ui-data/*/ecmwf_forecast/ecmwf_[15day|seasonal]_forecast.csv
  - \* qvidja, ik ja et. but not the sites mentioned above

## Might be useful notes...

How to run an interacive temporary pod (bash).
```
oc run pod-name-temporary -it --rm --image=bash --restart=Never
```
How to run an interactive temporary pod (python but start it in bash prompt)
```
oc run pod-name-temporary -it --rm --image=python --restart=Never -- bash 
```


