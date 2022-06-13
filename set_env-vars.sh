#!/bin/sh

export PROJECT_NAME=lafleet
export AWS_REGION_VALUE=$(aws configure get region)
AWS_ACCOUNT_ID_VALUE=$(aws sts get-caller-identity --query "Account" --output text)
export S3_OBJECT_STORE=$PROJECT_NAME-object-store-$AWS_ACCOUNT_ID_VALUE
export S3_REACT_WEB=$PROJECT_NAME-react-web-$AWS_ACCOUNT_ID_VALUE
export S3_CODEBUILD_ARTIFACTS=$PROJECT_NAME-codebuild-artifacts-repo-$AWS_ACCOUNT_ID_VALUE
export S3_CODEPIPELINE_ARTIFACTS=$PROJECT_NAME-codepipeline-artifacts-repo-$AWS_ACCOUNT_ID_VALUE

SQS_QUEUE_NAME=$PROJECT_NAME-device-messages
export ELB_DNS_NAME=NOT_READY
export THING_TOPIC=topic_1

LAMBDA_LAYER_DIR=./tmp/lambda-layers
GITHUB_DIR=./tmp/github
CONFIG_DIR=./tmp/config

export DEVICE_REPO=mockIotGpsDeviceAwsSdkV2
export DEVICE_DESC="LaFleet - Emulated IoT GPS Device based on aws-iot-device-sdk-v2"
export DEVICE_IMAGE_REPO="mock-iot-gps-device-awssdkv2"
export CONSUMER_REPO=sqsConsumerToRedisearchJs
export CONSUMER_DESC="LaFleet - SQS Consumer to Redisearch in Javascript"
export CONSUMER_IMAGE_REPO="sqsconsumer-toredisearch-js"
export QUERY_REPO=redisearchQueryClient
export QUERY_DESC="LaFleet - Service to query Redisearch in Javascript"
export QUERY_IMAGE_REPO="redisearch-query-client"
export ANALYTICS_REPO=redisPerformanceAnalyticsPy
export ANALYTICS_DESC="LaFleet - Redis performance analytics in python3"
export ANALYTICS_IMAGE_REPO="redisearch-performance-analytics-py"
export REACT_REPO=reactFrontend
export REACT_DESC="LaFleet - React Frontend in TypeScript"
export CODEBUILD_BRANCH_NAME="main";

FORCE_UPPER=$(echo $FORCE | tr 'a-z' 'A-Z')
if [ "$FORCE" = "TRUE" ]; then
  CDK_FORCE=--force
else
  CDK_FORCE=
fi

CDK_APPROVAL=""
if [ "$APPROVAL" = "ALL" ]; then
    # Requires approval on any IAM or security-group-related change
    CDK_APPROVAL="--require-approval any-change"
elif [ "$APPROVAL" = "SKIP" ]; then
    # Approval is never required
    CDK_APPROVAL="--require-approval never"
elif [ "$APPROVAL" = "DEFAULT" ]; then
    # Requires approval when IAM statements or traffic rules are added (default)
    CDK_APPROVAL="--require-approval broadening "
fi
