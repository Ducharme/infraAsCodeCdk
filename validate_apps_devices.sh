#!/bin/sh

#################### DEVICES ####################

ALL_H0_L0='"80a5fffffffffff","8099fffffffffff","8075fffffffffff","8039fffffffffff","801bfffffffffff","8003fffffffffff","80d5fffffffffff","80b1fffffffffff","8027fffffffffff","8045fffffffffff",'
ALL_H0_L1='"80cffffffffffff","80c3fffffffffff","8081fffffffffff","8057fffffffffff","800ffffffffffff","805dfffffffffff","80b7fffffffffff","8051fffffffffff","806ffffffffffff","8093fffffffffff",'
ALL_H0_L2='"80ebfffffffffff","80dffffffffffff","80c1fffffffffff","8055fffffffffff","8019fffffffffff","8007fffffffffff","800dfffffffffff","80b5fffffffffff","80d3fffffffffff","80c7fffffffffff",'
ALL_H0_L3='"80a9fffffffffff","802bfffffffffff","8013fffffffffff","8037fffffffffff","8079fffffffffff","808bfffffffffff","8091fffffffffff","8067fffffffffff","8049fffffffffff","806dfffffffffff",'
ALL_H0_L4='"80e3fffffffffff","80e9fffffffffff","80effffffffffff","80ddfffffffffff","80c5fffffffffff","807dfffffffffff","8035fffffffffff","8023fffffffffff","8047fffffffffff","8071fffffffffff",'
ALL_H0_L5='"809bfffffffffff","8089fffffffffff","803bfffffffffff","801dfffffffffff","80a1fffffffffff","80b3fffffffffff","805ffffffffffff","804dfffffffffff","8029fffffffffff","808ffffffffffff",'
ALL_H0_L6='"80f3fffffffffff","80dbfffffffffff","809ffffffffffff","8033fffffffffff","8015fffffffffff","8009fffffffffff","803ffffffffffff","80e7fffffffffff","80e1fffffffffff","80c9fffffffffff",'
ALL_H0_L7='"804bfffffffffff","8021fffffffffff","802dfffffffffff","807bfffffffffff","80bdfffffffffff","8069fffffffffff","8063fffffffffff","80abfffffffffff","808dfffffffffff","8087fffffffffff",'
ALL_H0_L8='"80f1fffffffffff","80d9fffffffffff","80bbfffffffffff","807ffffffffffff","805bfffffffffff","804ffffffffffff","8001fffffffffff","801ffffffffffff","80e5fffffffffff","809dfffffffffff",'
ALL_H0_L9='"8073fffffffffff","8031fffffffffff","8025fffffffffff","8097fffffffffff","80cdfffffffffff","80affffffffffff","803dfffffffffff","8043fffffffffff","80a3fffffffffff","8085fffffffffff",'
ALL_H0_L10='"8061fffffffffff","80bffffffffffff","8077fffffffffff","8017fffffffffff","802ffffffffffff","8005fffffffffff","800bfffffffffff","8011fffffffffff","8059fffffffffff","8083fffffffffff",'
ALL_H0_L11='"806bfffffffffff","80adfffffffffff","80d1fffffffffff","80b9fffffffffff","8053fffffffffff","80d7fffffffffff","80cbfffffffffff","8095fffffffffff","80a7fffffffffff","8041fffffffffff",'
ALL_H0_L12='"8065fffffffffff","80edfffffffffff"'
ALL_H0=$ALL_H0_L0$ALL_H0_L1$ALL_H0_L2$ALL_H0_L3$ALL_H0_L4$ALL_H0_L5$ALL_H0_L6$ALL_H0_L7$ALL_H0_L8$ALL_H0_L9$ALL_H0_L10$ALL_H0_L11$ALL_H0_L12

# Start mock device (done by default via script)

# Check IoT server logs to see reply streamId

