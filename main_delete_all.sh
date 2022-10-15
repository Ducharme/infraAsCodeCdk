#!/bin/sh

FORCE=TRUE
. ./set_env-vars.sh

echo "Deleting all ECR images"
. ./deleteEcrImages.sh || { echo "Deleting all ECR images failed, exiting" ; exit 1; }

echo "Deleting S3 buckets objects"
. ./deleteS3objects.sh || { echo "Deleting S3 buckets objects failed, exiting" ; exit 1; }

. ./eks/setEnvVar.sh

STATUSES="CREATE_FAILED CREATE_COMPLETE ROLLBACK_COMPLETE ROLLBACK_FAILED DELETE_FAILED UPDATE_COMPLETE UPDATE_FAILED UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE IMPORT_COMPLETE IMPORT_ROLLBACK_FAILED IMPORT_ROLLBACK_COMPLETE"
STACKS=$(aws cloudformation list-stacks --stack-status-filter $STATUSES | grep "StackName")

WS_STACK=$(echo "$STACKS" | grep "LaFleet-WebsiteStack")
if [ ! -z "$WS_STACK" ]; then
    export ELB_DNS_NAME=$(kubectl get svc -n haproxy-controller -o json | jq '.items[] | select( .spec.type == "LoadBalancer" ) | .status.loadBalancer.ingress[0].hostname' | tr -d '"')
    if [ ! -z "$ELB_DNS_NAME" ]; then
        ELB_DNS_NAME=$(aws cloudfront list-distributions | jq '.DistributionList | .Items[] | select ( .Comment == "LaFleet React Website" ) | .Origins | .Items [] | select( .DomainName | contains(".elb.")) | .DomainName' | tr -d '"')
    fi

    echo "Destroying LaFleet-WebsiteStack"
    cdk destroy LaFleet-WebsiteStack $CDK_FORCE || { echo "Destroying LaFleet-WebsiteStack failed, exiting" ; exit 1; }
fi

EC_STACK=$(echo "$STACKS" | grep "eksctl")
if [ ! -z "$EC_STACK" ]; then
    echo "Removing apps on K8s"
    . ./eks/delete_apps.sh || { echo "Removing apps on K8s failed, exiting" ; exit 1; }

    echo "Deleting K8s cluster"
    . ./eksctl/delete_cluster.sh || { echo "Deleting K8s cluster failed, exiting" ; exit 1; }
fi

AS_STACK=$(echo "$STACKS" | grep "LaFleet-AnalyticsStack")
if [ ! -z "$AS_STACK" ]; then
    echo "Destroying LaFleet-AnalyticsStack"
    cdk destroy LaFleet-AnalyticsStack $CDK_FORCE || { echo "Destroying LaFleet-AnalyticsStack failed, exiting" ; exit 1; }
fi

QS_STACK=$(echo "$STACKS" | grep "LaFleet-QueryStack")
if [ ! -z "$QS_STACK" ]; then
    echo "Destroying LaFleet-QueryStack"
    cdk destroy LaFleet-QueryStack $CDK_FORCE || { echo "Destroying LaFleet-QueryStack failed, exiting" ; exit 1; }
fi

SC_STACK=$(echo "$STACKS" | grep "LaFleet-ShapeConsumerStack")
if [ ! -z "$SC_STACK" ]; then
    echo "Destroying LaFleet-ShapeConsumerStack"
    cdk destroy LaFleet-ShapeConsumerStack $CDK_FORCE || { echo "Destroying LaFleet-ShapeConsumerStack failed, exiting" ; exit 1; }
fi

DC_STACK=$(echo "$STACKS" | grep "LaFleet-DeviceConsumerStack")
if [ ! -z "$DC_STACK" ]; then
    echo "Destroying LaFleet-DeviceConsumerStack"
    cdk destroy LaFleet-DeviceConsumerStack $CDK_FORCE || { echo "Destroying LaFleet-DeviceConsumerStack failed, exiting" ; exit 1; }
fi

SS_STACK=$(echo "$STACKS" | grep "LaFleet-ShapeStack")
if [ ! -z "$SS_STACK" ]; then
    echo "Destroying LaFleet-ShapeStack"
    cdk destroy LaFleet-ShapeStack $CDK_FORCE || { echo "Destroying LaFleet-ShapeStack failed, exiting" ; exit 1; }
fi

IS_STACK=$(echo "$STACKS" | grep "LaFleet-IotServerStack")
if [ ! -z "$IS_STACK" ]; then
    echo "Destroying LaFleet-IotServerStack"
    cdk destroy LaFleet-IotServerStack $CDK_FORCE || { echo "Destroying LaFleet-IotServerStack failed, exiting" ; exit 1; }
fi

DS_STACK=$(echo "$STACKS" | grep "LaFleet-DeviceStack")
if [ ! -z "$DS_STACK" ]; then
    echo "Destroying LaFleet-DeviceStack"
    cdk destroy LaFleet-DeviceStack $CDK_FORCE || { echo "Destroying LaFleet-DeviceStack failed, exiting" ; exit 1; }
fi

CO_STACK=$(echo "$STACKS" | grep "LaFleet-CommonStack")
if [ ! -z "$CO_STACK" ]; then
    echo "Destroying LaFleet-CommonStack"
    cdk destroy LaFleet-CommonStack $CDK_FORCE || { echo "Destroying LaFleet-CommonStack failed, exiting" ; exit 1; }
fi

#cdk destroy --all
