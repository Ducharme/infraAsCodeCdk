# Pre-requisites


## AWS user

Create an IAM user granted policy AdministratorAccess.

Under "Security credentials" tab, under "Access keys" section, click Create access key and save the file for later.

Under "Security credentials" tab, under "HTTPS Git credentials for AWS CodeCommit" section, click "Generate credentials" and save the file for later.


## curl

cURL is a command-line tool for getting or sending data including files using URL syntax

```
sudo apt install curl
```


## aws cli version 2

Get the aws cli version by running
```
aws --version
```

If version is 1 (aws-cli/1.x.xx) follow [Installing, updating, and uninstalling the AWS CLI v1](https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-install.html)

On linux/ubuntu commands would be similar to
```
pip3 uninstall awscli
sudo rm -rf /usr/local/aws
sudo rm /usr/local/bin/aws
```

If version is below aws-cli/2.4.x or package is not installed, follow [Installing or updating the latest version of the AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update

```
or
```
python3 -m pip install awscli --upgrade
```
or if the install was a bundle [install linux bundled uninstall](https://docs.aws.amazon.com/cli/v1/userguide/install-linux.html#install-linux-bundled-uninstall)


Then follow [Configuration basics for CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) using values from "new_user_credentials.csv" previously generated in AWS console.
```
aws configure
```


## CodeCommit git

Use file "&lt;user&gt;_codecommit_credentials.csv" previously generated in AWS console.

```
sudo apt-get install git
git config --global user.name <User Name>
git config --global user.email <email>
git config --global user.password <Password>
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.usehttppath true
```

Reference to setup git
[7.14 Git Tools - Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
[8.1 Customizing Git - Git Configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
[Troubleshooting Git credentials and HTTPS connections to AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/troubleshooting-gc.html)


## GitHub CLI

```
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

Autenticate

```
gh auth login
```


## jq

jq is a lightweight and flexible command-line JSON processor

Install by running
```
sudo apt install -y jq
```
or follow [Download jq](https://stedolan.github.io/jq/download/)


## yq

yq a lightweight and portable command-line YAML processor

Install by running
```
snap install yq
```
or follow [Download yq](https://github.com/mikefarah/yq#wget)
```
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
```


## zip unzip

Install by running
```
sudo apt install zip unzip
```


## npm

Install by running
```
sudo apt install npm
npm install -g npm@8.9.0
```


## Node.js

Install by running
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
source ~/.bash_profile
nvm list-remote
nvm install v16.15.0
```


## aws cdk

[CDK Workshop pre-requisites](https://cdkworkshop.com/15-prerequisites.html) especially "AWS CDK Toolkit".

```
npm install -g aws-cdk@latest
```


## eksctl

[AWS EKS userguide eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
 and [eksctl introduction/installation](https://eksctl.io/introduction/#installation)
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

export KUBECONFIG=~/.kube/eksctl/clusters/lafleet-cluster
export EKSCTL_ENABLE_CREDENTIAL_CACHE=1
```

https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/


## kubectl

https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
```
curl -LO https://dl.k8s.io/release/v1.21.8/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
kubectl version --short --client
```


## Helm

> To avoid follow exception, set version to 3.8.2
> Error: INSTALLATION FAILED: Kubernetes cluster unreachable: exec plugin: invalid apiVersion "client.authentication.k8s.io/v1alpha1"

https://helm.sh/docs/intro/install/
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
DESIRED_VERSION=v3.8.2 bash get_helm.sh
```
or
```
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```


## Docker

Run docker without admin rights
[Docker engine install ubuntu](https://docs.docker.com/engine/install/ubuntu/)
[Docker engine postinstall ubuntu](https://docs.docker.com/engine/install/linux-postinstall/)


## Visual Code (optional for development)

[Download Visual Studio Code deb file](https://code.visualstudio.com/download) then follow [Debian and Ubuntu based distributions](https://code.visualstudio.com/docs/setup/linux#_debian-and-ubuntu-based-distributions)
```
sudo apt install ./<file>.deb
```


## Google Chrome (optional for development)

[Download 64 bit .deb (For Debian/Ubuntu)](https://www.google.com/chrome/) then follow execute
```
sudo apt install ./<file>.deb
```


# How To Deploy


## First step: Download scripts locally (1 minute)

Create a folder for the project and go inside
```
mkdir LaFleet && cd LaFleet
```

Clone the repository which contains all the scripts
```
git clone https://github.com/Ducharme/infraAsCodeCdk
```

Copy/paste file .env.example and rename it to .env.production then replace the MAPBOX_TOKEN by yours. You need to create an account on mapbox then go to https://account.mapbox.com/access-tokens/ to get your default public token.



## Second step: Deploy core infrastructure (13 minutes)

Run below script (tested with Lubuntu 20.04 default terminal)

```
npm install
cdk bootstrap
sh ./run_synth.sh
sh ./main_create_core.sh
```
Note: It is recommended to have FORCE=TRUE set


## Third step: Deploy Kubernetes cluster (29 minutes)

Use eksctl by running below script to get an EKS cluster and React Website
```
sh ./main_create_k8s.sh
```

Approximate timings:
1. eksctl-lafleet-cluster-cluster (15 minutes)
2. eksctl-lafleet-cluster-addon-iamserviceaccount-default-lafleet-eks-sa-sqsdeviceconsumer (2 minutes)
3. eksctl-lafleet-cluster-addon-iamserviceaccount-default-lafleet-eks-sa-sqsshapeconsumer (2 minutes)
4. eksctl-lafleet-cluster-addon-iamserviceaccount-kube-system-aws-node (2 minutes in // with 2.)
5. eksctl-lafleet-cluster-nodegroup-ng-standard-x64 (4 minutes)
6. eksctl-lafleet-cluster-nodegroup-ng-compute-x64 (4 minutes in // with 4.)
7. cdk deploy LaFleet-WebsiteStack


## Fourth step: Deploy pods on EKS cluster (2 minutes)

Run below script
```
sh ./main_create_k8s_apps.sh
```

When ready, launch mock decices with
```
kubectl apply -f ./eks/devices-slow_deployment.yml
```

Once completed you should see the map with CloudFront.
[LaFleet PoC - Core](images/LaFleet-core.png?raw=true)


# Resources created by the scripts

* IoT Core (Thing, Security/Certificates, Security/Policy, Rules)
* SQS & SQS DLQ
* S3 buckets (4x)
* CloudFront Distribution & OAI
* CloudWatch Log Groups
* IAM/roles with inline policies
* CodeCommit (7x)
* CodeBuild (7x)
* CodePipeline (7x)
* ECR (6x)
* EC2/Instances
* EC2/LoadBalancer
* EC2/Auto Scaling Groups
* VPC/NAT gateways
* EKS cluster
* API Gateway v2 (HTTP)
* Lambda/Functions
* Lambda/Layers

## CodeBuild Repositories (ECR Repository)

* mockIotGpsDeviceAwsSdkV2: Emulated IoT GPS Device based on aws-iot-device-sdk-v2 (mock-iot-gps-device-awssdkv2)
* iotServer: IoT Server based on aws-iot-device-sdk-v2 (iot-server)
* sqsDeviceConsumerToRedisearch: SQS Device Consumer writing to Redisearch in TypeScript (sqsdeviceconsumer-toredisearch)
* sqsShapeConsumerToRedisearch: SQS Shape Consumer writing to Redisearch in TypeScript (sqsshapeconsumer-toredisearch)
* redisearchQueryClient: Service to query Redisearch in TypeScript (redisearch-query-client)
* redisPerformanceAnalyticsPy: Redis performance analytics in python3 (redisearch-performance-analytics-py)


# Playing with Kubernetes

## Setup the environment once eksctl is deployed

```
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc
```

Run this everytime a new terminal session is opened
```
export EKSCTL_ENABLE_CREDENTIAL_CACHE=1
export KUBECONFIG=~/.kube/eksctl/clusters/lafleet-cluster
```

To retrieve the config from another computer and save it locally
```
eksctl utils write-kubeconfig --cluster=lafleet-cluster --kubeconfig=/home/$USER/.kube/eksctl/clusters/lafleet-cluster
```

## Creating a pod with curl on the cluster

```
NODESELECTOR='{ "apiVersion": "v1", "spec": { "template": { "spec": { "nodeSelector": { "nodegroup-type": "backend-standard" } } } } }'
kubectl run curl --image=radial/busyboxplus:curl -i --rm --tty --overrides="$NODESELECTOR"
```

### To query analytics

Note: Add arguments --raw --show-error --verbose for more details

### For analytics service

Port 5973 exposed to 80
```
curl -s -X GET -H "Content-Type: text/html" http://analytics-service/
curl -s -X GET -H "Content-Type: text/html" http://analytics-service/health
curl -s -X POST -H "Content-Type: application/json" http://analytics-service/devices/data
curl -s -X POST -H "Content-Type: application/json" http://analytics-service/devices/stats
curl -s -X POST -H "Content-Type: text/html" http://analytics-service/devices/stats
curl -s -X DELETE -H "Content-Type: application/json" http://analytics-service/devices
```

#### For redisearch service

Note: External service domain is https://&lt;cloudfront-distribution-domain-name&gt; which looks like d12acbc34def5g0.cloudfront.net (not to be confused with CloudFront Distribution ID with capital alpha-numeric)

```
curl -s --raw --show-error --verbose -L -X GET http://query-service
curl -s --raw --show-error --verbose -L -X GET http://query-service/health
curl -s --raw --show-error --verbose -L -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"h3resolution":"0","h3indices":["802bfffffffffff","8023fffffffffff"]}' http://query-service/h3/aggregate/device-count
curl -s --raw --show-error --verbose -L -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"longitude":-73.5, "latitude": 45.5, "distance": 200, "distanceUnit": "km"}' http://query-service/location/search/radius/device-list
curl -s --raw --show-error --verbose -L -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"h3resolution":"0","h3indices":["802bfffffffffff","8023fffffffffff"]}' https://d12acbc34def5g0.cloudfront.net/query/h3/aggregate/device-count
```


## Creating a pod with redis on the cluster

Note: Use \<Shift\>+R to get the prompt to show with redis client otherwise the terminal might not display it
Note: Add arguments --raw --show-error --verbose for more details

```
NODESELECTOR='{ "apiVersion": "v1", "spec": { "template": { "spec": { "nodeSelector": { "nodegroup-type": "backend-standard" } } } } }'
kubectl run redis-cli3 --image=redis:latest --attach --leave-stdin-open --rm -it  --labels="app=redis-cli,project=lafleet" --overrides="$NODESELECTOR" -- redis-cli -h redisearch-service
```

Common commands
```
$ KEYS *
$ FLUSHALL
$ HGETALL DEVLOC:lafleet/devices/location/test-123456/streaming
$ XRANGE STREAMDEV:lafleet/devices/location/test-123456/streaming - +
```

Using INDEX
```
FT.AGGREGATE topic-h3-idx "@topic:lafleet/devices/location/+/streaming @h3r0:{802bfffffffffff | 802bffffffffffw }" GROUPBY 1 @h3r0 REDUCE COUNT 0 AS num_devices
FT.SEARCH topic-lnglat-idx "@topic:lafleet/devices/location/+/streaming @lnglat:[-73 45 100 km]" NOCONTENT
```

## To play locally with redisearch

Creating INDEX
```
sudo docker run --name redisearch-cli --rm -it -d -p 6379:6379 redislabs/redisearch:latest

