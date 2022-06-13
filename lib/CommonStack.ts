import { CfnOutput, RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';


export interface CommonStackProps extends StackProps { };

export class CommonStack extends Stack {
  public readonly sqsQueue: sqs.Queue;
  public readonly sqsQueueRole : iam.Role;
  public readonly sqsDeadLetterQueue: sqs.DeadLetterQueue;
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


    /********** SQS QUEUE **********/

    const sqsQueueName : string = projectName + "-device-messages";
    const sqsDlqName : string = sqsQueueName + "-dlq";

    const sqsProps = { maxMessageSizeBytes: 2048};
    const sqs_queue_dlq : sqs.Queue = new sqs.Queue(this,
      "SQS_DLQ", {...sqsProps,
        queueName: sqsDlqName
    });
    this.sqsDeadLetterQueue = {maxReceiveCount: 3, queue: sqs_queue_dlq };
    this.sqsQueue = new sqs.Queue(this,
      "SQS_QUEUE", {...sqsProps,
        queueName: sqsQueueName,
        deadLetterQueue: this.sqsDeadLetterQueue
    });

    const sqsRole1 = new iam.Role(this, 'SQS_ROLE', {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com')
    });

    sqsRole1.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['sqs:SendMessage', 'sqs:ReceiveMessage'],
        resources: [this.sqsQueue.queueArn, this.sqsDeadLetterQueue.queue.queueArn],
      }),
    );

    this.sqsQueueRole = sqsRole1;

    const sqsQueueNameOutput = new CfnOutput(this, "SqsQueueName", {
      value: this.sqsQueue.queueName,
      description: '',
      exportName: 'SqsQueueName',
    });

    const sqsQueueUrlOutput = new CfnOutput(this, "SqsQueueUrl", {
      value: this.sqsQueue.queueUrl,
      description: '',
      exportName: 'SqsQueueUrl',
    });
  }
}
