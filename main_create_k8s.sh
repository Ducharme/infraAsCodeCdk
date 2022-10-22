#!/bin/sh

FORCE=TRUE
APPROVAL=SKIP
#APPROVAL=DEFAULT
#APPROVAL=ALL

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

echo "Creating K8s cluster"
. ./eksctl/create_cluster.sh || { echo "Creating K8s cluster failed, exiting" ; exit 1; }


. ./eks/setEnvVar.sh

##########   Metrics Server   ##########

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
helm repo add stable https://charts.helm.sh/stable
helm repo update

##########  HA Proxy for ingress via ELB on CDN  ##########

# https://www.haproxy.com/documentation/kubernetes/latest/installation/community/aws/

helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo update
helm install kubernetes-ingress haproxytech/kubernetes-ingress \
     --create-namespace --namespace haproxy-controller \
     --set controller.service.type=LoadBalancer


export ELB_DNS_NAME=$(kubectl --kubeconfig=$KUBECONFIG get svc -n haproxy-controller -o json | jq '.items[] | select( .spec.type == "LoadBalancer" ) | .status.loadBalancer.ingress[0].hostname' | tr -d '"')
if [ ! -z "$ELB_DNS_NAME" ]; then
    echo "Deploying LaFleet-WebsiteStack"
    cdk deploy LaFleet-WebsiteStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-WebsiteStack failed, exiting" ; exit 1; }
    node ./lib/script-utils/main.js $REACT_REPO || { echo "Creating $REACT_REPO config failed, exiting" ; exit 1; }
fi

##########  Kubernetes Dashboard (Web UI)  ##########

# From https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml
kubectl proxy
K8S_DASHBOARD_LINK=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

K8S_DASHBOARD_USER=k8s-dashboard-user
kubectl create serviceaccount $K8S_DASHBOARD_USER
kubectl create clusterrolebinding $K8S_DASHBOARD_USER-binding --clusterrole=cluster-admin --serviceaccount=default:$K8S_DASHBOARD_USER

K8S_DASHBOARD_SECRET=$(kubectl get secrets | grep "$K8S_DASHBOARD_USER" | cut -d ' ' -f1)
K8S_DASHBOARD_TOKEN=$(kubectl describe secret $K8S_DASHBOARD_SECRET | grep "token:" | cut -d ':' -f2 | tr -d ' ')

echo ""
echo "*** NOTE - Kubernetes Dashboard (Web UI) ***"
echo "K8S DASHBOARD LINK is $K8S_DASHBOARD_LINK"
echo "Underlying Service Account $K8S_DASHBOARD_USER hold the Secret"
echo "Login with  with Bearer Token $K8S_DASHBOARD_TOKEN"
echo ""

echo "FINISHED!"
