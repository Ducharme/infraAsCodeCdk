#!/bin/sh

TMP_DIR=./tmp/github
GIT_ACC=https://github.com/Ducharme
BRANCH_NAME=main
GIT_PATH=archive/refs/heads


if [ ! -d "$TMP_DIR" ]; then
  mkdir -p $TMP_DIR
fi

downloadRepo(){
  REPO_NAME=$1
  curl -L $GIT_ACC/$REPO_NAME/$GIT_PATH/$BRANCH_NAME.zip --output $TMP_DIR/$REPO_NAME-$BRANCH_NAME.zip
  unzip $TMP_DIR/$REPO_NAME-$BRANCH_NAME.zip -d $TMP_DIR
}


downloadRepo $DEVICE_REPO
downloadRepo $DEVICE_CONSUMER_REPO
downloadRepo $SHAPE_CONSUMER_REPO
downloadRepo $REACT_REPO
downloadRepo $QUERY_REPO
downloadRepo $ANALYTICS_REPO
