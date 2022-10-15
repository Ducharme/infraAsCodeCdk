#!/bin/sh

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
if [ "$QUERY_HEALTH" = "OK" ]; then
    echo "OK redisearchQueryClient https://$DN_REACT/query/health"
else
    echo "NOK redisearchQueryClient https://$DN_REACT/query/health"
fi

PERF_HEALTH=$(curl -s -X GET https://$DN_REACT/analytics/health)
if [ "$PERF_HEALTH" = "OK" ]; then
    echo "OK redisPerformanceAnalyticsPy https://$DN_REACT/analytics/health"
else
    echo "NOK redisPerformanceAnalyticsPy https://$DN_REACT/analytics/health"
fi

# Check redis json entry
REDIS_POD_NAME=$(kubectl get pods -o json | jq '.items[] | select(.spec.containers[0].name == "redisearch") | .metadata.name' | tr -d '"')
FT_IDX_LST=$(kubectl exec $REDIS_POD_NAME -- redis-cli FT._LIST)
FT_IDX_CHK1=$(echo $FT_IDX_LST | grep "shape-loc-match-idx")
FT_IDX_CHK2=$(echo $FT_IDX_LST | grep "shape-loc-filter-idx")
FT_IDX_CHK3=$(echo $FT_IDX_LST | grep "topic-h3-idx")
FT_IDX_CHK4=$(echo $FT_IDX_LST | grep "shape-type-idx")
FT_IDX_CHK5=$(echo $FT_IDX_LST | grep "topic-lnglat-idx")
if [ ! -z "$FT_IDX_CHK1" ] && [ ! -z "$FT_IDX_CHK2" ] && [ ! -z "$FT_IDX_CHK3" ] && [ ! -z "$FT_IDX_CHK4" ] && [ ! -z "$FT_IDX_CHK5" ]; then
    echo "OK all redis index exist"
else
    echo "NOK some redis index are missing"
fi
