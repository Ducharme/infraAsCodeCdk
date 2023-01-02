#!/bin/sh

export PROJECT_NAME=lafleet
export AWS_REGION_VALUE=$(aws configure get region)
AWS_ACCOUNT_ID_VALUE=$(aws sts get-caller-identity --query "Account" --output text)
export S3_OBJECT_STORE=$PROJECT_NAME-object-store-$AWS_ACCOUNT_ID_VALUE
export S3_REACT_WEB=$PROJECT_NAME-react-web-$AWS_ACCOUNT_ID_VALUE
export S3_CODEBUILD_ARTIFACTS=$PROJECT_NAME-codebuild-artifacts-repo-$AWS_ACCOUNT_ID_VALUE
export S3_CODEPIPELINE_ARTIFACTS=$PROJECT_NAME-codepipeline-artifacts-repo-$AWS_ACCOUNT_ID_VALUE
export S3_SHAPE_REPO=$PROJECT_NAME-shape-repo-$AWS_ACCOUNT_ID_VALUE

DEVICE_SQS_QUEUE_NAME=$PROJECT_NAME-device-messages
SHAPE_SQS_QUEUE_NAME=$PROJECT_NAME-shape-messages
export ELB_DNS_NAME=NOT_READY
export STREAMING_LOCATION_TOPIC=$PROJECT_NAME/devices/location/+/streaming
export STREAMID_REQUEST_TOPIC=$PROJECT_NAME/devices/streamId/+/request
export STREAMID_REPLY_TOPIC=$PROJECT_NAME/devices/streamId/+/reply

LAMBDA_LAYER_DIR=./tmp/lambda-layers
GITHUB_DIR=./tmp/github
CODECOMMIT_DIR=./tmp/codecommit
CONFIG_DIR=./tmp/config

export DEVICE_REPO=mockIotGpsDeviceAwsSdkV2
export DEVICE_DESC="$PROJECT_NAME - Emulated IoT GPS Device based on aws-iot-device-sdk-v2"
export DEVICE_IMAGE_REPO="mock-iot-gps-device-awssdkv2"
export IOT_SERVER_REPO=iotServer
export IOT_SERVER_DESC="$PROJECT_NAME - IoT Server based on aws-iot-device-sdk-v2"
export IOT_SERVER_IMAGE_REPO="iot-server"
export DEVICE_CONSUMER_REPO=sqsDeviceConsumerToRedisearch
export DEVICE_CONSUMER_DESC="$PROJECT_NAME - SQS Device Consumer writing to Redisearch in TypeScript"
export DEVICE_CONSUMER_IMAGE_REPO="sqsdeviceconsumer-toredisearch"
export SHAPE_CONSUMER_REPO=sqsShapeConsumerToRedisearch
export SHAPE_CONSUMER_DESC="$PROJECT_NAME - SQS Shape Consumer writing to Redisearch in TypeScript"
export SHAPE_CONSUMER_IMAGE_REPO="sqsshapeconsumer-toredisearch"
export QUERY_REPO=redisearchQueryClient
export QUERY_DESC="$PROJECT_NAME - Service to query Redisearch in TypeScript"
export QUERY_IMAGE_REPO="redisearch-query-client"
export ANALYTICS_REPO=redisPerformanceAnalyticsPy
export ANALYTICS_DESC="$PROJECT_NAME - Redis performance analytics in python3"
export ANALYTICS_IMAGE_REPO="redisearch-performance-analytics-py"
export REACT_REPO=reactFrontend
export REACT_DESC="$PROJECT_NAME - React Frontend in TypeScript"
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
