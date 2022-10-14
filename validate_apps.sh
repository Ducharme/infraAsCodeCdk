#!/bin/sh

. ./set_env-vars.sh

CHK_DIR=./tmp/check
mkdir -p "$CHK_DIR"
mkdir -p "$CHK_DIR/logs/"

# API gateway upload-page (form)
API_GW_DNS=$(aws apigatewayv2 get-apis | jq '.Items[] | select (.Name == "ShapesHttpApi") | .ApiEndpoint' | tr -d '"')
UPLOAD_HTM=$CHK_DIR/web/$REACT_REPO/upload-shape.html
curl -s -L $API_GW_DNS/upload-shape > $UPLOAD_HTM
NOT_FOUND=$(cat $UPLOAD_HTM | grep 'Not Found')
if [ ! -z "$NOT_FOUND" ]; then
    echo "NOK page upload-shape not found"
else
    echo "OK page upload-shape was found"
fi

# CloudFront
DN_REACT=$(aws cloudfront list-distributions | jq '.DistributionList.Items[] | select(.Comment | contains("React")) | .DomainName' | tr -d '"')

# Services health check
QUERY_HEALTH=$(curl -s -X GET https://$DN_REACT/query/health)
PERF_HEALTH=$(curl -s -X GET https://$DN_REACT/analytics/health)
echo "redisearchQueryClient health -> $QUERY_HEALTH"
echo "redisPerformanceAnalyticsPy health -> $PERF_HEALTH"


# Upload shape (LIMIT)

# TODO: Implement with selenium or curl?
echo "***** DO THIS MANUALLY ****"

# Check s3 for both the shape json and the latest zone json
S3_DST_DIR=$CHK_DIR/s3/$S3_SHAPE_REPO
mkdir -p "$S3_DST_DIR/latest"
S3_SHAPE_KEYS=$(aws s3api list-objects-v2 --bucket $S3_SHAPE_REPO | jq '.Contents[] | .Key' | tr -d '"')
echo "$S3_SHAPE_KEYS" | tr ' ' '\n' | while read item; do
    S3_COPY=$(aws s3api get-object --bucket $S3_SHAPE_REPO --key $item "$S3_DST_DIR/$item" | jq '.ETag' | tr -d '" \t\n\r\\')
    echo "S3_COPY $S3_COPY"
done
# TODO: Works only if there is one latest file on s3
LATEST_FILE=$(echo "$S3_SHAPE_KEYS" | grep latest)
echo LATEST_FILE $LATEST_FILE
SHAPE_ID=$(cat "$S3_DST_DIR/$LATEST_FILE" | jq '.active[0]' | tr -d '"')
echo SHAPE_ID $SHAPE_ID
S3_SHAPE=$(cat $S3_DST_DIR/$SHAPE_ID)
S3_SHAPE_ID=$(echo "$S3_SHAPE" | jq '.shapeId' | tr -d '"')
echo "S3_SHAPE_ID -> $S3_SHAPE_ID"
SHAPE_TYPE=$(echo "$S3_SHAPE" | jq '.type' | tr -d '"')
echo "SHAPE_TYPE -> $SHAPE_TYPE"

# Check sqsShapeConsumer logs
POD_NAME=$(kubectl get po | grep lafleet-shape-consumers | cut -d ' ' -f1)
LOG_DIR=$CHK_DIR/logs/$POD_NAME
mkdir -p "$LOG_DIR"
kubectl logs $POD_NAME > "$LOG_DIR/pod.log"
LOG_CACHE=$(cat "$LOG_DIR/pod.log")
REDIS_CONNECTED=$(echo "$LOG_CACHE" | grep "Redis client ready")
SHAPE_UPDATED=$(echo "$LOG_CACHE" | grep "Shape files updated")
S3_GET_OBJ=$(echo "$LOG_CACHE" | grep "List of s3")
REDIS_GET_LST=$(echo "$LOG_CACHE" | grep "Getting list of")
REDIS_LST_OF=$(echo "$LOG_CACHE" | grep "List of redis")
REDIS_FAILED=$(echo "$LOG_CACHE" | grep "failed")

echo ""
echo "Logs from the pod:"
echo "REDIS_CONNECTED -> $REDIS_CONNECTED"
echo "SHAPE_UPDATED -> $SHAPE_UPDATED"
echo "S3_GET_OBJ -> $S3_GET_OBJ"
echo "REDIS_GET_LST -> $REDIS_GET_LST"
echo "REDIS_LST_OF -> $REDIS_LST_OF"
echo "REDIS_FAILED -> $REDIS_FAILED"

# Check redis json entry
POD_NAME=$(kubectl get pods -o json | jq '.items[] | select(.spec.containers[0].name == "redisearch") | .metadata.name' | tr -d '"')
LOG_DIR=$CHK_DIR/logs/$POD_NAME
mkdir -p "$LOG_DIR"
kubectl exec $POD_NAME -- redis-cli FT._LIST > "$LOG_DIR/ft_list.txt"
LOG_CACHE=$(cat "$LOG_DIR/ft_list.txt")
echo ""
echo "Redis index are:\n$LOG_CACHE"
echo ""

REDIS_SHAPE_KEYS=$(kubectl exec $POD_NAME -- redis-cli KEYS SHAPELOC*)
echo "REDIS_SHAPE_KEYS $REDIS_SHAPE_KEYS"
REDIS_SHAPE_CHK=$(echo "$REDIS_SHAPE_KEYS" | grep $SHAPE_ID)
if [ ! -z "$REDIS_SHAPE_CHK" ]; then
    echo "OK shapeId $REDIS_SHAPE_CHK exists in redis"
else
    echo "NOK shapeId $REDIS_SHAPE_CHK does not exist in redis"
fi
REDIS_SHAPE_JSON=$(kubectl exec $POD_NAME -- redis-cli JSON.GET SHAPELOC:$SHAPE_ID)
REDIS_SHAPE_ID=$(echo "$REDIS_SHAPE_JSON" | jq '.shapeId' | tr -d '"')
echo "REDIS_SHAPE_ID -> $REDIS_SHAPE_ID"
# Check query to find it
ALL_H0_L0="80a5fffffffffff","8099fffffffffff","8075fffffffffff","8039fffffffffff","801bfffffffffff","8003fffffffffff","80d5fffffffffff","80b1fffffffffff","8027fffffffffff","8045fffffffffff",
ALL_H0_L1="80cffffffffffff","80c3fffffffffff","8081fffffffffff","8057fffffffffff","800ffffffffffff","805dfffffffffff","80b7fffffffffff","8051fffffffffff","806ffffffffffff","8093fffffffffff",
ALL_H0_L2="80ebfffffffffff","80dffffffffffff","80c1fffffffffff","8055fffffffffff","8019fffffffffff","8007fffffffffff","800dfffffffffff","80b5fffffffffff","80d3fffffffffff","80c7fffffffffff",
ALL_H0_L3="80a9fffffffffff","802bfffffffffff","8013fffffffffff","8037fffffffffff","8079fffffffffff","808bfffffffffff","8091fffffffffff","8067fffffffffff","8049fffffffffff","806dfffffffffff",
ALL_H0_L4="80e3fffffffffff","80e9fffffffffff","80effffffffffff","80ddfffffffffff","80c5fffffffffff","807dfffffffffff","8035fffffffffff","8023fffffffffff","8047fffffffffff","8071fffffffffff",
ALL_H0_L5="809bfffffffffff","8089fffffffffff","803bfffffffffff","801dfffffffffff","80a1fffffffffff","80b3fffffffffff","805ffffffffffff","804dfffffffffff","8029fffffffffff","808ffffffffffff",
ALL_H0_L6="80f3fffffffffff","80dbfffffffffff","809ffffffffffff","8033fffffffffff","8015fffffffffff","8009fffffffffff","803ffffffffffff","80e7fffffffffff","80e1fffffffffff","80c9fffffffffff",
ALL_H0_L7="804bfffffffffff","8021fffffffffff","802dfffffffffff","807bfffffffffff","80bdfffffffffff","8069fffffffffff","8063fffffffffff","80abfffffffffff","808dfffffffffff","8087fffffffffff",
ALL_H0_L8="80f1fffffffffff","80d9fffffffffff","80bbfffffffffff","807ffffffffffff","805bfffffffffff","804ffffffffffff","8001fffffffffff","801ffffffffffff","80e5fffffffffff","809dfffffffffff",
ALL_H0_L9="8073fffffffffff","8031fffffffffff","8025fffffffffff","8097fffffffffff","80cdfffffffffff","80affffffffffff","803dfffffffffff","8043fffffffffff","80a3fffffffffff","8085fffffffffff",
ALL_H0_L10="8061fffffffffff","80bffffffffffff","8077fffffffffff","8017fffffffffff","802ffffffffffff","8005fffffffffff","800bfffffffffff","8011fffffffffff","8059fffffffffff","8083fffffffffff",
ALL_H0_L11="806bfffffffffff","80adfffffffffff","80d1fffffffffff","80b9fffffffffff","8053fffffffffff","80d7fffffffffff","80cbfffffffffff","8095fffffffffff","80a7fffffffffff","8041fffffffffff",
ALL_H0_L12="8065fffffffffff","80edfffffffffff"
ALL_H0=$ALL_H0_L0$ALL_H0_L1$ALL_H0_L2$ALL_H0_L3$ALL_H0_L4$ALL_H0_L5$ALL_H0_L6$ALL_H0_L7$ALL_H0_L8$ALL_H0_L9$ALL_H0_L10$ALL_H0_L11$ALL_H0_L12

echo ""
echo ""
ENDPOINT=https://$DN_REACT/query/h3/search/shapes/list
H3_SEARCH_SHAPES_LST=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{ \"shapeType\": \"$SHAPE_TYPE\", \"status\": \"ACTIVE\", \"h3indices\": [ \"802bfffffffffff\" ]}" $ENDPOINT)
SHAPE_ENTRY=$(echo "$H3_SEARCH_SHAPES_LST" | jq '.[0].shape')
if [ ! -z "$SHAPE_ENTRY" ]; then
    echo "OK shape exists on $ENDPOINT"
else
    echo "NOK shape does not exist on $ENDPOINT"
fi
echo ""
echo ""
ENDPOINT=https://$DN_REACT/query/h3/fetch/shapes/polygon
H3_FETCH_SHAPES_POL=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{ \"shapeIds\": [ \"$SHAPE_ID\" ] }" $ENDPOINT)
SHAPE_POLYGON=$(echo "$H3_FETCH_SHAPES_POL" | jq '.[0].polygon')
if [ ! -z "$SHAPE_POLYGON" ]; then
    echo "OK polygon exists on $ENDPOINT"
else
    echo "NOK polygon does not exist on $ENDPOINT"
fi

# Check react to see it


# Start mock device
# Check IoT server logs to see reply streamId
# Check mock device logs to see publish
# Check sqsDevice logs to see sqs consume and redis publish
# 

echo ""
echo ""
ENDPOINT=https://$DN_REACT/query/radius/search/devices/list
RADIUS_SEARCH_DEVICES_LST=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{ "longitude": -73.561668, "latitude": 45.508888, "distance": 5000, "distanceUnit": "km" }' $ENDPOINT)
echo "RADIUS_SEARCH_DEVICES_LST -> $RADIUS_SEARCH_DEVICES_LST on $ENDPOINT"

echo ""
echo "FINISHED!"
