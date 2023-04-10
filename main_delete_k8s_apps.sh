#!/bin/sh

. ./set_env-vars.sh

START_TIME=`date +%s`

echo "Calling ./eks/delete_apps.sh"
. ./eks/delete_apps.sh


END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))
echo "FINISHED in $RUN_TIME seconds!"
