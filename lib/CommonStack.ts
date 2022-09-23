import { CfnOutput, RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { SqsQueue } from './SqsQueue';


export interface CommonStackProps extends StackProps { };

export class CommonStack extends Stack {
  public readonly deviceSqsQueue: SqsQueue;
  public readonly codebuild_artifact_bucket: s3.Bucket;
  public readonly codepipeline_artifact_bucket: s3.Bucket;
  public readonly object_store_bucket: s3.Bucket;

  constructor(scope: Construct, id: string, props: CommonStackProps) {
    super(scope, id);

    const projectName = process.env.PROJECT_NAME;
    if (!projectName) {
      throw new Error("Environement variable PROJECT_NAME is not defined");
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

    
    /********** S3 BUCKET **********/

    const s3props = {
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      versioned: true,
      enforceSSL: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      publicReadAccess: false
    };
    this.codebuild_artifact_bucket = new s3.Bucket(this,
      "S3BUCKET_CODEBUILD_ARTIFACT", { ...s3props,
        bucketName: codebuild_artifact_bucket_name
    });
    this.codepipeline_artifact_bucket = new s3.Bucket(this,
      "S3BUCKET_CODEPIPELINE_ARTIFACT", {...s3props,
        bucketName: codepipeline_artifact_bucket_name
    });
    this.object_store_bucket = new s3.Bucket(this,
      "S3BUCKET_OBJECT_STORE",  {...s3props,
        bucketName: object_store_bucket_name
    });

    const s3ObjectStoreBucketNameOutput = new CfnOutput(this, "S3ObjectStoreBucketName", {
      value: this.object_store_bucket.bucketName,
      description: '',
      exportName: 'S3ObjectStoreBucketName',
    });


    /********** SQS QUEUES **********/

    const sqsDeviceQueueName : string = projectName + "-device-messages";
    this.deviceSqsQueue = new SqsQueue(this, "SqsQueue-" + sqsDeviceQueueName, { sqsQueueName: sqsDeviceQueueName, label: "device" });
    this.deviceSqsQueue.sqsQueue.grantSendMessages(new iam.ServicePrincipal('iot.amazonaws.com'))

  }
}
