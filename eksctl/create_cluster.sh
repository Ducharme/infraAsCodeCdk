#!/bin/sh

CLUSTER_NAME=$PROJECT_NAME-cluster

. ./eks/setEnvVar.sh


TEMPLATE_YAML=eksctl/lafleet_template.yaml
VALUES_YAML=eksctl/lafleet.yaml
cp $TEMPLATE_YAML $VALUES_YAML

# Recommended "c6i.large" with 2 vCPU & 4 GiB Memory (29 pods) for COMPUTE_INSTANCE_TYPE
COMPUTE_INSTANCE_TYPE=c6i.large
# Recommended "t3.medium" with 2 vCPU & 4 GiB Memory (17 pods) for STANDARD_INSTANCE_TYPE
STANDARD_INSTANCE_TYPE=c6i.large
RES_DEVICE_SQS_QUEUE=arn:aws:sqs:$AWS_REGION_VALUE:$AWS_ACCOUNT_ID_VALUE:$DEVICE_SQS_QUEUE_NAME
RES_SHAPE_SQS_QUEUE=arn:aws:sqs:$AWS_REGION_VALUE:$AWS_ACCOUNT_ID_VALUE:$SHAPE_SQS_QUEUE_NAME
RES_S3_SHAPE_REPO=arn:aws:s3:::$S3_SHAPE_REPO/*
USE_SPOT_INSTANCES=false

sed -i 's@PROJECT_NAME@'"$PROJECT_NAME"'@g' $VALUES_YAML
sed -i 's@AWS_REGION_VALUE@'"$AWS_REGION_VALUE"'@g' $VALUES_YAML
sed -i 's@RES_DEVICE_SQS_QUEUE@'"$RES_DEVICE_SQS_QUEUE"'@g' $VALUES_YAML
sed -i 's@RES_SHAPE_SQS_QUEUE@'"$RES_SHAPE_SQS_QUEUE"'@g' $VALUES_YAML
sed -i 's@RES_S3_SHAPE_REPO@'"$RES_S3_SHAPE_REPO"'@g' $VALUES_YAML
sed -i 's@STANDARD_INSTANCE_TYPE@'"$STANDARD_INSTANCE_TYPE"'@g' $VALUES_YAML
sed -i 's@COMPUTE_INSTANCE_TYPE@'"$COMPUTE_INSTANCE_TYPE"'@g' $VALUES_YAML
sed -i 's@USE_SPOT_INSTANCES@'"$USE_SPOT_INSTANCES"'@g' $VALUES_YAML


eksctl create cluster -f ./eksctl/lafleet.yaml --auto-kubeconfig
eksctl utils write-kubeconfig --cluster=lafleet-cluster --kubeconfig=/home/$USER/.kube/eksctl/clusters/lafleet-cluster


eksctl utils update-coredns --cluster $CLUSTER_NAME
eksctl utils update-kube-proxy --cluster $CLUSTER_NAME --approve
eksctl utils update-aws-node --cluster $CLUSTER_NAME --approve

# IAM OIDC provider for your cluster https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
# Amazon EBS CSI driver IAM role for service accounts https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster $CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve --role-only --role-name AmazonEKS_EBS_CSI_DriverRole
# Managing the Amazon EBS CSI driver as an Amazon EKS add-on https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html
eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --service-account-role-arn arn:aws:iam::$AWS_ACCOUNT_ID_VALUE:role/AmazonEKS_EBS_CSI_DriverRole --force
