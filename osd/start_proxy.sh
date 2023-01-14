#!/bin/sh


## Prometheus

echo 'Prometheus Server is accessible via URL http://localhost:9090/graph and URL http://localhost:9090/metrics in a browser.'
POD_NAME=$(kubectl get pods --namespace monitoring | grep "prometheus-server" | cut -d ' ' -f1)
kubectl --namespace monitoring port-forward $POD_NAME 9090 &

echo 'Prometheus PushGateway is accessible via URL http://localhost:9091 in a browser.'
POD_NAME=$(kubectl get pods --namespace monitoring | grep "prometheus-pushgateway" | cut -d ' ' -f1)
kubectl --namespace monitoring port-forward $POD_NAME 9091 &

echo 'Prometheus AlertManager is accessible via URL http://localhost:9093 in a browser.'
POD_NAME=$(kubectl get pods --namespace monitoring | grep "prometheus-alertmanager" | cut -d ' ' -f1)
kubectl --namespace monitoring port-forward $POD_NAME 9093 &

## OpenSearch

echo 'OpenSearch is accessible via URL http://localhost:8080 in a browser. Username/Password are admin/admin'
POD_NAME=$(kubectl get pods --namespace logging -l "app=opensearch-dashboards" -o jsonpath="{.items[0].metadata.name}")
CONTAINER_PORT=$(kubectl get pod --namespace logging $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
kubectl --namespace logging port-forward $POD_NAME 8080:$CONTAINER_PORT &

## Grafana

GF_PASS=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)
echo "Grafana is accessible via URL http://localhost:3000 in a browser. Username/Password are admin/$GF_PASS"
POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 3000
