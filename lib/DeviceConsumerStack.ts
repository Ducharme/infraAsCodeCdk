import { Stack, StackProps } from 'aws-cdk-lib';
import { CiCd } from './CiCd';
import { Construct } from 'constructs';


export interface DeviceConsumerStackProps extends StackProps {
  readonly repoCodeFolder : string;
}

export class DeviceConsumerStack extends Stack {

  constructor(scope: Construct, id: string, props: DeviceConsumerStackProps) {
    super(scope, id);

    const repoName = process.env.DEVICE_CONSUMER_REPO;
    if (!repoName) {
      throw new Error("Environement variable DEVICE_CONSUMER_REPO is not defined");
    }

    const repoDesc = process.env.DEVICE_CONSUMER_DESC;
    if (!repoDesc) {
      throw new Error("Environement variable DEVICE_CONSUMER_DESC is not defined");
    }

    const imageRepo = process.env.DEVICE_CONSUMER_IMAGE_REPO;
    if (!imageRepo) {
      throw new Error("Environement variable DEVICE_CONSUMER_IMAGE_REPO is not defined");
    }

    const branchName = process.env.CODEBUILD_BRANCH_NAME;
    if (!branchName) {
      throw new Error("Environement variable CODEBUILD_BRANCH_NAME is not defined");
    }

    const object_store_bucket_name = process.env.S3_OBJECT_STORE;
    if (!object_store_bucket_name) {
      throw new Error("Environement variable S3_OBJECT_STORE is not defined");
    }

    const codebuild_artifact_bucket_name = process.env.S3_CODEBUILD_ARTIFACTS;
    if (!codebuild_artifact_bucket_name) {
      throw new Error("Environement variable S3_CODEBUILD_ARTIFACTS is not defined");
    }

    const codepipeline_artifact_bucket_name = process.env.S3_CODEPIPELINE_ARTIFACTS;
    if (!codepipeline_artifact_bucket_name) {
      throw new Error("Environement variable S3_CODEPIPELINE_ARTIFACTS is not defined");
    }

    const thingTopic = process.env.STREAMING_LOCATION_TOPIC;
    if (!thingTopic) {
      throw new Error("Environement variable STREAMING_LOCATION_TOPIC is not defined");
    }

    var cicd = new CiCd(this, "CICD-" + repoName, {
        repoName: repoName,
        repoDescription: repoDesc,
        registryRepoName: imageRepo,
        repoCodeFolder: props.repoCodeFolder,
        sourceVersionBranchName: branchName,
        object_store_bucket_name: object_store_bucket_name,
        codebuild_artifact_bucket_name: codebuild_artifact_bucket_name,
        codepipeline_artifact_bucket_name: codepipeline_artifact_bucket_name
    });

    // TODO: Might have race condition with s3 env config file replication if build is faster than cdk to copy

  }
}