#!/bin/sh

ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups | jq '.AutoScalingGroups[] | .AutoScalingGroupName' | tr -d '"')
NODE_GROUP_NAMES=$(cat eksctl/lafleet.yaml | yq '.managedNodeGroups[] | .name')
echo "$NODE_GROUP_NAMES" | tr ' ' '\n' | while read item; do
    ASG_NAME=$(echo "$ASG_NAMES" | grep "$item")
    ASG_DC=$(cat eksctl/lafleet.yaml | yq ".managedNodeGroups[] | select (.name == \"$item\") | .desiredCapacity")
    aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity $ASG_DC --no-honor-cooldown
done

ALL_DC=$(cat eksctl/lafleet.yaml | yq ".managedNodeGroups[] | .desiredCapacity")
I=0; for N in $(echo "$ALL_DC"); do I=$(($I + $N)); done;
echo "Waiting for $I nodes to be up"

n=0
until [ "$n" -ge 20 ]
do
    GET_NODES=$(kubectl get no -o json | jq '.items[] | .status.conditions[] | select(.type == "Ready" and .status == "True") | .type' | tr -d '"')
    READY_CNT=$(echo "$GET_NODES" | grep "Ready" | wc -l)
    echo "$READY_CNT nodes are ready"
    if [ "$READY_CNT" = "$I" ]; then
        break
    fi
    n=$((n+1)) 
    sleep 5
done

# TODO: Have sidecar pod to create index on the redis instance instead of running a script
. ./eks/create_redis_index.sh

echo "FINISHED"
