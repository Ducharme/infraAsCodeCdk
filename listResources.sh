#!/bin/sh

echo "\n=== aws iot list-things"
aws iot list-things | jq '.things[] | .thingName' | tr -d '"'
echo "\n=== aws iot list-ca-certificates"
aws iot list-ca-certificates
echo "\n=== aws iot list-certificates"
aws iot list-certificates | jq '.certificates[] | "\(.certificateId) \(.status)"' | tr -d '"' # TODO: Cleanup unassigned certificates (deactive & delete)
echo "\n=== aws iot list-policies"
aws iot list-policies | jq '.policies[] | .policyName' | tr -d '"'
echo "\n=== aws iot list-thing-groups"
aws iot list-thing-groups
echo "\n=== aws iot list-security-profiles"
aws iot list-security-profiles
#aws iot list-thing-principals --thing-name <value>
#aws iot list-targets-for-policy --policy-name <value>
#aws iot list-principal-things --principal <value>

echo "\n=== aws iam list-policies"
aws iam list-policies --scope Local | jq '.Policies[] | .PolicyName' | tr -d '"'
echo "\n=== aws iam list-roles"
aws iam list-roles | jq '.Roles[] | "\(.RoleName) -->> \(.Description)"' | tr -d '"' # TODO: Cleanup unassigned roles (except AWSServiceRoleForSupport, AWSServiceRoleForTrustedAdvisor, AWSServiceRoleForOrganizations, and cdk-*-*-*-role-<accountId>-<region>)
#aws iam list-role-policies --role-name <value>

echo "\n=== aws codecommit list-repositories"
aws codecommit list-repositories | jq '.repositories[] | .repositoryName' | tr -d '"'
echo "\n=== aws codebuild list-projects"
aws codebuild list-projects | jq '.projects[] | .' | tr -d '"'
echo "\n=== aws codepipeline list-pipelines"
aws codepipeline list-pipelines | jq '.pipelines[] | .name' | tr -d '"'
echo "\n=== aws codeartifact list-repositories"
aws codeartifact list-repositories
echo "\n=== aws deploy list-deployments"
aws deploy list-deployments
echo "\n=== aws ecr describe-repositories"
aws ecr describe-repositories | jq '.repositories[] | .repositoryName' | tr -d '"'

echo "\n=== aws sqs list-queues"
aws sqs list-queues | jq '.QueueUrls[] | .' | tr -d '"'

echo "\n=== aws cloudfront list-distributions"
aws cloudfront list-distributions | jq '.DistributionList.Items[] | "\(.Id) \(.DomainName) -->> \(.Comment)"' | tr -d '"'
echo "\n=== aws s3api list-buckets"
aws s3api list-buckets | jq '.Buckets[] | .Name' | tr -d '"'
echo "\n=== aws logs describe-log-groups"
aws logs describe-log-groups | jq '.logGroups[] | .logGroupName' | tr -d '"' # TODO: Cleanup unassigned groups

echo "\n=== aws ec2 describe-hosts"
aws ec2 describe-hosts
echo "\n=== aws ec2 describe-images "
aws ec2 describe-images --owners self
echo "\n=== aws ec2 describe-instances"
aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | "\(.InstanceId) \(.InstanceType) KeyName:\(.KeyName)"' | tr -d '"'
echo "\n=== aws ec2 describe-nat-gateways"
aws ec2 describe-nat-gateways | jq '.NatGateways[] | [.NatGatewayId, ( .Tags[] | select( .Key == "aws:cloudformation:stack-name" ).Value ) ] | join(" ")' | tr -d '"'
echo "\n=== aws ec2 describe-local-gateway-virtual-interfaces"
aws ec2 describe-local-gateway-virtual-interfaces
echo "\n=== aws ec2 describe-snapshots"
aws ec2 describe-snapshots --owner-ids self | jq '.Snapshots[] | "\(.SnapshotId) \(.VolumeId)"' | tr -d '"'
echo "\n=== aws ec2 describe-volumes"
aws ec2 describe-volumes | jq '.Volumes[] | "\(.SnapshotId) \(.VolumeId)"' | tr -d '"'
echo "\n=== aws ec2 describe-vpcs"
aws ec2 describe-vpcs | jq '.Vpcs[] | "\(.VpcId) \(.State) -->> IsDefault = \(.IsDefault)"' | tr -d '"'

echo "\n=== aws autoscaling describe-auto-scaling-groups"
aws autoscaling describe-auto-scaling-groups | jq '.AutoScalingGroups[] | "\(.AutoScalingGroupName) MinSize:\(.MinSize) MaxSize:\(.MaxSize) DesiredCapacity:\(.DesiredCapacity)"' | tr -d '"'
echo "\n=== aws elb describe-load-balancers"
aws elb describe-load-balancers | jq '.LoadBalancerDescriptions[] | "\(.LoadBalancerName) \(.CreatedTime)"' | tr -d '"'
echo "\n=== aws eks list-clusters"
aws eks list-clusters | jq '.clusters[]' | tr -d '"'

echo "\n=== aws apigatewayv2 get-apis"
aws apigatewayv2 get-apis | jq '.Items[] | "\(.Name) \(.ApiEndpoint)"' | tr -d '"'
echo "\n=== aws apigateway get-rest-apis"
aws apigateway get-rest-apis

echo "\n=== aws lambda list-functions"
aws lambda list-functions | jq '.Functions[] | "\(.FunctionName) \(.Runtime) -->> \(.Description)"' | tr -d '"'
echo "\n=== aws lambda list-layers"
aws lambda list-layers | jq '.Layers[] | "\(.LayerName) Version:\(.LatestMatchingVersion.Version) \(.LatestMatchingVersion.CompatibleRuntimes[0])"' | tr -d '"'

echo ""
echo "FINISHED!"
