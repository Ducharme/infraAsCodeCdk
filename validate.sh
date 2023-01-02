#!/bin/sh

. ./set_env-vars.sh

CHK_DIR=./tmp/check
mkdir -p "$CHK_DIR"
mkdir -p "$CHK_DIR/certs"
mkdir -p "$CHK_DIR/certs/$DEVICE_REPO"
mkdir -p "$CHK_DIR/certs/$IOT_SERVER_REPO"
mkdir -p "$CHK_DIR/config/$DEVICE_REPO"
mkdir -p "$CHK_DIR/config/$IOT_SERVER_REPO"
mkdir -p "$CHK_DIR/config/$DEVICE_CONSUMER_REPO"
mkdir -p "$CHK_DIR/config/$SHAPE_CONSUMER_REPO"
mkdir -p "$CHK_DIR/config/$QUERY_REPO"
mkdir -p "$CHK_DIR/config/$ANALYTICS_REPO"
mkdir -p "$CHK_DIR/config/$REACT_REPO"
mkdir -p "$CHK_DIR/web/$REACT_REPO"

##################################################
##########          Common           #############
##################################################

S3_BUCKET_LST=$(aws s3api list-buckets | grep '"Name"' | cut -d ':' -f2 |  tr -d '", ')

checkIfBucketExists(){
    S3_BUCKET_ARG=$1
    S3_BUCKET_CHK=$(echo "$S3_BUCKET_LST" | grep $S3_BUCKET_ARG)
    if [ ! -z "$S3_BUCKET_CHK" ]; then
        echo "OK bucket $S3_BUCKET_CHK exists"
    else
        echo "NOK bucket $S3_BUCKET_CHK does not exist"
    fi
}

checkIfBucketExists $S3_REACT_WEB
checkIfBucketExists $S3_OBJECT_STORE
checkIfBucketExists $S3_CODEBUILD_ARTIFACTS
checkIfBucketExists $S3_CODEPIPELINE_ARTIFACTS
checkIfBucketExists $S3_SHAPE_REPO

# TODO: Fix teh FOUND not keeping its value
SQS_QUEUE_LST=$(aws sqs list-queues | grep https  | tr -d '", ')
checkIfQueuesExist(){
    SQS_QUEUE_ARG=$1

    #https://sqs.ap-southeast-1.amazonaws.com/748293476463/lafleet-shape-messages-dlq
    SQS_QUEUE_URL_EXP=https://sqs.$AWS_REGION_VALUE.amazonaws.com/$AWS_ACCOUNT_ID_VALUE/$SQS_QUEUE_ARG
    SQS_QUEUE_CNT=$(echo "$SQS_QUEUE_LST" | grep $SQS_QUEUE_URL_EXP | wc -l)
    
    if [ "$SQS_QUEUE_CNT" = "2" ]; then
        echo "OK queue $SQS_QUEUE_URL_EXP and its dlq exist"
    else
        echo "NOK queue $SQS_QUEUE_URL_EXP and its dlq do not exist"
    fi
}

checkIfQueuesExist $DEVICE_SQS_QUEUE_NAME
checkIfQueuesExist $SHAPE_SQS_QUEUE_NAME


##################################################
##########          Device           #############
##################################################

IOT_THING_LST=$(aws iot list-things | grep thingName | cut -d ':' -f2 |  tr -d '", ')
checkIfThingExists(){
    IOT_THING_ARG=$1
    IOT_THING_CHK=$(echo "$IOT_THING_LST" | grep $IOT_THING_ARG)

    if [ ! -z "$IOT_THING_CHK" ]; then
        echo "OK thing $IOT_THING_CHK exists"
    else
        echo "NOK thing $IOT_THING_CHK does not exist"
    fi
}

IOT_POLICY_LST=$(aws iot list-policies | grep policyName | cut -d ':' -f2 |  tr -d '", ')
checkIfPolicyExists(){
    IOT_POLICY_ARG=$1
    IOT_POLICY_CHK=$(echo "$IOT_POLICY_LST" | grep $IOT_POLICY_ARG)

    if [ ! -z "$IOT_POLICY_CHK" ]; then
        echo "OK policy $IOT_POLICY_CHK exists"
    else
        echo "NOK policy $IOT_POLICY_CHK does not exist"
    fi
}