POD_NAME=$(kubectl get po | grep lafleet-iot-server | cut -d ' ' -f1)
LOG_DIR=$CHK_DIR/logs/$POD_NAME
mkdir -p "$LOG_DIR"
kubectl logs $POD_NAME > "$LOG_DIR/pod.log"
LOG_CACHE=$(cat "$LOG_DIR/pod.log")
IOT_SUB_CNT=$(echo "$LOG_CACHE" | grep "Subscribing returned" | wc -l)
IOT_RCV_CNT=$(echo "$LOG_CACHE" | grep "Message received on topic" | wc -l)
IOT_PUB_ED_CNT=$(echo "$LOG_CACHE" | grep "Published to" | wc -l)
if [ "$IOT_SUB_CNT" = "1" ] && [ "$IOT_RCV_CNT" = "2" ] && [ "$IOT_PUB_ED_CNT" = "2" ]; then
    echo "OK pod $POD_NAME succeeded according to logs, see $LOG_DIR/pod.log for details"
else
    echo "NOK pod $POD_NAME did not succeed according to logs, see $LOG_DIR/pod.log for details"
fi

IOT_CLIENT_ERR=$(echo "$LOG_CACHE" | grep "Client was interrupted")
if [ ! -z "$IOT_CLIENT_ERR" ]; then
    echo "NOK pod $POD_NAME was interrupted according in logs, see $LOG_DIR/pod.log for details"
else
    echo "OK pod $POD_NAME was interrupted according to logs, see $LOG_DIR/pod.log for details"
fi

SERVER_FAILED=$(echo "$LOG_CACHE" | grep "Failed\|failed\|Error\|error" | grep -v "error_code")
if [ ! -z "$REDIS_FAILED" ]; then
    echo "NOK pod $POD_NAME encountered failures in logs, see $LOG_DIR/pod.log for details"
else
    echo "OK pod $POD_NAME did not encounter failure in logs, see $LOG_DIR/pod.log for details"
fi


# Check mock device logs to see publish

POD_NAMES=$(kubectl get po | grep lafleet-devices-slow | cut -d ' ' -f1)

echo "$POD_NAMES" | tr ' ' '\n' | while read POD_NAME; do
    LOG_DIR=$CHK_DIR/logs/$POD_NAME
    mkdir -p "$LOG_DIR"
    kubectl logs $POD_NAME > "$LOG_DIR/pod.log"
    LOG_CACHE=$(cat "$LOG_DIR/pod.log")
    DEV_VAL_CNT=$(echo "$LOG_CACHE" | grep "Starting based on values from")
    DEV_EP_CNT=$(echo "$LOG_CACHE" | grep "Values endpoint")
    DEV_ID_CNT=$(echo "$LOG_CACHE" | grep "Values clientId")
    if [ ! -z "$DEV_VAL_CNT" ] && [ ! -z "$DEV_EP_CNT" ] && [ ! -z "$DEV_ID_CNT" ]; then
        echo "OK pod $POD_NAME succeeded according to startup logs, see $LOG_DIR/pod.log for details"
    else
        echo "NOK pod $POD_NAME did not succeed according to startup logs, see $LOG_DIR/pod.log for details"
    fi

    DEV_SUB_RET=$(echo "$LOG_CACHE" | grep "Subscribing returned")
    DEV_PUB_TO=$(echo "$LOG_CACHE" | grep "Publishing to")
    DEV_RCV_TOP=$(echo "$LOG_CACHE" | grep "Message received on topic")
    DEV_PUB_ST=$(echo "$LOG_CACHE" | grep "ACTIVE")
    if [ ! -z "$DEV_SUB_RET" ] && [ ! -z "$DEV_PUB_TO" ] && [ ! -z "$DEV_RCV_TOP" ]  && [ ! -z "$DEV_PUB_ST" ]; then
        echo "OK pod $POD_NAME succeeded according to subscription logs, see $LOG_DIR/pod.log for details"
    else
        echo "NOK pod $POD_NAME succeeded according to subscription logs, see $LOG_DIR/pod.log for details"
    fi

    DEV_CLIENT_ERR=$(echo "$LOG_CACHE" | grep "Client was interrupted")
    if [ ! -z "$DEV_CLIENT_ERR" ]; then
        echo "NOK pod $POD_NAME encountered interruptions in logs, see $LOG_DIR/pod.log for details"
    else
        echo "OK pod $POD_NAME did not encounter interruption according to logs, see $LOG_DIR/pod.log for details"
    fi

    DEVICE_FAILED=$(echo "$LOG_CACHE" | grep "Failed\|failed\|Error\|error" | grep -v "error_code")
    if [ ! -z "$DEVICE_FAILED" ]; then
        echo "NOK pod $POD_NAME encountered failures in logs, see $LOG_DIR/pod.log for details"
    else
        echo "OK pod $POD_NAME did not encounter failures to logs, see $LOG_DIR/pod.log for details"
    fi
