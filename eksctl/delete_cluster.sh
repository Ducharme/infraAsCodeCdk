#!/bin/sh

. ./eks/setEnvVar.sh

CLUSTER_NAME=$PROJECT_NAME-cluster
AWS_EKS_CLUSTERS=$(aws eks list-clusters)
AWS_EKS_CLUSTER=$(echo $AWS_EKS_CLUSTERS | grep $CLUSTER_NAME)

if [ ! -z "$AWS_EKS_CLUSTER" ]; then
  kubectl delete pdb ebs-csi-controller -n kube-system
  eksctl delete addon --cluster $CLUSTER_NAME --name aws-ebs-csi-driver
  sleep 10
  
  ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups | jq '.AutoScalingGroups[] | .AutoScalingGroupName' | tr -d '"')
  NODE_GROUP_NAMES=$(cat eksctl/lafleet.yaml | yq '.managedNodeGroups[] | .name')
  echo "$NODE_GROUP_NAMES" | tr ' ' '\n' | while read item; do
      ASG_NAME=$(echo "$ASG_NAMES" | grep "$item")
      echo "aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity 0 --no-honor-cooldown"
      aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity 0 --no-honor-cooldown
  done

  # Focus on ebs-csi-controller-68ccc8cc6d-99wrs and ebs-csi-node-26vl8, leave coredns-7cc96f45bb-j2bd5 for now
  K8S_PODS=$(kubectl get pods -n kube-system -o json | jq '.items[] | select (.metadata.name | startswith("ebs-csi-")) | .metadata.name' | tr -d '"' | tr '\n' ' ')
  echo "kubectl get pods -n kube-system -o json | grep ebs-csi-: $K8S_PODS"
  if [ ! "$K8S_PODS" = "" ]; then
      echo "kubectl delete pods $K8S_PODS -n kube-system"
      kubectl delete pods $K8S_PODS -n kube-system
  fi

  K8S_NODES=$(kubectl get nodes -o json | jq '.items[] | .metadata.name' | tr -d '"' | tr '\n' ' ')
  echo "kubectl get nodes -o json: $K8S_NODES"
  if [ ! "$K8S_NODES" = "" ]; then
      echo "kubectl delete nodes $K8S_NODES"
      kubectl delete node $K8S_NODES
  fi

  AWS_NODES=$(aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | .InstanceId' | tr -d '"' | tr '\n' ' ')
  echo "aws ec2 describe-instances: $AWS_NODES"
  if [ ! "$AWS_NODES" = "" ]; then
      echo "aws ec2 stop-instances --instance-ids $AWS_NODES"
      aws ec2 stop-instances --instance-ids $AWS_NODES
  fi

  eksctl delete cluster -f ./eksctl/lafleet.yaml --wait
fi
