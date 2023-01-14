#!/bin/sh


##########  Kubernetes Dashboard (Web UI)  ##########

echo 'Stopping proxy for Kubernetes Dashboard.'
PROC_ID=$(ps -ef | grep "kubectl proxy" | grep -v "color" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi


##########  Redis Insight (Web UI) ##########

echo 'Stopping proxy for Redis Insight.'
PROC_ID=$(ps -ef | grep "kubectl port-forward" | grep "redisinsight-service" | awk '{print $2}')
if [ ! -z "$PROC_ID" ]; then kill $PROC_ID; fi
