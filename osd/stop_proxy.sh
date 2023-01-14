#!/bin/sh


## Prometheus

echo 'Stopping proxy for Prometheus Server.'
PROC_ID=$(ps -ef | grep "kubectl --namespace monitoring port-forward" | grep "prometheus-server" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi

echo 'Stopping proxy for Prometheus PushGateway.'
PROC_ID=$(ps -ef | grep "kubectl --namespace monitoring port-forward" | grep "prometheus-pushgateway" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi

echo 'Stopping proxy for Prometheus AlertManager.'
PROC_ID=$(ps -ef | grep "kubectl --namespace monitoring port-forward" | grep "prometheus-alertmanager" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi

## OpenSearch

echo 'Stopping proxy for OpenSearch.'
PROC_ID=$(ps -ef | grep "kubectl --namespace logging port-forward" | grep "opensearch-cluster-master-0" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi

echo 'Stopping proxy for OpenSearch Dashbaord.'
PROC_ID=$(ps -ef | grep "kubectl --namespace logging port-forward" | grep "opensearch-dashboard" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi

## Grafana

echo 'Stopping proxy for Grafana.'
PROC_ID=$(ps -ef | grep "kubectl --namespace monitoring port-forward" | grep "grafana" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi
