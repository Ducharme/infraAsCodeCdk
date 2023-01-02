#!/bin/sh

LIB_DIR_LAMBDA=./lib/lambda-layers
TMP_DIR_LAMBDA=./tmp/lambda-layers
PKG_FILE=package.json
LCK_FILE=package-lock.json
ZIP_FILE=aws-sdk-client-layer.zip

if [ ! -d "$TMP_DIR_LAMBDA" ]; then
  mkdir -p $TMP_DIR_LAMBDA
else
  rm -rfv $TMP_DIR_LAMBDA/nodejs/
  rm -rfv $TMP_DIR_LAMBDA/node_modules/
  rm $TMP_DIR_LAMBDA/$ZIP_FILE
fi

cp -f $LIB_DIR_LAMBDA/$PKG_FILE $TMP_DIR_LAMBDA
npm install --prefix $TMP_DIR_LAMBDA
mkdir $TMP_DIR_LAMBDA/nodejs
mv $TMP_DIR_LAMBDA/node_modules/ $TMP_DIR_LAMBDA/nodejs/
cp -f $TMP_DIR_LAMBDA/$LCK_FILE $LIB_DIR_LAMBDA/$LCK_FILE

cd $TMP_DIR_LAMBDA
zip -y -r $ZIP_FILE nodejs
cd ..
cd ..
