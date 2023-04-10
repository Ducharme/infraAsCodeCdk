#!/bin/sh

. ./eks/setEnvVar.sh

kubectl get pods --all-namespaces
if [ $? -eq 0 ]; then
  kubectl delete -f ./eks/devices-slow_deployment.yml
  kubectl delete -f ./eks/redisearch-query_service.yml
  kubectl delete -f ./eks/redisearch-performance-analytics-py_service.yml
  kubectl delete -f ./eks/sqsdeviceconsumer-toredisearch_deployment.yml
  kubectl delete -f ./eks/sqsshapeconsumer-toredisearch_deployment.yml
  kubectl delete -f ./eks/iot-server_deployment.yml
  kubectl delete -f ./eks/redisinsight_service.yml
  kubectl delete -f ./eks/redisearch_service.yml

  kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml
else
  echo "Using kubectl to delete apps on K8s failed, skipping"
fi
