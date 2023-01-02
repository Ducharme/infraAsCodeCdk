#!/bin/sh

. ./eks/setEnvVar.sh


########## eks/redisearch_service.yml ##########

TEMPLATE_YAML=./eks/redisearch_service_template.yml
VALUES_YAML=./eks/redisearch_service.yml
cp $TEMPLATE_YAML $VALUES_YAML

kubectl apply -f eks/redis-index-creator-configmap.yml
kubectl apply -f $VALUES_YAML


########## eks/iot-server.yml ##########

IMAGE_REPO_NAME_VALUE=iot-server

IMAGE_VALUE=$AWS_ACCOUNT_ID_VALUE.dkr.ecr.$AWS_REGION_VALUE.amazonaws.com/$IMAGE_REPO_NAME_VALUE:latest
IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --query endpointAddress | tr -d '"')

TEMPLATE_YAML=./eks/iot-server_deployment_template.yml
VALUES_YAML=./eks/iot-server_deployment.yml
cp $TEMPLATE_YAML $VALUES_YAML

sed -i 's@IOT_ENDPOINT@'"$IOT_ENDPOINT"'@g' $VALUES_YAML
sed -i 's@STREAMID_REQUEST_TOPIC_VALUE@'"$STREAMID_REQUEST_TOPIC"'@g' $VALUES_YAML
sed -i 's@STREAMID_REPLY_TOPIC_VALUE@'"$STREAMID_REPLY_TOPIC"'@g' $VALUES_YAML

kubectl apply -f $VALUES_YAML


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


##########  Kubernetes Dashboard (Web UI)  ##########

# From https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml
K8S_DASHBOARD_LINK=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

K8S_DASHBOARD_USER=k8s-dashboard-user
kubectl create serviceaccount $K8S_DASHBOARD_USER
kubectl create clusterrolebinding $K8S_DASHBOARD_USER-binding --clusterrole=cluster-admin --serviceaccount=default:$K8S_DASHBOARD_USER
kubectl proxy &

K8S_DASHBOARD_SECRET=$(kubectl get secrets | grep "$K8S_DASHBOARD_USER" | cut -d ' ' -f1)
K8S_DASHBOARD_TOKEN=$(kubectl describe secret $K8S_DASHBOARD_SECRET | grep "token:" | cut -d ':' -f2 | tr -d ' ')

echo ""
echo "*** NOTE - Kubernetes Dashboard (Web UI) ***"
echo "Link is $K8S_DASHBOARD_LINK"
echo "Underlying Service Account $K8S_DASHBOARD_USER hold the Secret"
echo "Login with  with Bearer Token $K8S_DASHBOARD_TOKEN"
echo ""


##########  Redis Insight (Web UI) ##########

# https://docs.redis.com/latest/ri/installing/install-k8s/
TEMPLATE_YAML=./eks/reks/redisinsight_service_template.yml
VALUES_YAML=./eks/reks/redisinsight_service.yml
cp $TEMPLATE_YAML $VALUES_YAML
kubectl apply -f $VALUES_YAML

kubectl port-forward service/redisinsight-service 8002:80 &

echo "*** NOTE - Redis Insight (Web UI) ***"
echo "Link is http://localhost:8002/ on the computer deploying"
echo ""
