#!/bin/sh

. ./set_env-vars.sh

kubectl delete -f osd/busybox-logging-pod.yaml
kubectl delete -f osd/fluentbit.yaml

helm uninstall grafana -n monitoring
helm uninstall prometheus -n monitoring
helm uninstall opensearch-dashboards -n logging
helm uninstall opensearch -n logging
kubectl delete secret fluentbit-tls -n logging
kubectl delete pvc opensearch-cluster-master-opensearch-cluster-master-0 -n logging
kubectl delete pvc storage-prometheus-alertmanager-0 -n monitoring


waitForPod(){
    POD_NAME=$1
    echo "Waiting for pod(s) $POD_NAME"

    while true
    do
        RES=$(kubectl get po -A | grep "$POD_NAME" | tr -d '" \t\n\r')
        if [ "$RES" = "" ]; then
            break
        fi
        sleep 1
    done
    echo "No pod $POD_NAME running anymore"
}

waitForPod "hello-deployment"
waitForPod "metrics-server-"
waitForPod "fluent-bit-"

waitForPod "grafana-"
waitForPod "prometheus-"

waitForPod "opensearch-"