DEVICE_INDEX_H3="FT.CREATE topic-h3-idx ON HASH PREFIX 1 DEVLOC: SCHEMA topic TEXT h3r0 TAG h3r1 TAG h3r2 TAG h3r3 TAG h3r4 TAG h3r5 TAG h3r6 TAG h3r7 TAG h3r8 TAG h3r9 TAG h3r10 TAG h3r11 TAG h3r12 TAG h3r13 TAG h3r14 TAG h3r15 TAG dts NUMERIC batt NUMERIC fv TEXT"
DEVICE_INDEX_LOC="FT.CREATE topic-lnglat-idx ON HASH PREFIX 1 DEVLOC: SCHEMA topic TEXT lnglat GEO dts NUMERIC batt NUMERIC fv TEXT"
SHAPE_INDEX_TYPE="FT.CREATE shape-type-idx ON JSON PREFIX 1 SHAPELOC: SCHEMA $.type AS type TEXT"
SHAPE_INDEX_LOC_FILTER="FT.CREATE shape-loc-filter-idx ON JSON PREFIX 1 SHAPELOC: SCHEMA $.status AS status TEXT $.type AS type TEXT $.filter.h3r0.* AS f_h3r0 TAG $.filter.h3r1.* AS f_h3r1 TAG $.filter.h3r2.* AS f_h3r2 TAG $.filter.h3r3.* AS f_h3r3 TAG $.filter.h3r4.* AS f_h3r4 TAG $.filter.h3r5.* AS f_h3r5 TAG $.filter.h3r6.* AS f_h3r6 TAG $.filter.h3r7.* AS f_h3r7 TAG $.filter.h3r8.* AS f_h3r8 TAG $.filter.h3r9.* AS f_h3r9 TAG $.filter.h3r10.* AS f_h3r10 TAG $.filter.h3r11.* AS f_h3r11 TAG $.filter.h3r12.* AS f_h3r12 TAG $.filter.h3r13.* AS f_h3r13 TAG $.filter.h3r14.* AS f_h3r14 TAG $.filter.h3r15.* AS f_h3r15 TAG"
SHAPE_INDEX_LOC_MATCH="FT.CREATE shape-loc-match-idx ON JSON PREFIX 1 SHAPELOC: SCHEMA $.status AS status TEXT $.type AS type TEXT $.shape.h3r0.* AS s_h3r0 TAG $.shape.h3r1.* AS s_h3r1 TAG $.shape.h3r2.* AS s_h3r2 TAG $.shape.h3r3.* AS s_h3r3 TAG $.shape.h3r4.* AS s_h3r4 TAG $.shape.h3r5.* AS s_h3r5 TAG $.shape.h3r6.* AS s_h3r6 TAG $.shape.h3r7.* AS s_h3r7 TAG $.shape.h3r8.* AS s_h3r8 TAG $.shape.h3r9.* AS s_h3r9 TAG $.shape.h3r10.* AS s_h3r10 TAG $.shape.h3r11.* AS s_h3r11 TAG $.shape.h3r12.* AS s_h3r12 TAG $.shape.h3r13.* AS s_h3r13 TAG $.shape.h3r14.* AS s_h3r14 TAG $.shape.h3r15.* AS s_h3r15 TAG"

