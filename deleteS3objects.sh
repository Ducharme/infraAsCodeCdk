#!/bin/sh

S3_BUCKETS_DEL=$(aws s3api list-buckets | grep '"Name"')

deleteObjectsFromBucket(){
    S3_BUCKET_ARG=$1
    S3_BUCKET_DEL=$(echo "$S3_BUCKETS_DEL" | grep $S3_BUCKET_ARG)
    if [ ! -z "$S3_BUCKET_DEL" ]; then
        echo "Deleting files from S3 bucket $S3_BUCKET_ARG"
        CMD_ROOT=$(aws s3api list-object-versions --bucket $S3_BUCKET_ARG)
        S3_KEYS=$(aws s3api list-objects --bucket $S3_BUCKET_ARG | grep '"Key"')
        if [ ! -z "$S3_KEYS" ]; then
            HAS_MARKERS=$(echo "$CMD_ROOT" | grep "DeleteMarkers")
            if [ ! -z "$HAS_MARKERS" ]; then
                aws s3api delete-objects --bucket $S3_BUCKET_ARG --delete "$(echo "$CMD_ROOT" | jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId:.VersionId}]}')" 1>/dev/null
            fi
            HAS_VERSIONS=$(echo "$CMD_ROOT" | grep "Versions")
            if [ ! -z "$HAS_VERSIONS" ]; then
                aws s3api delete-objects --bucket $S3_BUCKET_ARG --delete "$(echo "$CMD_ROOT" | jq '{Objects: [.Versions[] | {Key:.Key, VersionId:.VersionId}]}')" 1>/dev/null
            fi
        fi
    fi
}

deleteObjectsFromBucket $S3_REACT_WEB
deleteObjectsFromBucket $S3_OBJECT_STORE
deleteObjectsFromBucket $S3_CODEBUILD_ARTIFACTS
deleteObjectsFromBucket $S3_CODEPIPELINE_ARTIFACTS
deleteObjectsFromBucket $S3_SHAPE_REPO