checkIfCertificateExists(){
    IOT_CERT_ARG=$1
    IOT_CERT_LST=$(aws iot list-targets-for-policy --policy-name lafleet-$IOT_CERT_ARG-policy)

    IOT_CERT_CNT=$(echo "$IOT_CERT_LST" | jq '.targets | length')
    if [ "$IOT_CERT_CNT" = "1" ]; then
        echo "OK thing $IOT_CERT_ARG has only one certificate"
    else
        echo "NOK thing $IOT_CERT_ARG has more or less than one certificate"
    fi

    IOT_CERT_FST=$(echo "$IOT_CERT_LST" | jq '.targets' | tr -d '"[] ')
    IOT_CERT_EXP=arn:aws:iot:$AWS_REGION_VALUE:$AWS_ACCOUNT_ID_VALUE:cert
    IOT_CERT_CHK=$(echo "$IOT_CERT_FST" | grep $IOT_CERT_EXP)
    if [ ! -z "$IOT_CERT_CHK" ]; then
        echo "OK thing $IOT_CERT_ARG has certificate $IOT_CERT_CHK"
    else
        echo "NOK thing $IOT_CERT_ARG certificate does not exist"
    fi
}

S3_OBJECT_STORE_KEYS=$(aws s3api list-objects --bucket $S3_OBJECT_STORE | grep '"Key"' | cut -d ':' -f2 | tr -d '", ')
S3_OBJECT_STORE_FILES_CNT=5
checkIfCertFilesExist(){
    S3_THING_FOLDER=$1
    S3_KEYS_CNT=$(echo "$S3_OBJECT_STORE_KEYS" | grep "certs/$S3_THING_FOLDER" | wc -l)
    if [ "$S3_KEYS_CNT" = "$S3_OBJECT_STORE_FILES_CNT" ]; then
        echo "OK $S3_OBJECT_STORE $S3_THING_FOLDER has all $S3_OBJECT_STORE_FILES_CNT cert files"
    else
        echo "NOK $S3_OBJECT_STORE $S3_THING_FOLDER does not have $S3_OBJECT_STORE_FILES_CNT cert files"
    fi
}

checkIfCertIdsMatch(){
    THING_NAME_ARG=$1

    IOT_CERT_ID=$(aws iot list-targets-for-policy --policy-name lafleet-$THING_NAME_ARG-policy | jq '.targets[0]' | tr -d '"[] ' | cut -d '/' -f2)
    aws s3 cp s3://$S3_OBJECT_STORE/certs/$THING_NAME_ARG/certificate-id.txt $CHK_DIR/certs/$THING_NAME_ARG > /dev/null 2>&1
    S3_CERT_ID=$(cat "$CHK_DIR/certs/$THING_NAME_ARG/certificate-id.txt")

    if [ "$IOT_CERT_ID" = "$S3_CERT_ID" ]; then
        echo "OK $THING_NAME_ARG cert ids match $IOT_CERT_ID"
    else
        echo "NOK $THING_NAME_ARG cert ids do not match $IOT_CERT_ID <> $S3_CERT_ID"
    fi
}

CW_LOGS_GRP_LST=$(aws logs describe-log-groups | grep '"logGroupName"' | cut -d ':' -f2 |  tr -d '", ')
checkIfIotRuleLogGroupExists(){
    THING_NAME_ARG=$1
    LOG_GRP_OK=$PROJECT_NAME/iot/$THING_NAME_ARG-logs
    LOG_GRP_ERR=$PROJECT_NAME/iot/$THING_NAME_ARG-error-logs
    LG_OK_CHK=$(echo "$CW_LOGS_GRP_LST" | grep $LOG_GRP_OK)
    LG_ERR_CHK=$(echo "$CW_LOGS_GRP_LST" | grep $LOG_GRP_ERR)

    if [ ! -z "$LG_OK_CHK" ] && [ ! -z "$LG_ERR_CHK" ]; then
        echo "OK iot rule log groups $LOG_GRP_OK and $LOG_GRP_ERR exist"
    else
        echo "NOK iot rule log groups $LOG_GRP_OK and $LOG_GRP_ERR are missing"
    fi
}

checkIotThing(){
    CIT_TN_ARG=$1

    checkIfThingExists $CIT_TN_ARG
    checkIfPolicyExists $CIT_TN_ARG
    checkIfCertificateExists $CIT_TN_ARG
    checkIfCertFilesExist $CIT_TN_ARG
    checkIfCertIdsMatch $CIT_TN_ARG
    checkIfIotRuleLogGroupExists $CIT_TN_ARG
}

