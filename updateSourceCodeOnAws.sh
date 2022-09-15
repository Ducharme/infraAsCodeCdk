#!/bin/sh

. ./set_env-vars.sh

. ./downloadRepos.sh || { echo "Downloading github repositories to $GITHUB_DIR failed, exiting" ; exit 1; }

### Setup GitHub repos

GIT_ACC=https://git-codecommit.$AWS_REGION_VALUE.amazonaws.com
GIT_PATH=v1/repos
BRANCH_NAME=main


if [ ! -d "$CODECOMMIT_DIR" ]; then
  mkdir -p $CODECOMMIT_DIR
fi

downloadRepo(){
  REPO_NAME=$1

  CC_REPO_DIR=$CODECOMMIT_DIR/$REPO_NAME
  echo " === $CC_REPO_DIR ===" 
  if [ -d "$CC_REPO_DIR" ]; then
    echo rm -rf "$CC_REPO_DIR"
    rm -rf "$CC_REPO_DIR"
  fi

  git clone $GIT_ACC/$GIT_PATH/$REPO_NAME $CC_REPO_DIR

  cd $CC_REPO_DIR
  ls -a  | grep -xv ".git\|.\|.." | xargs rm -r
  cd ..
  cd ..
  cd ..

  cp -r -a "$GITHUB_DIR/$REPO_NAME-$BRANCH_NAME/." "$CC_REPO_DIR"

  cd $CC_REPO_DIR
  git add .
  git commit -m "Sync github to codecommit"
  git push
  cd ..
  cd ..
  cd ..
}

downloadRepo $DEVICE_REPO
downloadRepo $DEVICE_CONSUMER_REPO
downloadRepo $SHAPE_CONSUMER_REPO
downloadRepo $REACT_REPO
downloadRepo $QUERY_REPO
downloadRepo $ANALYTICS_REPO
