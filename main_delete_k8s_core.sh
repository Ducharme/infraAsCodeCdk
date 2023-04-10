#!/bin/sh

FORCE=TRUE
APPROVAL=SKIP
#APPROVAL=DEFAULT
#APPROVAL=ALL

START_TIME=`date +%s`

. ./set_env-vars.sh

. ./eks/setEnvVar.sh

STATUSES="CREATE_FAILED CREATE_COMPLETE ROLLBACK_COMPLETE ROLLBACK_FAILED DELETE_FAILED UPDATE_COMPLETE UPDATE_FAILED UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE IMPORT_COMPLETE IMPORT_ROLLBACK_FAILED IMPORT_ROLLBACK_COMPLETE"
STACKS=$(aws cloudformation list-stacks --stack-status-filter $STATUSES | grep "StackName")

WS_STACK=$(echo "$STACKS" | grep "LaFleet-WebsiteStack")
if [ ! -z "$WS_STACK" ]; then
    export EDN1=$(kubectl --kubeconfig=$KUBECONFIG get svc -n haproxy-controller -o json | jq '.items[] | select( .spec.type == "LoadBalancer" ) | .status.loadBalancer.ingress[0].hostname' | tr -d '"')
    export EDN2=$(aws cloudfront list-distributions | jq '.DistributionList | .Items[] | select ( .Comment == "LaFleet React Website" ) | .Origins | .Items [] | select( .DomainName | contains(".elb.")) | .DomainName' | tr -d '"')
    export ELB_DNS_NAME=$(if [ ! -z "$EDN1" ]; then echo "$EDN1"; else echo "$EDN2"; fi)

    echo "Destroying LaFleet-WebsiteStack"
    cdk destroy LaFleet-WebsiteStack $CDK_FORCE || { echo "Destroying LaFleet-WebsiteStack failed, exiting" ; exit 1; }
fi


##########  HA Proxy for ingress via ELB on CDN  ##########

# https://www.haproxy.com/documentation/kubernetes/latest/installation/community/aws/

helm uninstall kubernetes-ingress --namespace haproxy-controller --wait


##########   Prometheus, OpenSearch, fluentbit, Grafana   ##########

. ./osd/uninstall.sh


##########   Metrics Server   ##########

kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml


END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))
echo "FINISHED in $RUN_TIME seconds!"
