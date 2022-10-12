#!/bin/sh

. ./eks/setEnvVar.sh


########## eks/redisearch_service.yml ##########

kubectl apply -f ./eks/redisearch_service.yml

n=0
until [ "$n" -ge 10 ]
do
  POD_STATUS=$(kubectl get pods -o json | jq '.items[] | select(.spec.containers[0].name == "redisearch") | .status.phase' | tr -d '"')
  if [ "$POD_STATUS" = "Running" ]; then
    break
  fi
  n=$((n+1)) 
  sleep 5
done

POD_NAME=$(kubectl get pods -o json | jq '.items[] | select(.spec.containers[0].name == "redisearch") | .metadata.name' | tr -d '"')
DEVICE_INDEX_H3="FT.CREATE topic-h3-idx ON HASH PREFIX 1 DEVLOC: SCHEMA topic TEXT h3r0 TAG h3r1 TAG h3r2 TAG h3r3 TAG h3r4 TAG h3r5 TAG h3r6 TAG h3r7 TAG h3r8 TAG h3r9 TAG h3r10 TAG h3r11 TAG h3r12 TAG h3r13 TAG h3r14 TAG h3r15 TAG dts NUMERIC batt NUMERIC fv TEXT"
DEVICE_INDEX_LOC="FT.CREATE topic-lnglat-idx ON HASH PREFIX 1 DEVLOC: SCHEMA topic TEXT lnglat GEO dts NUMERIC batt NUMERIC fv TEXT"
SHAPE_INDEX_LOC_FILTER="FT.CREATE shape-loc-filter-idx ON JSON PREFIX 1 SHAPELOC: SCHEMA $.status AS status TEXT $.type AS type TEXT $.filter.h3r0.* AS f_h3r0 TAG $.filter.h3r1.* AS f_h3r1 TAG $.filter.h3r2.* AS f_h3r2 TAG $.filter.h3r3.* AS f_h3r3 TAG $.filter.h3r4.* AS f_h3r4 TAG $.filter.h3r5.* AS f_h3r5 TAG $.filter.h3r6.* AS f_h3r6 TAG $.filter.h3r7.* AS f_h3r7 TAG $.filter.h3r8.* AS f_h3r8 TAG $.filter.h3r9.* AS f_h3r9 TAG $.filter.h3r10.* AS f_h3r10 TAG $.filter.h3r11.* AS f_h3r11 TAG $.filter.h3r12.* AS f_h3r12 TAG $.filter.h3r13.* AS f_h3r13 TAG $.filter.h3r14.* AS f_h3r14 TAG $.filter.h3r15.* AS f_h3r15 TAG"
SHAPE_INDEX_LOC_MATCH="FT.CREATE shape-loc-match-idx ON JSON PREFIX 1 SHAPELOC: SCHEMA $.status AS status TEXT $.type AS type TEXT $.shape.h3r0.* AS s_h3r0 TAG $.shape.h3r1.* AS s_h3r1 TAG $.shape.h3r2.* AS s_h3r2 TAG $.shape.h3r3.* AS s_h3r3 TAG $.shape.h3r4.* AS s_h3r4 TAG $.shape.h3r5.* AS s_h3r5 TAG $.shape.h3r6.* AS s_h3r6 TAG $.shape.h3r7.* AS s_h3r7 TAG $.shape.h3r8.* AS s_h3r8 TAG $.shape.h3r9.* AS s_h3r9 TAG $.shape.h3r10.* AS s_h3r10 TAG $.shape.h3r11.* AS s_h3r11 TAG $.shape.h3r12.* AS s_h3r12 TAG $.shape.h3r13.* AS s_h3r13 TAG $.shape.h3r14.* AS s_h3r14 TAG $.shape.h3r15.* AS s_h3r15 TAG"

# NOTE: do not quote the INDEX env var
kubectl exec $POD_NAME -- redis-cli $DEVICE_INDEX_H3
kubectl exec $POD_NAME -- redis-cli $DEVICE_INDEX_LOC
kubectl exec $POD_NAME -- redis-cli $SHAPE_INDEX_TYPE
kubectl exec $POD_NAME -- redis-cli $SHAPE_INDEX_LOC_FILTER
kubectl exec $POD_NAME -- redis-cli $SHAPE_INDEX_LOC_MATCH

########## eks/redisearch-performance-analytics-py_service.yml ##########

IMAGE_REPO_NAME_VALUE=redisearch-performance-analytics-py

IMAGE_VALUE=$AWS_ACCOUNT_ID_VALUE.dkr.ecr.$AWS_REGION_VALUE.amazonaws.com/$IMAGE_REPO_NAME_VALUE:latest

TEMPLATE_YAML=./eks/redisearch-performance-analytics-py_service_template.yml
VALUES_YAML=./eks/redisearch-performance-analytics-py_service.yml
cp $TEMPLATE_YAML $VALUES_YAML

sed -i 's@IMAGE_VALUE@'"$IMAGE_VALUE"'@g' $VALUES_YAML
sed -i 's@IMAGE_REPO_NAME_VALUE@'"$IMAGE_REPO_NAME_VALUE"'@g' $VALUES_YAML

kubectl apply -f $VALUES_YAML


