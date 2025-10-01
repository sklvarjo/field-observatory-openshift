#! /bin/bash

# RUN THIS A BIT PAST MIDNIGHT EVERY DAY ONLY ONCE A DAY
# 10 0 * * *

PATH=/home/varjonen/fo-oc-rsync
CLUSTER=https://api.ock.fmi.fi:6443
PROJECT=field-observatory
CONTAINER=dummy
OCPATH=/home/varjonen/.local/bin

#Use the current to get the new
token=$(/usr/bin/cat $PATH/token.secret)

$OCPATH/oc login $CLUSTER --token $token
$OCPATH/oc project $PROJECT
$OCPATH/oc create token hatakkaj-external-pipeline --duration=25h > $PATH/token.secret
$OCPATH/oc logout
