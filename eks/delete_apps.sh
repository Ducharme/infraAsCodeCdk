#!/bin/sh

. ./eks/setEnvVar.sh

kubectl get pods --all-namespaces
if [ $? -eq 0 ]; then
  kubectl delete -f ./eks/devices-slow_deployment.yml
  kubectl delete -f ./eks/redisearch-query_service.yml
  kubectl delete -f ./eks/redisearch-performance-analytics-py_service.yml
  kubectl delete -f ./eks/sqsdeviceconsumer-toredisearch_deployment.yml
  kubectl delete -f ./eks/sqsshapeconsumer-toredisearch_deployment.yml
  kubectl delete -f ./eks/redisearch_service.yml

  kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

  helm uninstall kubernetes-ingress --namespace haproxy-controller --wait
else
  echo "Using kubectl to delete apps on K8s failed, skipping"
fi
