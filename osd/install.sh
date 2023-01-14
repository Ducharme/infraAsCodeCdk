#!/bin/sh

kubectl create namespace logging
kubectl create namespace monitoring

##########   Prometheus   ##########

# Look at README.md "Prometheus" for instructions to connect
helm install -f osd/prometheus_values.yaml --set prometheus-node-exporter.priorityClassName=system-node-critical \
  --namespace monitoring prometheus prometheus-community/prometheus


##########  OpenSearch  ##########

# Look at README.md "OpenSearch dashboard" for instructions to connect
helm install opensearch opensearch/opensearch --namespace logging --set singleNode=true
helm install opensearch-dashboards opensearch/opensearch-dashboards --namespace logging

OS_NS=logging
OSCM_POD_NAME=opensearch-cluster-master-0
echo "Waiting for pod $OSCM_POD_NAME to be ready before copying files"
while [ $(kubectl get pods $OSCM_POD_NAME -n $OS_NS -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]; do
   sleep 1
done
echo "Pod $OSCM_POD_NAME -> Now copying files"

# Copying keys and certificates to create a secret for fluentbit to upload data to OpenSearch
OS_POD_NAME=$OS_NS/$OSCM_POD_NAME
OS_CERT_DIR=./tmp/certs/opensearch
mkdir -p tmp/certs/opensearch
kubectl cp $OS_POD_NAME:config/esnode-key.pem $OS_CERT_DIR/esnode-key.pem
kubectl cp $OS_POD_NAME:config/esnode.pem $OS_CERT_DIR/esnode.pem
kubectl cp $OS_POD_NAME:config/kirk-key.pem $OS_CERT_DIR/kirk-key.pem
kubectl cp $OS_POD_NAME:config/kirk.pem $OS_CERT_DIR/kirk.pem
kubectl cp $OS_POD_NAME:config/root-ca.pem $OS_CERT_DIR/root-ca.pem
echo "Pod $OSCM_POD_NAME -> Files were copied"

kubectl create secret generic fluentbit-tls -n logging --from-file=root-ca.pem=$OS_CERT_DIR/root-ca.pem \
  --from-file=esnode-key.pem=$OS_CERT_DIR/esnode-key.pem --from-file=esnode.pem=$OS_CERT_DIR/esnode.pem \
  --from-file=kirk-key.pem=$OS_CERT_DIR/kirk-key.pem --from-file=kirk.pem=$OS_CERT_DIR/kirk.pem


##########  Grafana  ##########

# Look at README.md "Grafana" for instructions to get the password and connect
helm install --set persistence.enabled=true --set persistence.size=1Gi --namespace monitoring \
  -f osd/grafana_values.yaml grafana grafana/grafana


##########   Fluent Bit   ##########

kubectl create -f osd/fluentbit.yaml
