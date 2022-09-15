#!/bin/sh

GIT_ACC=https://github.com/Ducharme
GIT_PATH=archive/refs/heads
BRANCH_NAME=main


if [ ! -d "$GITHUB_DIR" ]; then
  mkdir -p $GITHUB_DIR
fi

downloadRepo(){
  REPO_NAME=$1

  GITHUB_REPO_DIR=$GITHUB_DIR/$REPO_NAME-$BRANCH_NAME
  if [ -d "$GITHUB_REPO_DIR" ]; then
    rm -r "$GITHUB_REPO_DIR"
  fi
  
  curl -L $GIT_ACC/$REPO_NAME/$GIT_PATH/$BRANCH_NAME.zip --output $GITHUB_REPO_DIR.zip
  unzip $GITHUB_REPO_DIR.zip -d $GITHUB_DIR
}


downloadRepo $DEVICE_REPO
downloadRepo $DEVICE_CONSUMER_REPO
downloadRepo $SHAPE_CONSUMER_REPO
downloadRepo $REACT_REPO
downloadRepo $QUERY_REPO
downloadRepo $ANALYTICS_REPO
