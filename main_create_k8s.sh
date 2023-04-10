#!/bin/sh

FORCE=TRUE
APPROVAL=SKIP
#APPROVAL=DEFAULT
#APPROVAL=ALL

START_TIME=`date +%s`

. ./set_env-vars.sh

echo "Creating K8s cluster"
. ./eksctl/create_cluster.sh || { echo "Creating K8s cluster failed, exiting" ; exit 1; }

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))
echo "FINISHED in $RUN_TIME seconds!"
