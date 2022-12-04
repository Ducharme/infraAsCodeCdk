#!/bin/sh

GF_PW=$(kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)
GF_POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
#kubectl --namespace default port-forward $GF_POD_NAME 3000 &

GF_HOST="http://localhost:3000"
GF_CREDS="admin:$GF_PW"
GF_DS="prometheus"

curl "http://admin:$GF_PW@localhost:3000/api/datasources" -X POST -H "Accept: application/json" -H "Content-Type: application/json" \
    --data-binary '{ "name":"prometheus", "type":"prometheus", "access":"proxy", "url":"http://prometheus-server:80", "basicAuth":false, "withCredentials":false, "isDefault":true }'
echo ""

GF_PM_UID=$(curl -s -k "http://admin:$GF_PW@localhost:3000/api/datasources" -X GET -H "Accept: application/json" -H "Content-Type: application/json" | jq '.[] | select (.name == "prometheus") | .uid' | tr -d '"')
echo "Grafana uid for Prometheus is $GF_PM_UID"

#curl -s -k "http://admin:$GF_PW@localhost:3000/api/dashboards/db" -X POST -H "Accept: application/json" -H "Content-Type: application/json" \
#    -d '{ "dashboard": { "id": null, "uid": null, "title": "Overview", "tags": [ "templated" ], "timezone": "browser", "schemaVersion": 16, "version": 0, "refresh": "15s" }, "folderId": 0, "message": "Creation", "overwrite": false }'
#echo ""

GF_DIR=./tmp/grafana/dashboard
mkdir -p $GF_DIR
ARR="12740 15055 13646 3662 6417 7249"
echo "$ARR" | tr ' ' '\n' | while read item; do
  echo -n "Processing $item: "
  j=$(curl -s -k -u "$GF_CREDS" $GF_HOST/api/gnet/dashboards/$item | jq .json > $GF_DIR/$item.json)

  #curl -s -k -u "$GF_CREDS" -XPOST -H "Accept: application/json" \
  #  -H "Content-Type: application/json" -d "{\"dashboard\":$j,\"overwrite\":true, \"inputs\":[{\"name\":\"Overview\",\"type\":\"datasource\", \"pluginId\":\"prometheus\",\"value\":\"$GF_DS\"}]}" \
  #  $GF_HOST/api/dashboards/import; echo ""
  
  #curl -s -k -X POST -H "Content-Type: application/json" -d "{\"dashboard\":$(cat ./tmp/grafana/dashboard/$item.json)}" http://admin:$GF_PW@localhost:3000/api/dashboards/db

  GF_IMPORTED_ID=$(cat $GF_DIR/$item.json | jq ".id" | tr -d '"')
  echo "Imported id for Dashboard is $GF_IMPORTED_ID"
  GF_IMPORTED_UID=$(cat $GF_DIR/$item.json | jq ".uid" | tr -d '"')
  echo "Imported uid for Prometheus is $GF_IMPORTED_UID"

  sed -i 's@${DS_THEMIS}@'"$GF_DS"'@g' $GF_DIR/$item.json
  sed -i 's@DS_THEMIS@'"$GF_DS"'@g' $GF_DIR/$item.json
  sed -i 's@${DS_PROMETHEUS}@'"$GF_DS"'@g' $GF_DIR/$item.json
  sed -i 's@DS_PROMETHEUS@'"$GF_DS"'@g' $GF_DIR/$item.json
  sed -i 's@${DS_VM-CLUSTER}@'"$GF_DS"'@g' $GF_DIR/$item.json
  sed -i 's@DS_VM-CLUSTER@'"$GF_DS"'@g' $GF_DIR/$item.json
  if [ ! "$GF_IMPORTED_UID" = "null" ]; then
    echo "Imported uid $GF_IMPORTED_UID will be replaced in json by $GF_PM_UID"
    sed -i "s@'"$GF_IMPORTED_UID"'@'"$GF_PM_UID"'@g" $GF_DIR/$item.json
  fi
  if [ ! "$GF_IMPORTED_ID" = "null" ]; then
    echo "Imported uid $GF_IMPORTED_UID will be replaced in json by $GF_PM_UID"
    sed -i "s@'"$GF_IMPORTED_UID"'@'"$GF_PM_UID"'@g" $GF_DIR/$item.json

    cp $GF_DIR/$item.json $GF_DIR/$item-tmp.json
    cat $GF_DIR/$item-tmp.json | jq '.id = "null"' > $GF_DIR/$item.json
  fi

  curl -X POST --insecure -H "Content-Type: application/json" -d "{\"dashboard\":$(cat ./tmp/grafana/dashboard/$item.json), \"inputs\": [{\"name\":\"DS_PROMETHEUS\", \"label\": \"prometheus\", \"description\": \"\", \"type\": \"datasource\", \"pluginId\": \"prometheus\", \"pluginName\": \"Prometheus\"}]}" http://admin:$GF_PW@localhost:3000/api/dashboards/db
done
