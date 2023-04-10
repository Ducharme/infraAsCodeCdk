#!/bin/sh

FORCE=TRUE

START_TIME=`date +%s`

. ./set_env-vars.sh

. ./eks/setEnvVar.sh

STATUSES="CREATE_FAILED CREATE_COMPLETE ROLLBACK_COMPLETE ROLLBACK_FAILED DELETE_FAILED UPDATE_COMPLETE UPDATE_FAILED UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE IMPORT_COMPLETE IMPORT_ROLLBACK_FAILED IMPORT_ROLLBACK_COMPLETE"
STACKS=$(aws cloudformation list-stacks --stack-status-filter $STATUSES | grep "StackName")

EC_STACK=$(echo "$STACKS" | grep "eksctl")
if [ ! -z "$EC_STACK" ]; then
    echo "Deleting K8s cluster"
    . ./eksctl/delete_cluster.sh || { echo "Deleting K8s cluster failed, exiting" ; exit 1; }
fi

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))
echo "FINISHED in $RUN_TIME seconds!"