echo "$DEVICE_INDEX_H3" | redis-cli 
echo "$DEVICE_INDEX_LOC" | redis-cli
echo "$SHAPE_INDEX_TYPE" | redis-cli
echo "$SHAPE_INDEX_LOC_FILTER" | redis-cli
echo "$SHAPE_INDEX_LOC_MATCH" | redis-cli

FT._LIST
```

## Prometheus

The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster: "prometheus-server.monitoring.svc.cluster.local". 
Get the Prometheus server URL by running these commands in the same shell then go to http://localhost:9090/graph or http://localhost:9090/metrics
```
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 9090
```

The Prometheus Alertmanager can be accessed via port 80 on the following DNS name from within your cluster: "prometheus-alertmanager.monitoring.svc.cluster.local". 
Get the Alertmanager URL by running these commands in the same shell:
```
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=alertmanager" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 9093
```

The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster: "prometheus-pushgateway.monitoring.svc.cluster.local". 
Get the PushGateway URL by running these commands in the same shell:
```
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 9091
```

## OpenSearch dashboard

Get the application URL by running these commands:
```
export POD_NAME=$(kubectl get pods --namespace logging -l "app=opensearch-dashboards" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace logging $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
kubectl --namespace logging port-forward $POD_NAME 8080:$CONTAINER_PORT
```
Visit http://127.0.0.1:8080 to use OpenSearch (default username/password are admin/admin)


## Grafana

Get your 'admin' user password by running:
```
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

The Grafana server can be accessed via port 80 on the following DNS name from within your cluster: "grafana.monitoring.svc.cluster.local". 
Get the Grafana URL to visit by running these commands in the same shell:
```
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 3000
```
Visit http://127.0.0.1:3000 to use Grafana (see first command line for username/password)


## Destroying

Execute
```
sh ./main_delete_all.sh
```
Note: It is recommended to have FORCE=TRUE


### Known issues

Resources left after:
* IoT Core - Security/Certificates
* CloudWatch - Log Group


# License

LaFleet PoC is available under the [MIT license](LICENSE). LaFleet PoC also includes external libraries that are available under a variety of licenses, see [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES) for the list.
