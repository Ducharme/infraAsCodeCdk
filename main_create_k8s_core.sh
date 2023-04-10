#!/bin/sh

FORCE=TRUE
APPROVAL=SKIP
#APPROVAL=DEFAULT
#APPROVAL=ALL

START_TIME=`date +%s`

. ./set_env-vars.sh

### Get mapbox token from .env.* config if any

ENV_CFG_FILE=.env.production
if [ -f "$ENV_CFG_FILE" ]; then
    MAPBOX_TOKEN=$(grep MAPBOX_TOKEN $ENV_CFG_FILE | cut -d '=' -f2)
    if [ "$MAPBOX_TOKEN" = "" ]; then
        echo "MAPBOX_TOKEN not found in $ENV_CFG_FILE config file, aborting"
        exit 1
    fi
else
    echo "Config file $ENV_CFG_FILE does not exist, abording"
    exit 1
fi

. ./eks/setEnvVar.sh

helm repo add stable https://charts.helm.sh/stable
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update


##########   Metrics Server   ##########

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml


##########   Prometheus, OpenSearch, fluentbit, Grafana   ##########

. ./osd/install.sh


##########  HA Proxy for ingress via ELB on CDN  ##########

# https://www.haproxy.com/documentation/kubernetes/latest/installation/community/aws/

helm install kubernetes-ingress haproxytech/kubernetes-ingress \
     --create-namespace --namespace haproxy-controller \
     --set controller.service.type=LoadBalancer

export ELB_DNS_NAME=$(kubectl --kubeconfig=$KUBECONFIG get svc -n haproxy-controller -o json | jq '.items[] | select( .spec.type == "LoadBalancer" ) | .status.loadBalancer.ingress[0].hostname' | tr -d '"')
if [ ! -z "$ELB_DNS_NAME" ]; then
    echo "Deploying LaFleet-WebsiteStack"
    cdk deploy LaFleet-WebsiteStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-WebsiteStack failed, exiting" ; exit 1; }
    node ./lib/script-utils/main.js $REACT_REPO || { echo "Creating $REACT_REPO config failed, exiting" ; exit 1; }
fi

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))
echo "FINISHED in $RUN_TIME seconds!"
