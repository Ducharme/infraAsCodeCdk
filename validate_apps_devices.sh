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
IOT_SUB_CNT=$(echo "$LOG_CACHE" | grep "Subscribing returned" | wc-l)
IOT_RCV_CNT=$(echo "$LOG_CACHE" | grep "Message received on topic" | wc-l)
IOT_PUB_ED_CNT=$(echo "$LOG_CACHE" | grep "Published to" | wc-l)
if [ "$IOT_SUB_CNT" = "2" ] && [ "$IOT_RCV_CNT" = "2" ] && [ "$IOT_PUB_ED_CNT" = "2" ]; then
    echo "OK pod iot-server succeeded according to logs, see $LOG_DIR/pod.log for details"
else
    echo "NOK pod iot-server succeeded according to logs, see $LOG_DIR/pod.log for details"
fi

IOT_CLIENT_ERR=$(echo "$LOG_CACHE" | grep "Client was interrupted")
if [ ! -z "$IOT_CLIENT_ERR" ]; then
    echo "NOK pod lafleet-iot-server encountered failures in logs, see $LOG_DIR/pod.log for details"
else
    echo "OK pod lafleet-iot-server succeeded according to logs, see $LOG_DIR/pod.log for details"
fi

SERVER_FAILED=$(echo "$LOG_CACHE" | grep "Failed\|failed")
if [ ! -z "$REDIS_FAILED" ]; then
    echo "NOK pod lafleet-iot-server encountered failures in logs, see $LOG_DIR/pod.log for details"
else
    echo "OK pod lafleet-iot-server succeeded according to logs, see $LOG_DIR/pod.log for details"
fi


# Check mock device logs to see publish

# Starting based on values from Env Vars
# Values endpoint:ahp9n1hu76nbz-ats.iot.ap-southeast-1.amazonaws.com, streamIdRequestTopic:lafleet/devices/streamId/+/request, streamIdReplyTopic:lafleet/devices/streamId/+/reply, interval:10000, count:0, message:undefined, idle:false, client_id:undefined, use_websocket:false, signing_region:undefined, ca_file:./certs/root-ca.crt, cert_file:./certs/certificate.pem.crt, key_file:./certs/private.pem.key, proxy_host:undefined, proxy_port:0, verbosity:undefined
# Values clientId:client-89097521, streamingLocationTopic:lafleet/devices/location/client-89097521/streaming, firmwareVersion:0.0.1, maxGracePeriod:5000, maxLifespan:0, certificateId:0d49267cdf8e329e57128de9ce780c0133a9297632d1b0aaae588e70ea58ae6b
# Client has connected: false
# Subscribing returned {"packet_id":1,"topic":"lafleet/devices/streamId/client-89097521/reply","qos":1,"error_code":0}
# Publishing to lafleet/devices/streamId/client-89097521/request returned {"packet_id":2}
# Client is messaged: lafleet/devices/streamId/client-89097521/reply
# Message received on topic lafleet/devices/streamId/client-89097521/reply {"deviceId":"client-89097521","streamId":0,"seq":0,"serverId":"server-41754626"} (dup:false qos:1 retain:false)
# {"deviceId":"client-89097521","streamId":0,"state":"ACTIVE","ts":1665811770546,"fv":"0.0.1","batt":100,"gps":{"lat":45.42243644920908,"lng":-73.68514355079093,"alt":58.935220449209076},"seq":1}
# {"deviceId":"client-89097521","streamId":0,"state":"ACTIVE","ts":1665811780547,"fv":"0.0.1","batt":100,"gps":{"lat":45.13082913235874,"lng":-73.97675086764127,"alt":58.64361313235874},"seq":2}

# Check sqsDevice logs to see sqs consume and redis publish


ENDPOINT=https://$DN_REACT/query/radius/search/devices/list
RADIUS_SEARCH_DEVICES_LST=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{ "longitude": -73.561668, "latitude": 45.508888, "distance": 5000, "distanceUnit": "km" }' $ENDPOINT)
RADIUS_SEARCH_DEVICES_CHK=$(echo "$RADIUS_SEARCH_DEVICES_LST" | grep "DEVLOC")
if [ ! -z "$RADIUS_SEARCH_DEVICES_CHK" ]; then
    echo "OK devices $RADIUS_SEARCH_DEVICES_LST exist on $ENDPOINT"
else
    echo "NOK devices do not exist on $ENDPOINT"
fi

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

# Performance
