#!/bin/sh

FORCE=TRUE

START_TIME_ALL=`date +%s`

. ./set_env-vars.sh

echo "Deleting all ECR images"
. ./deleteEcrImages.sh || { echo "Deleting all ECR images failed, exiting" ; exit 1; }

echo "Deleting S3 buckets objects"
. ./deleteS3objects.sh || { echo "Deleting S3 buckets objects failed, exiting" ; exit 1; }

. ./eks/setEnvVar.sh
. ./main_delete_k8s_apps.sh
. ./main_delete_k8s_core.sh
. ./main_delete_k8s.sh
. ./main_delete_core.sh

#cdk destroy --all

END_TIME_ALL=`date +%s`
RUN_TIME_ALL=$((END_TIME_ALL-START_TIME_ALL))
echo "FINISHED in $RUN_TIME_ALL seconds!"
