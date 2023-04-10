#!/bin/sh

START_TIME=`date +%s`

. ./set_env-vars.sh

echo "Calling ./eks/deploy_apps.sh"
. ./eks/deploy_apps.sh


END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))
echo "FINISHED in $RUN_TIME seconds!"
