#!/bin/sh

REPO_NAMES=$(aws ecr describe-repositories | grep repositoryName)

deleteImagesFromRepo(){
  REPO_NAME=$1

  echo "REPO_NAME=$REPO_NAME";
  REPO_MATCH=$(echo "$REPO_NAMES" | grep $REPO_NAME)
  if [ ! -z "$REPO_MATCH" ]; then
    IMAGE_DIGESTS=$(aws ecr list-images --repository-name $REPO_NAME | jq '.imageIds[].imageDigest')
    echo "$IMAGE_DIGESTS" | tr ' ' '\n' | while read item1; do
        IMAGE_DIGEST="$item1"
        if [ ! -z "$IMAGE_DIGEST" ]; then
          echo "IMAGE_DIGEST=$IMAGE_DIGEST";
          aws ecr batch-delete-image --repository-name $REPO_NAME --image-ids imageDigest=$IMAGE_DIGEST 1>/dev/null
        fi
    done
  fi
}

deleteImagesFromRepo redisearch-performance-analytics-py
deleteImagesFromRepo redisearch-query-client
deleteImagesFromRepo sqsdeviceconsumer-toredisearch
deleteImagesFromRepo sqsshapeconsumer-toredisearch
deleteImagesFromRepo iot-server
deleteImagesFromRepo mock-iot-gps-device-awssdkv2
