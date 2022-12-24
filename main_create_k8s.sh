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

helm repo add stable https://charts.helm.sh/stable
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update


##########   Metrics Server   ##########

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

##########   https://github.com/kubernetes-sigs/aws-ebs-csi-driver   ##########

## https://aws.amazon.com/premiumsupport/knowledge-center/eks-persistent-storage/

K8S_DIR=./tmp/k8s
mkdir -p "$K8S_DIR"
curl -o $K8S_DIR/pv-ebs-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v0.9.0/docs/example-iam-policy.json
aws iam create-policy --policy-name AmazonEKS_EBS_CSI_Driver_Policy --policy-document file://$K8S_DIR/pv-ebs-iam-policy.json
OIDC_URL=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text)
REPLACE_BY=""
OIDC_PATH=$(echo "$OIDC_URL" | sed "s/https:\/\//$REPLACE_BY/")

cat <<EOF > $K8S_DIR/pv-ebs-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID_VALUE:oidc-provider/$OIDC_PATH"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$OIDC_PATH:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF

aws iam create-role --role-name AmazonEKS_EBS_CSI_DriverRole --assume-role-policy-document file://$K8S_DIR/pv-ebs-trust-policy.json
aws iam attach-role-policy --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID_VALUE:policy/AmazonEKS_EBS_CSI_Driver_Policy --role-name AmazonEKS_EBS_CSI_DriverRole
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::$AWS_ACCOUNT_ID_VALUE:role/AmazonEKS_EBS_CSI_DriverRole
kubectl delete pods -n kube-system -l=app=ebs-csi-controller
#helm upgrade --install aws-ebs-csi-driver --namespace kube-system aws-ebs-csi-driver/aws-ebs-csi-driver


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

##########   Fluent Bit   ##########

# From https://docs.fluentbit.io/manual/v/1.8/installation/kubernetes#container-runtime-interface-cri-parser
$ kubectl create namespace logging
$ kubectl create -f eks/fluentbit_basics.yaml
$ kubectl create -f eks/fluentbit_cm.yaml
$ kubectl create -f eks/fluentbit_ds.yaml


##########   Prometheus   ##########

# Look at README.md "Prometheus" for instructions to connect
helm install --set prometheus-node-exporter.tolerations[0].operator=Exists,prometheus-node-exporter.tolerations[0].effect=NoSchedule,prometheus-node-exporter.tolerations[0].key=dedicated-compute \
  --set prometheus-node-exporter.priorityClassName=system-node-critical prometheus prometheus-community/prometheus


##########  OpenSearch  ##########

# Look at README.md "OpenSearch dashboard" for instructions to connect
helm install opensearch opensearch/opensearch --set singleNode=true
helm install opensearch-dashboards opensearch/opensearch-dashboards

##########  Grafana  ##########

# Look at README.md "Grafana" for instructions to get the password and connect
helm install --set persistence.enabled=true --set persistence.size=1Gi grafana grafana/grafana

. ./eks/import_grafana_dashboards.sh

echo "FINISHED!"