########## eks/sqsdeviceconsumer-toredisearch_deployment.yml ##########

IMAGE_REPO_NAME_VALUE=sqsdeviceconsumer-toredisearch

IMAGE_VALUE=$AWS_ACCOUNT_ID_VALUE.dkr.ecr.$AWS_REGION_VALUE.amazonaws.com/$IMAGE_REPO_NAME_VALUE:latest
SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name $DEVICE_SQS_QUEUE_NAME --query QueueUrl | tr -d '"')

TEMPLATE_YAML=./eks/sqsdeviceconsumer-toredisearch_deployment_template.yml
VALUES_YAML=./eks/sqsdeviceconsumer-toredisearch_deployment.yml
cp $TEMPLATE_YAML $VALUES_YAML

sed -i 's@AWS_REGION_VALUE@'"$AWS_REGION_VALUE"'@g' $VALUES_YAML
sed -i 's@SQS_QUEUE_URL_VALUE@'"$DEVICE_SQS_QUEUE_NAME"'@g' $VALUES_YAML
sed -i 's@TOPIC_VALUE@'"$STREAMING_LOCATION_TOPIC"'@g' $VALUES_YAML
sed -i 's@IMAGE_VALUE@'"$IMAGE_VALUE"'@g' $VALUES_YAML
sed -i 's@IMAGE_REPO_NAME_VALUE@'"$IMAGE_REPO_NAME_VALUE"'@g' $VALUES_YAML

kubectl apply -f $VALUES_YAML


########## eks/sqsshapeconsumer-toredisearch_deployment.yml ##########

IMAGE_REPO_NAME_VALUE=sqsshapeconsumer-toredisearch

IMAGE_VALUE=$AWS_ACCOUNT_ID_VALUE.dkr.ecr.$AWS_REGION_VALUE.amazonaws.com/$IMAGE_REPO_NAME_VALUE:latest
SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name $SHAPE_SQS_QUEUE_NAME --query QueueUrl | tr -d '"')

TEMPLATE_YAML=./eks/sqsshapeconsumer-toredisearch_deployment_template.yml
VALUES_YAML=./eks/sqsshapeconsumer-toredisearch_deployment.yml
cp $TEMPLATE_YAML $VALUES_YAML

sed -i 's@AWS_REGION_VALUE@'"$AWS_REGION_VALUE"'@g' $VALUES_YAML
sed -i 's@SQS_QUEUE_URL_VALUE@'"$SHAPE_SQS_QUEUE_NAME"'@g' $VALUES_YAML
sed -i 's@IMAGE_VALUE@'"$IMAGE_VALUE"'@g' $VALUES_YAML
sed -i 's@IMAGE_REPO_NAME_VALUE@'"$IMAGE_REPO_NAME_VALUE"'@g' $VALUES_YAML

kubectl apply -f $VALUES_YAML


########## eks/devices-slow_deployment.yml ##########

IMAGE_REPO_NAME_VALUE=mock-iot-gps-device-awssdkv2

IMAGE_VALUE=$AWS_ACCOUNT_ID_VALUE.dkr.ecr.$AWS_REGION_VALUE.amazonaws.com/$IMAGE_REPO_NAME_VALUE:latest
IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --query endpointAddress | tr -d '"')

TEMPLATE_YAML=./eks/devices-slow_deployment_template.yml
VALUES_YAML=./eks/devices-slow_deployment.yml
cp $TEMPLATE_YAML $VALUES_YAML

sed -i 's@IOT_ENDPOINT@'"$IOT_ENDPOINT"'@g' $VALUES_YAML
sed -i 's@STREAMING_LOCATION_TOPIC_VALUE@'"$STREAMING_LOCATION_TOPIC"'@g' $VALUES_YAML
sed -i 's@STREAMID_REQUEST_TOPIC_VALUE@'"$STREAMID_REQUEST_TOPIC"'@g' $VALUES_YAML
sed -i 's@STREAMID_REPLY_TOPIC_VALUE@'"$STREAMID_REPLY_TOPIC"'@g' $VALUES_YAML
sed -i 's@IMAGE_VALUE@'"$IMAGE_VALUE"'@g' $VALUES_YAML
sed -i 's@IMAGE_REPO_NAME_VALUE@'"$IMAGE_REPO_NAME_VALUE"'@g' $VALUES_YAML

kubectl apply -f $VALUES_YAML


########## eks/eks/redisearch-query_deployment.yml ##########

IMAGE_REPO_NAME_VALUE=redisearch-query-client

IMAGE_VALUE=$AWS_ACCOUNT_ID_VALUE.dkr.ecr.$AWS_REGION_VALUE.amazonaws.com/$IMAGE_REPO_NAME_VALUE:latest

TEMPLATE_YAML=./eks/redisearch-query_service_template.yml
VALUES_YAML=./eks/redisearch-query_service.yml
cp $TEMPLATE_YAML $VALUES_YAML

sed -i 's@IMAGE_VALUE@'"$IMAGE_VALUE"'@g' $VALUES_YAML
sed -i 's@IMAGE_REPO_NAME_VALUE@'"$IMAGE_REPO_NAME_VALUE"'@g' $VALUES_YAML

kubectl apply -f $VALUES_YAML
