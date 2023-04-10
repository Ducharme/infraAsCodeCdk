#!/bin/sh

. ./eks/setEnvVar.sh

CLUSTER_NAME=$PROJECT_NAME-cluster
AWS_EKS_CLUSTERS=$(aws eks list-clusters)
AWS_EKS_CLUSTER=$(echo $AWS_EKS_CLUSTERS | grep $CLUSTER_NAME)

if [ ! -z "$AWS_EKS_CLUSTER" ]; then
  eksctl delete cluster -f ./eksctl/lafleet.yaml --wait
fi
