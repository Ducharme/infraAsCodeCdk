#!/bin/sh

#################### SHAPES ####################

# Upload shape (LIMIT)
# TODO: Implement with selenium or curl?
echo "***** DO THIS MANUALLY - Upload shape (LIMIT) ****"

# Check s3 for both the shape json and the latest zone json
S3_DST_DIR=$CHK_DIR/s3/$S3_SHAPE_REPO
mkdir -p "$S3_DST_DIR/latest"
S3_SHAPE_KEYS=$(aws s3api list-objects-v2 --bucket $S3_SHAPE_REPO | jq '.Contents[] | .Key' | tr -d '"')
echo "$S3_SHAPE_KEYS" | tr ' ' '\n' | while read item; do
    S3_COPY=$(aws s3api get-object --bucket $S3_SHAPE_REPO --key $item "$S3_DST_DIR/$item" | jq '.ETag' | tr -d '" \t\n\r\\')
    #echo "S3_COPY $S3_COPY"
done
# TODO: Works only if there is one latest file on s3
LATEST_FILE=$(echo "$S3_SHAPE_KEYS" | grep latest)
if [ ! -z "$LATEST_FILE" ]; then
    echo "OK s3 latest file $LATEST_FILE exists"
else
    echo "NOK s3 latest file does not exist"
fi

SHAPE_ID=$(cat "$S3_DST_DIR/$LATEST_FILE" | jq '.active[0]' | tr -d '"')
if [ ! -z "$SHAPE_ID" ]; then
    echo "OK s3 shapeId $SHAPE_ID exists"
else
    echo "NOK s3 shapeId does not exist"
fi

S3_SHAPE=$(cat $S3_DST_DIR/$SHAPE_ID)
S3_SHAPE_ID=$(echo "$S3_SHAPE" | jq '.shapeId' | tr -d '"')
SHAPE_TYPE=$(echo "$S3_SHAPE" | jq '.type' | tr -d '"')
if [ "$SHAPE_ID" = "$S3_SHAPE_ID" ]; then
    echo "OK s3 shapeId matches the latest zone file for $SHAPE_TYPE"
else
    echo "OK s3 shapeId does not match the latest zone file for $SHAPE_TYPE"
fi


# Check sqsShapeConsumer logs
POD_NAME=$(kubectl get po | grep lafleet-shape-consumers | cut -d ' ' -f1)
LOG_DIR=$CHK_DIR/logs/$POD_NAMEPOD_NAME=$(kubectl get po | grep lafleet-shape-consumers | cut -d ' ' -f1)
LOG_DIR=$CHK_DIR/logs/$POD_NAME
mkdir -p "$LOG_DIR"
kubectl logs $POD_NAME > "$LOG_DIR/pod.log"
LOG_CACHE=$(cat "$LOG_DIR/pod.log")
REDIS_CONNECTED=$(echo "$LOG_CACHE" | grep "Redis client ready")
mkdir -p "$LOG_DIR"
kubectl logs $POD_NAME > "$LOG_DIR/pod.log"
LOG_CACHE=$(cat "$LOG_DIR/pod.log")
REDIS_CONNECTED=$(echo "$LOG_CACHE" | grep "Redis client ready")
# SHAPE_UPDATED=$(echo "$LOG_CACHE" | grep "Shape files updated")
# S3_GET_OBJ=$(echo "$LOG_CACHE" | grep "List of s3")
# REDIS_GET_LST=$(echo "$LOG_CACHE" | grep "Getting list of")
# REDIS_LST_OF=$(echo "$LOG_CACHE" | grep "List of redis")

# echo ""
# echo "Logs from the pod:"
echo "REDIS_CONNECTED -> $REDIS_CONNECTED"
# echo "SHAPE_UPDATED -> $SHAPE_UPDATED"
# echo "S3_GET_OBJ -> $S3_GET_OBJ"
# echo "REDIS_GET_LST -> $REDIS_GET_LST"
# echo "REDIS_LST_OF -> $REDIS_LST_OF"

REDIS_FAILED=$(echo "$LOG_CACHE" | grep "Failed\|failed")
if [ ! -z "$REDIS_FAILED" ]; then
    echo "NOK pod encountered failures in logs, see $LOG_DIR/pod.log for details"
else
    echo "OK pod succeeded according to logs, see $LOG_DIR/pod.log for details"
fi

REDIS_POD_NAME=$(kubectl get pods -o json | jq '.items[] | select(.spec.containers[0].name == "redisearch") | .metadata.name' | tr -d '"')
REDIS_SHAPE_KEYS=$(kubectl exec $POD_NAME -- redis-cli KEYS SHAPELOC*)
REDIS_SHAPE_CHK=$(echo "$REDIS_SHAPE_KEYS" | grep $SHAPE_ID)
if [ ! -z "$REDIS_SHAPE_CHK" ]; then
    echo "OK shapeId $REDIS_SHAPE_CHK exists in redis"
else
    echo "NOK shapeId $REDIS_SHAPE_CHK does not exist in redis"
fi
REDIS_SHAPE_JSON=$(kubectl exec $POD_NAME -- redis-cli JSON.GET SHAPELOC:$SHAPE_ID)
REDIS_SHAPE_ID=$(echo "$REDIS_SHAPE_JSON" | jq '.shapeId' | tr -d '"')
if [ "$SHAPE_ID" = "$REDIS_SHAPE_ID" ]; then
    echo "OK redis shapeId matches the one from s3"
else
    echo "NOK redis shapeId does not match the one from s3"
fi

# Check query to find it

ENDPOINT=https://$DN_REACT/query/h3/search/shapes/list
H3_SEARCH_SHAPES_LST=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{ \"shapeType\": \"$SHAPE_TYPE\", \"status\": \"ACTIVE\", \"h3indices\": [ \"802bfffffffffff\" ]}" $ENDPOINT)
SHAPE_ENTRY=$(echo "$H3_SEARCH_SHAPES_LST" | jq '.[0].shape')
if [ ! -z "$SHAPE_ENTRY" ]; then
    echo "OK shape exists on $ENDPOINT"
else
    echo "NOK shape does not exist on $ENDPOINT"
fi

ENDPOINT=https://$DN_REACT/query/h3/fetch/shapes/polygon
H3_FETCH_SHAPES_POL=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{ \"shapeIds\": [ \"$SHAPE_ID\" ] }" $ENDPOINT)
SHAPE_POLYGON=$(echo "$H3_FETCH_SHAPES_POL" | jq '.[0].polygon')
if [ ! -z "$SHAPE_POLYGON" ]; then
    echo "OK polygon exists on $ENDPOINT"
else
    echo "NOK polygon does not exist on $ENDPOINT"
fi

ENDPOINT=https://$DN_REACT/query/h3/fetch/shapes/h3polygon
H3_FETCH_SHAPES_POL=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{ \"shapeIds\": [ \"$SHAPE_ID\" ] }" $ENDPOINT)
SHAPE_POLYGON=$(echo "$H3_FETCH_SHAPES_POL" | jq '.[0].h3polygon')
if [ ! -z "$SHAPE_POLYGON" ]; then
    echo "OK h3polygon exists on $ENDPOINT"
else
    echo "NOK h3polygon does not exist on $ENDPOINT"
fi

# Check reactFrontend to see it