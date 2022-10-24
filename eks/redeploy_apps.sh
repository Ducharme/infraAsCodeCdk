#!/bin/sh

REDISEARCH_YAML=./eks/redisearch_service.yml
REDISINSIGHT_YAML=./eks/redisinsight_service.yml
IOT_SERVER_YAML=./eks/iot-server_deployment.yml
PERFORMANCE_YAML=./eks/redisearch-performance-analytics-py_service.yml
DEVICE_CONSUMER_YAML=./eks/sqsdeviceconsumer-toredisearch_deployment.yml
SHAPE_CONSUMER_YAML=./eks/sqsshapeconsumer-toredisearch_deployment.yml
MOCK_DEVICE_YAML=./eks/devices-slow_deployment.yml
QUERY_YAML=./eks/redisearch-query_service.yml

# NICE TO HAVE IF YAML COULD BE PARSED
#sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.1/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
#cat eks/redisearch_service.yml | yq '.metadata[0]'


#lafleet-devices-slow $MOCK_DEVICE_YAML
#lafleet-query-service $QUERY_YAML
#lafleet-analytics $PERFORMANCE_YAML
#lafleet-iot-server $IOT_SERVER_YAML
#lafleet-shape-consumers $SHAPE_CONSUMER_YAML
#lafleet-device-consumers $DEVICE_CONSUMER_YAML
#redisearch $REDISEARCH_YAML
#redisinsight $REDISINSIGHT_YAML

##### Delete

waitForPodToStop(){
    POD_ARG=$1
    YAML_ARG=$2

    POD_LST=$(kubectl get pods -o json | jq '.items[] | .spec.containers[0].name' | tr -d '"')
    POD_CHK=$(echo "$POD_LST" | grep $POD_ARG)
    if [ -z "$POD_CHK" ]; then
         echo "Pod $POD_ARG is not running"
    else
        echo "Waiting for pod $POD_ARG to stop"
        kubectl delete -f $YAML_ARG

        n=0
        until [ "$n" -ge 20 ]
        do
            POD_LST=$(kubectl get pods -o json | jq '.items[] | .spec.containers[0].name' | tr -d '"')
            POD_CHK=$(echo "$POD_LST" | grep $POD_ARG)
            if [ -z "$POD_CHK" ]; then
                break
            fi
            n=$((n+1)) 
            sleep 5
        done
    fi
}

waitForPodToStop mock-iot-gps-device-awssdkv2 $MOCK_DEVICE_YAML
waitForPodToStop redisearch-query-client $QUERY_YAML
waitForPodToStop redisearch-performance-analytics-py $PERFORMANCE_YAML
waitForPodToStop iot-server $IOT_SERVER_YAML
waitForPodToStop sqsshapeconsumer-toredisearch $SHAPE_CONSUMER_YAML
waitForPodToStop sqsdeviceconsumer-toredisearch $DEVICE_CONSUMER_YAML
waitForPodToStop redisinsight $REDISINSIGHT_YAML
waitForPodToStop redisearch $REDISEARCH_YAML


echo "Pods are stopped. Now starting them..."

##### Apply

waitForPodToRun(){
    POD_ARG=$1
    YAML_ARG=$2

    echo "Waiting for pod $POD_ARG to run"
    kubectl apply -f $YAML_ARG

    n=0
    until [ "$n" -ge 20 ]
    do
        JQF=".items[] | select(.spec.containers[0].name == \"$POD_ARG\") | .status.phase"
        POD_STATUS=$(kubectl get pods -o json | jq "$JQF" | tr -d '"')
        if [ "$POD_STATUS" = "Running" ]; then
            break
        fi
        n=$((n+1)) 
        sleep 5
    done
}

waitForPodToRun redisearch $REDISEARCH_YAML
waitForPodToRun redisinsight $REDISINSIGHT_YAML
waitForPodToRun iot-server $IOT_SERVER_YAML
waitForPodToRun redisearch-performance-analytics-py $PERFORMANCE_YAML
waitForPodToRun sqsdeviceconsumer-toredisearch $DEVICE_CONSUMER_YAML
waitForPodToRun sqsshapeconsumer-toredisearch $SHAPE_CONSUMER_YAML
waitForPodToRun mock-iot-gps-device-awssdkv2 $MOCK_DEVICE_YAML
waitForPodToRun redisearch-query-client $QUERY_YAML


echo "FINISHED"
