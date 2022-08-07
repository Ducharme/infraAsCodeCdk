#!/bin/sh

CLUSTER_NAME=$PROJECT_NAME-cluster
EKS_DEVICE_SQS_SA_NAME=$PROJECT_NAME-eks-sa-sqsdeviceconsumer
EKS_SHAPE_SQS_SA_NAME=$PROJECT_NAME-eks-sa-sqsshapeconsumer

. ./eks/setEnvVar.sh

AWS_EKS_CLUSTERS=$(aws eks list-clusters)
AWS_EKS_CLUSTER=$(echo $AWS_EKS_CLUSTERS | grep $CLUSTER_NAME)

if [ ! -z "$AWS_EKS_CLUSTER" ]; then
  eksctl delete cluster -f ./eksctl/lafleet.yaml --wait
fi
