#!/bin/sh


##########  Kubernetes Dashboard (Web UI)  ##########

K8S_DASHBOARD_LINK=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

K8S_DASHBOARD_USER=k8s-dashboard-user
K8S_DASHBOARD_SECRET=$(kubectl get secrets | grep "$K8S_DASHBOARD_USER" | cut -d ' ' -f1)
K8S_DASHBOARD_TOKEN=$(kubectl describe secret $K8S_DASHBOARD_SECRET | grep "token:" | cut -d ':' -f2 | tr -d ' ')

kubectl proxy &

echo ""
echo "*** NOTE - Kubernetes Dashboard (Web UI) ***"
echo "Link is $K8S_DASHBOARD_LINK"
echo "Underlying Service Account $K8S_DASHBOARD_USER hold the Secret"
echo "Login with  with Bearer Token $K8S_DASHBOARD_TOKEN"
echo ""

##########  Redis Insight (Web UI) ##########

kubectl port-forward service/redisinsight-service 8002:80 &

echo "*** NOTE - Redis Insight (Web UI) ***"
echo "Link is http://localhost:8002/ on the computer deploying"
echo ""