done


# Check sqsDevice logs to see sqs consume and redis publish

POD_NAMES=$(kubectl get po | grep lafleet-device-consumers | cut -d ' ' -f1)

echo "$POD_NAMES" | tr ' ' '\n' | while read POD_NAME; do
    LOG_DIR=$CHK_DIR/logs/$POD_NAME
    mkdir -p "$LOG_DIR"
    kubectl logs $POD_NAME > "$LOG_DIR/pod.log"
    LOG_CACHE=$(cat "$LOG_DIR/pod.log")
    SQS_REDIS_CON=$(echo "$LOG_CACHE" | grep "Redis client connected")
    SQS_REDIS_READY=$(echo "$LOG_CACHE" | grep "Redis client ready")
    SQS_SQS_WAITING=$(echo "$LOG_CACHE" | grep "Waiting...")
    if [ ! -z "$SQS_REDIS_CON" ] && [ ! -z "$SQS_REDIS_READY" ] && [ ! -z "$SQS_SQS_WAITING" ]; then
        echo "OK pod $POD_NAME succeeded according to startup logs, see $LOG_DIR/pod.log for details"
    else
        echo "NOK pod $POD_NAME did not succeed according to startup logs, see $LOG_DIR/pod.log for details"
    fi

    SQS_RCV_MSG=$(echo "$LOG_CACHE" | grep "Received sqs message")
    SQS_HSET=$(echo "$LOG_CACHE" | grep "Succeeded to hSet key")
    SQS_XADD=$(echo "$LOG_CACHE" | grep "Succeeded to xAdd key")
    SQS_UPD=$(echo "$LOG_CACHE" | grep "Redis updated successfully")
    if [ ! -z "$SQS_RCV_MSG" ] && [ ! -z "$SQS_HSET" ] && [ ! -z "$SQS_XADD" ]  && [ ! -z "$SQS_UPD" ]; then
        echo "OK pod $POD_NAME succeeded according to subscription logs, see $LOG_DIR/pod.log for details"
    else
        echo "NOK pod $POD_NAME did not succeed according to subscription logs, see $LOG_DIR/pod.log for details"
    fi

    SQS_CLIENT_ERR=$(echo "$LOG_CACHE" | grep "Redis client disconnected")
    if [ ! -z "$SQS_CLIENT_ERR" ]; then
        echo "NOK pod $POD_NAME encountered disconnections in logs, see $LOG_DIR/pod.log for details"
    else
        echo "OK pod $POD_NAME did not encounter disconnection in logs, see $LOG_DIR/pod.log for details"
    fi

    SQS_FAILED=$(echo "$LOG_CACHE" | grep "Failed\|failed\|Error\|error")
    if [ ! -z "$SQS_FAILED" ]; then
        echo "NOK pod $POD_NAME encountered failures in logs, see $LOG_DIR/pod.log for details"
    else
        echo "OK pod $POD_NAME did not encounter failures in logs, see $LOG_DIR/pod.log for details"
    fi
done


# Check endpoints

ENDPOINT=https://$DN_REACT/query/radius/search/devices/list
RADIUS_SEARCH_DEVICES_LST=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{ "longitude": -73.561668, "latitude": 45.508888, "distance": 5000, "distanceUnit": "km" }' $ENDPOINT)
RADIUS_SEARCH_DEVICES_CHK=$(echo "$RADIUS_SEARCH_DEVICES_LST" | grep "DEVLOC")
if [ ! -z "$RADIUS_SEARCH_DEVICES_CHK" ]; then
    echo "OK devices $RADIUS_SEARCH_DEVICES_LST exist on $ENDPOINT"
