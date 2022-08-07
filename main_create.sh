#!/bin/sh

FORCE=TRUE
APPROVAL=SKIP
#APPROVAL=DEFAULT
#APPROVAL=ALL

. ./set_env-vars.sh


### Setup Lambda layer

if [ -d "$LAMBDA_LAYER_DIR" ]; then
    echo "Lambda layer already created in $LAMBDA_LAYER_DIR"
else
    echo "Creating lambda layer in $LAMBDA_LAYER_DIR"
    . ./createLambdaLayer.sh || { echo "Creating lambda layer in $LAMBDA_LAYER_DIR failed, exiting" ; exit 1; }
fi


### Setup GitHub repos

if [ -d "$GITHUB_DIR" ]; then
    echo "Repostories already exist in $GITHUB_DIR"
else
    echo "Downloading github repositories to $GITHUB_DIR"
    . ./downloadRepos.sh || { echo "Downloading github repositories to $GITHUB_DIR failed, exiting" ; exit 1; }
fi


### Setup config script

echo "Installing script-utils dependencies"
CUR_FOLDER=$PWD
cd ./lib/script-utils
npm install
cd $CUR_FOLDER


### Get existing certificate from S3 if any

S3_BUCKETS=$(aws s3api list-buckets | grep '"Name"')
S3_BUCKET=$(echo "$S3_BUCKETS" | grep $S3_OBJECT_STORE)
if [ ! -z "$S3_BUCKET" ]; then
    CERT_TXT_FILE=certificate-id.txt
    S3_OBJECT_STORE_FILE=$(aws s3 ls s3://$S3_OBJECT_STORE/certs/$CERT_TXT_FILE)
    if [ "$S3_OBJECT_STORE_FILE" = "" ]; then
        test -f ./tmp/$CERT_TXT_FILE && rm -fv ./tmp/$CERT_TXT_FILE
    else
        aws s3 cp s3://$S3_OBJECT_STORE/certs/$CERT_TXT_FILE ./tmp/
        test $? -eq 0 || { echo "Copying certs to S3 failed, exiting" ; exit 1; }
    fi
fi


### CDK deployments

echo "Deploying LaFleet-CommonStack"
cdk deploy LaFleet-CommonStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-CommonStack failed, exiting" ; exit 1; }

echo "Deploying LaFleet-DeviceStack"
cdk deploy LaFleet-DeviceStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-DeviceStack failed, exiting" ; exit 1; }
node ./lib/script-utils/main.js $DEVICE_REPO || { echo "Creating $DEVICE_REPO config failed, exiting" ; exit 1; }

echo "Deploying LaFleet-DeviceConsumerStack"
cdk deploy LaFleet-DeviceConsumerStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-DeviceConsumerStack failed, exiting" ; exit 1; }
node ./lib/script-utils/main.js $DEVICE_CONSUMER_REPO || { echo "Creating $DEVICE_CONSUMER_REPO config failed, exiting" ; exit 1; }

echo "Deploying LaFleet-ShapeConsumerStack"
cdk deploy LaFleet-ShapeConsumerStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-ShapeConsumerStack failed, exiting" ; exit 1; }
node ./lib/script-utils/main.js $SHAPE_CONSUMER_REPO || { echo "Creating $SHAPE_CONSUMER_REPO config failed, exiting" ; exit 1; }

echo "Deploying LaFleet-QueryStack"
cdk deploy LaFleet-QueryStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-QueryStack failed, exiting" ; exit 1; }
node ./lib/script-utils/main.js $QUERY_REPO || { echo "Creating $QUERY_REPO config failed, exiting" ; exit 1; }

echo "Deploying LaFleet-AnalyticsStack"
cdk deploy LaFleet-AnalyticsStack $CDK_APPROVAL $SDK_APPROVAL || { echo "Deploying LaFleet-AnalyticsStack failed, exiting" ; exit 1; }
node ./lib/script-utils/main.js $ANALYTICS_REPO || { echo "Creating $ANALYTICS_REPO config failed, exiting" ; exit 1; }

#echo "Overriding CodeProject ArtifactName..."
#. ./overrideArtifactName.sh

echo "FINISHED!"
