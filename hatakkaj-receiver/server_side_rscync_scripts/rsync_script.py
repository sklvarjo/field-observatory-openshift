#! /bin/bash

PATH=/home/varjonen/fo-oc-rsync
CLUSTER=https://api.ock.fmi.fi:6443
PROJECT=field-observatory
CONTAINER=hatakkaj-receiver
OCPATH=/home/varjonen/.local/bin
RSYNCPATH=/usr/bin

echo "==============================="
echo "STARTED"
/usr/bin/date
echo "==============================="

token=$(/usr/bin/cat $PATH/token.secret)
$OCPATH/oc login $CLUSTER --token $token
$OCPATH/oc project $PROJECT
receiver=$($OCPATH/oc get pods -l app=$container --no-headers -o custom-columns=POD:.metadata.name)

while read -r exclude_file site; do
  echo $site
  echo "-------------------------------"

  echo $RSYNCPATH/rsync --rsh="$OCPATH/oc rsh" -rva --size-only --no-perms --no-times --exclude-from=$PATH/excludes/$exclude_file $site $rece>
  $RSYNCPATH/rsync --rsh="$OCPATH/oc rsh" -rva --size-only --no-perms --no-times --exclude-from=$PATH/excludes/$exclude_file $site $receiver:>
  echo
done < $PATH/syncs.txt

$OCPATH/oc logout

echo "==============================="
/usr/bin/date
echo "DONE"
echo "==============================="
