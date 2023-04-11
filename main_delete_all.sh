#!/bin/sh

FORCE=TRUE

START_TIME_ALL=`date +%s`

. ./set_env-vars.sh

. ./eks/setEnvVar.sh

. ./main_delete_k8s_apps.sh
. ./main_delete_k8s_core.sh
. ./main_delete_k8s.sh
. ./main_delete_core.sh

#cdk destroy --all

END_TIME_ALL=`date +%s`
RUN_TIME_ALL=$((END_TIME_ALL-START_TIME_ALL))
echo "FINISHED in $RUN_TIME_ALL seconds!"