checkIotThing $DEVICE_REPO
checkIotThing $IOT_SERVER_REPO


ENV_CONFIG_FILE=".env.production";

checkConfigFileValues(){
    REPO_ARG=$1
    CFG_ARGS=$2

    aws s3 cp s3://$S3_OBJECT_STORE/config/$REPO_ARG/$ENV_CONFIG_FILE $CHK_DIR/config/$REPO_ARG > /dev/null 2>&1
    CFG_LINES=$(cat "$CHK_DIR/config/$REPO_ARG/$ENV_CONFIG_FILE")

    MISSING_CFG=
    HAS_MISSING=FALSE
    echo "$CFG_ARGS" | tr ' ' '\n' | while read item; do
        CFG_KEY=$(echo "$CFG_LINES" | grep $item | cut -d '=' -f1)
        if [ ! "$CFG_KEY" = "$item" ]; then
            MISSING_CFG=$item
            HAS_MISSING=TRUE
            break
        fi
    done

    if [ "$HAS_MISSING" = "FALSE" ]; then
        echo "OK $REPO_ARG config file has all values"
    else
        echo "NOK $REPO_ARG config file is missing $MISSING_CFG value"
    fi
}

checkIfCodeBuildLogGroupExists(){
    REPO_ARG=$1
    LOG_GRP=$PROJECT_NAME/codebuild/$REPO_ARG
    LG_CHK=$(echo "$CW_LOGS_GRP_LST" | grep $LOG_GRP)

    if [ ! -z "$LG_CHK" ]; then
        echo "OK codebuild log group $LOG_GRP exists"
    else
        echo "NOK codebuild log group $LOG_GRP does not exist"
    fi
}

CC_REPO_LST=$(aws codecommit list-repositories | grep '"repositoryName"' | cut -d ':' -f2 | tr -d '"[], ')
CB_PROJECT_LST=$(aws codebuild list-projects | jq '.projects' | tr -d '"[], ')
CP_PIPELINE_LST=$(aws codepipeline list-pipelines | grep '"name"' | cut -d ':' -f2 | tr -d '", ')
ECR_REPO_LIST=$(aws ecr describe-repositories | grep '"repositoryName"' | cut -d ':' -f2 | tr -d '", ')
checkCiCdHealth(){
    REPO_ARG=$1
    ECR_ARG=$2

    CC_CHK=$(echo "$CC_REPO_LST" | grep $REPO_ARG)
    if [ ! -z "$CC_CHK" ]; then
        echo "OK codecommit $REPO_ARG exists"
    else
        echo "NOK codecommit $REPO_ARG does not exist"
    fi

    CB_CHK=$(echo "$CB_PROJECT_LST" | grep $REPO_ARG)
    if [ ! -z "$CB_CHK" ]; then
        echo "OK codebuild $REPO_ARG exists"
    else
        echo "NOK codebuild $REPO_ARG does not exist"
    fi

    LATEST_BUILD_ID=$(aws codebuild list-builds-for-project --project-name $REPO_ARG | jq ".ids[0]" | tr -d '"')
    LATEST_BUILD_STATUS=$(aws codebuild batch-get-builds --ids $LATEST_BUILD_ID | jq ".builds[0] | .buildStatus" | tr -d '"')
    if [ "$LATEST_BUILD_STATUS" = "SUCCEEDED" ]; then
        echo "OK codebuild $REPO_ARG succeeded"
    else
        echo "NOK codebuild $REPO_ARG failed"
    fi

    CP_CHK=$(echo "$CP_PIPELINE_LST" | grep $REPO_ARG)
    if [ ! -z "$CP_CHK" ]; then
        echo "OK codepipeline $REPO_ARG exists"
    else
        echo "NOK codepipeline $REPO_ARG does not exist"
    fi

    LATEST_PL_STATUS=$(aws codepipeline get-pipeline-state --name $REPO_ARG | jq ".stageStates[] | .latestExecution.status" | tr -d '"')
    HAS_FAILED=$(echo "$LATEST_PL_STATUS" | grep 'Failed')
    HAS_NULL=$(echo "$LATEST_PL_STATUS" | grep 'null')
    if [ ! -z "$HAS_FAILED" ] || [ ! -z "$HAS_NULL" ]; then
        echo "NOK codepipeline $REPO_ARG failed"
    else
        echo "OK codepipeline $REPO_ARG succeeded"
    fi

    if [ ! "$ECR_ARG" = "" ]; then
        ECR_CHK=$(echo "$ECR_REPO_LIST" | grep $ECR_ARG)
        if [ ! -z "$ECR_CHK" ]; then
            echo "OK ecr repo $ECR_ARG exists"

            ECK_IMAGE_LATEST=$(aws ecr list-images --repository-name iot-server | jq '.imageIds[] | select (.imageTag == "latest") | .imageDigest' | grep sha256)
            if [ ! -z "$ECK_IMAGE_LATEST" ]; then
                echo "OK ecr repo $ECR_ARG latest image exists"
            else
                echo "NOK ecr repo $ECR_ARG latest image does not exist"
            fi
        else
            echo "NOK ecr repo $ECR_ARG does not exist"
        fi
    fi
}