else
    echo "NOK devices do not exist on $ENDPOINT"
fi

# Check queryService logs to look for errors

# TODO: Implementsee sqs consume and redis publish


ENDPOINT=https://$DN_REACT/query/h3/aggregate/devices/count
AGGREGATE_DEVICES_CNT=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{ \"h3resolution\": \"0\", \"h3indices\": [ $ALL_H0 ] }" $ENDPOINT)
echo "AGGREGATE_DEVICES_CNT -> $AGGREGATE_DEVICES_CNT"
AGGREGATE_DEVICES_VAL=$(echo "$AGGREGATE_DEVICES_CNT" | jq '.h3indices | length')
echo "AGGREGATE_DEVICES_VAL -> $AGGREGATE_DEVICES_VAL"
#if [ ! -z "$RADIUS_SEARCH_DEVICES_CHK" ]; then
#    echo "OK devices $RADIUS_SEARCH_DEVICES_LST exist on $ENDPOINT"
#else
#    echo "NOK devices do not exist on $ENDPOINT"
#fi


#################### ANALYTICS ###############

# TODO: Implement checks for pod encountered failures

#curl -X POST -H "Content-Type: application/json" https://$DN_REACT/analytics/devices/data
#curl -X POST -H "Content-Type: application/json" https://$DN_REACT/analytics/devices/stats


# {"summary_all": {"start_end": "Start time 2022-10-15 22:52:49.718000 and end 2022-10-15 22:54:49.988000", "first_last": "First record 2022-10-15 22:52:49.718000 and last 2022-10-15 22:54:49.988000, timedelta 120.27 seconds", "devices": "2 devices with stats out of 2", "records": "26 records with stats out of 26, 0.21618026107923838 records/sec"}, "stats_all"
# {"summary_rng": {"start_end": "Start time 2022-10-15 22:52:54.817000 and end 2022-10-15 22:54:44.873000", "first_last": "First record 9999-12-31 23:59:59.999999 and last 0001-01-01 00:00:00, timedelta -86400.0 seconds", "devices": "0 devices with stats out of 0", "records": "0 records with stats out of 0, -0.0 records/sec"}, "stats_rng"


# INFO:waitress:Serving on http://0.0.0.0:5973
# ERROR:main:Exception on /devices/stats [POST]
# Traceback (most recent call last):
#   File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 2525, in wsgi_app
#     response = self.full_dispatch_request()
#   File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 1822, in full_dispatch_request
#     rv = self.handle_user_exception(e)
#   File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 1820, in full_dispatch_request
#     rv = self.dispatch_request()
#   File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 1796, in dispatch_request
#     return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)
#   File "/home/user/main.py", line 76, in getStats
#     summary_all, stats_all, summary_rng, stats_rng = PerformanceStatistics.getStatsAsJson()
#   File "/home/user/performancestatistics.py", line 275, in getStatsAsJson
#     min_val = round(min(gvalues), 1)
# ValueError: min() arg is an empty sequence

# POD_NAME=$(kubectl get po | grep lafleet-analytics | cut -d ' ' -f1)
# LOG_DIR=$CHK_DIR/logs/$POD_NAME
# mkdir -p "$LOG_DIR"
# kubectl logs $POD_NAME > "$LOG_DIR/pod.log"
# LOG_CACHE=$(cat "$LOG_DIR/pod.log")
# ANA_SVC_START=$(echo "$LOG_CACHE" | grep "INFO:waitress:Serving on")
# if [ ! -z "$ANA_SVC_START" ]; then
#     echo "OK pod iot-server succeeded according to logs, see $LOG_DIR/pod.log for details"
# else
#     echo "NOK pod iot-server succeeded according to logs, see $LOG_DIR/pod.log for details"
# fi
