#!/bin/sh

CLUSTER_NAME=$PROJECT_NAME-cluster
EKS_DEVICE_SQS_SA_NAME=$PROJECT_NAME-eks-sa-sqsdeviceconsumer
EKS_SHAPE_SQS_SA_NAME=$PROJECT_NAME-eks-sa-sqsshapeconsumer

. ./eks/setEnvVar.sh

eksctl create cluster -f ./eksctl/lafleet.yaml --auto-kubeconfig
# Next 3 lines needed for creating an ARM nodegroup kube-proxy
eksctl utils update-coredns --cluster $CLUSTER_NAME
eksctl utils update-kube-proxy --cluster $CLUSTER_NAME --approve
eksctl utils update-aws-node --cluster $CLUSTER_NAME --approve