checkRepo(){
    CR_REPO_ARG=$1
    CR_ECR_ARG=$2
    CR_CFG_ARGS=$3

    checkConfigFileValues $CR_REPO_ARG $CR_CFG_ARGS
    checkIfCodeBuildLogGroupExists $CR_REPO_ARG
    checkCiCdHealth $CR_REPO_ARG $CR_ECR_ARG
}

checkRepo $DEVICE_REPO $DEVICE_IMAGE_REPO "ENDPOINT STREAMING_LOCATION_TOPIC STREAMID_REQUEST_TOPIC STREAMID_REPLY_TOPIC INTERVAL COUNT CA_FILE CERT_FILE KEY_FILE"
checkRepo $IOT_SERVER_REPO $IOT_SERVER_IMAGE_REPO "ENDPOINT STREAMID_REQUEST_TOPIC STREAMID_REPLY_TOPIC CA_FILE CERT_FILE KEY_FILE"
checkRepo $DEVICE_CONSUMER_REPO $DEVICE_CONSUMER_IMAGE_REPO "REDIS_HOST AWS_REGION SQS_QUEUE_URL"
checkRepo $SHAPE_CONSUMER_REPO $SHAPE_CONSUMER_IMAGE_REPO "REDIS_HOST AWS_REGION SQS_QUEUE_URL"
checkRepo $QUERY_REPO $QUERY_IMAGE_REPO "REDIS_HOST REDIS_PORT"
checkRepo $ANALYTICS_REPO $ANALYTICS_IMAGE_REPO "REDIS_HOST REDIS_PORT"
checkRepo $REACT_REPO "" "CDN_DIST_ID S3_WEB_BUCKET REACT_CDN SHAPES_CDN MAPBOX_TOKEN MAPBOX_STYLE_LIGHT MAPBOX_STYLE_BASIC"


checkCloudFrontExists(){
    CDN_ARG=$1
    LBL_ARG=$2

    if [ ! -z "$DN_SHAPE" ]; then
        echo "OK cloudfront distribution $CDN_ARG for $LBL_ARG exists"
    else
        echo "NOK cloudfront distribution $CDN_ARG for $LBL_ARG does not exist"
    fi
}

DN_SHAPE=$(aws cloudfront list-distributions | jq '.DistributionList.Items[] | select(.Comment | contains("Shape")) | .DomainName' | tr -d '"')
checkCloudFrontExists $DN_SHAPE Shape
DN_REACT=$(aws cloudfront list-distributions | jq '.DistributionList.Items[] | select(.Comment | contains("React")) | .DomainName' | tr -d '"')
checkCloudFrontExists $DN_REACT React

curl -s -L $DN_REACT > $CHK_DIR/web/$REACT_REPO/index.html
HAS_ERROR=$(cat $CHK_DIR/web/$REACT_REPO/index.html | grep 'Error')
if [ ! -z "$HAS_ERROR" ]; then
    echo "NOK react page $DN_REACT has error"
else
    echo "OK react page $DN_REACT is returned"
fi


API_GW=$(aws apigatewayv2 get-apis | jq '.Items[] | select (.Name == "ShapesHttpApi") | .ApiEndpoint' | tr -d '"')
if [ ! -z "$API_GW" ]; then
    echo "OK api gateway ShapesHttpApi exists"
else
    echo "NOK api gateway ShapesHttpApi does not exist"
fi

echo "FINISHED!"

