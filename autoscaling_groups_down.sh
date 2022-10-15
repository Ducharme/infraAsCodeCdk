#!/bin/sh

ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups | jq '.AutoScalingGroups[] | .AutoScalingGroupName' | tr -d '"')
NODE_GROUP_NAMES=$(cat eksctl/lafleet.yaml | yq '.managedNodeGroups[] | .name')
echo "$NODE_GROUP_NAMES" | tr ' ' '\n' | while read item; do
    ASG_NAME=$(echo "$ASG_NAMES" | grep "$item")
    aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity 0 --no-honor-cooldown
done

echo "Waiting for nodes to shutdown"

n=0
until [ "$n" -ge 20 ]
do
    GET_NODES_CNT=$(kubectl get no -o json | jq '.items | length')
    if [ "$GET_NODES_CNT" = "0" ]; then
        break
    fi
    n=$((n+1)) 
    sleep 5
done

echo "FINISHED"
