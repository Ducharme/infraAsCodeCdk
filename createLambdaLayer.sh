#!/bin/sh

LIB_DIR=./lib/lambda-layers
TMP_DIR=./tmp/lambda-layers
PKG_FILE=package.json
LCK_FILE=package-lock.json
ZIP_FILE=aws-sdk-client-layer.zip

if [ ! -d "$TMP_DIR" ]; then
  mkdir -p $TMP_DIR
else
  rm -rfv $TMP_DIR/nodejs/
  rm -rfv $TMP_DIR/node_modules/
  rm $TMP_DIR/$ZIP_FILE
fi

cp -f $LIB_DIR/$PKG_FILE $TMP_DIR
npm install --prefix $TMP_DIR
mkdir $TMP_DIR/nodejs
mv $TMP_DIR/node_modules/ $TMP_DIR/nodejs/
cp -f $TMP_DIR/$LCK_FILE $LIB_DIR/$LCK_FILE

cd $TMP_DIR
zip -y -r $ZIP_FILE nodejs
cd ..
cd ..
