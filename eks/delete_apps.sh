#!/bin/sh

. ./eks/setEnvVar.sh

kubectl apply -f ./eks/devices-slow_deployment.yml
kubectl apply -f ./eks/redisearch-query_service.yml
kubectl apply -f ./eks/redisearch-performance-analytics-py_service.yml
kubectl apply -f ./eks/sqsconsumer-toredisearch-js_deployment.yml
kubectl apply -f ./eks/redisearch_service.yml

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

helm uninstall kubernetes-ingress --namespace haproxy-controller --wait
