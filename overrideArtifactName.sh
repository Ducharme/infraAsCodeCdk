#!/bin/sh

# CodeProject Default (cannot change in CDK) -> Override artifact name: True
# Console -> Enable semantic versioning: Use the artifact name specified in the buildspec file

overrideValue(){
  REPO_NAME=$1
  ARTIFACTS=$(aws codebuild batch-get-projects --names $REPO_NAME | jq '.projects[0].artifacts')
  aws codebuild update-project --name $REPO_NAME --artifacts "
  {
    \"type\": $( echo "$ARTIFACTS" | jq '.type'),
    \"location\": $( echo "$ARTIFACTS" | jq '.location'),
    \"path\": $( echo "$ARTIFACTS" | jq '.path'),
    \"namespaceType\": $( echo "$ARTIFACTS" | jq '.namespaceType'),
    \"name\": $( echo "$ARTIFACTS" | jq '.name'),
    \"packaging\": $( echo "$ARTIFACTS" | jq '.packaging'),
    \"encryptionDisabled\": $( echo "$ARTIFACTS" | jq '.encryptionDisabled'),
    \"overrideArtifactName\": true,
    \"artifactIdentifier\": $( echo "$ARTIFACTS" | jq '.artifactIdentifier')
  }" 1>/dev/null
}

echo "Overriding CodeProject ArtifactName on $DEVICE_REPO"
overrideValue $DEVICE_REPO
echo "Overriding CodeProject ArtifactName on $IOT_SERVER_REPO"
overrideValue $IOT_SERVER_REPO
echo "Overriding CodeProject ArtifactName on $DEVICE_CONSUMER_REPO"
overrideValue $DEVICE_CONSUMER_REPO
echo "Overriding CodeProject ArtifactName on $SHAPE_CONSUMER_REPO"
overrideValue $SHAPE_CONSUMER_REPO
echo "Overriding CodeProject ArtifactName on $QUERY_REPO"
overrideValue $QUERY_REPO
echo "Overriding CodeProject ArtifactName on $ANALYTICS_REPO"
overrideValue $ANALYTICS_REPO
