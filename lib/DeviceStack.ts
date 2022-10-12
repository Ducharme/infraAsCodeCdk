import { Aws, Stack, StackProps } from 'aws-cdk-lib';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as iot from 'aws-cdk-lib/aws-iot';
import { CiCd } from './CiCd';
import { Construct } from 'constructs';
import { IotThing } from './IotThing';


export interface DeviceStackProps extends StackProps {
  readonly repoCodeFolder : string;
  readonly sqsQueueRoleArn : string;
  readonly sqsQueueUrl : string;
}

export class DeviceStack extends Stack {
  public readonly sqsQueue: sqs.Queue;
  public readonly sqsDLQ: sqs.DeadLetterQueue;

  constructor(scope: Construct, id: string, props: DeviceStackProps) {
    super(scope, id);

    const projectName = process.env.PROJECT_NAME;
    if (!projectName) {
      throw new Error("Environement variable PROJECT_NAME is not defined");
    }

    const repoName = process.env.DEVICE_REPO;
    if (!repoName) {
      throw new Error("Environement variable DEVICE_REPO is not defined");
    }

    const repoDesc = process.env.DEVICE_DESC;
    if (!repoDesc) {
      throw new Error("Environement variable DEVICE_DESC is not defined");
    }

    const imageRepo = process.env.DEVICE_IMAGE_REPO;
    if (!imageRepo) {
      throw new Error("Environement variable DEVICE_IMAGE_REPO is not defined");
    }

    const branchName = process.env.CODEBUILD_BRANCH_NAME;
    if (!branchName) {
      throw new Error("Environement variable CODEBUILD_BRANCH_NAME is not defined");
    }

    const streamingLocationTopic = process.env.STREAMING_LOCATION_TOPIC;
    if (!streamingLocationTopic) {
      throw new Error("Environement variable STREAMING_LOCATION_TOPIC is not defined");
    }

    const streamIdRequestTopic = process.env.STREAMID_REQUEST_TOPIC;
    if (!streamIdRequestTopic) {
      throw new Error("Environement variable STREAMID_REQUEST_TOPIC is not defined");
    }

    const streamIdReplyTopic = process.env.STREAMID_REPLY_TOPIC;
    if (!streamIdReplyTopic) {
      throw new Error("Environement variable STREAMID_REPLY_TOPIC is not defined");
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


    const thingName = repoName;
    const policyName : string = thingName + "-policy";
    const thingPolicyName : string = projectName + "-" + policyName;

    const streamingLocationTopicFilter = streamingLocationTopic.replace("+", "${iot:ClientId}");
    const streamIdRequestTopicFilter = streamIdRequestTopic.replace("+", "${iot:ClientId}");
    const streamIdReplyTopicFilter = streamIdReplyTopic.replace("+", "${iot:ClientId}");
    const clientFilter = "${iot:ClientId}";
    // NOTE: When not set properly the connect might success but first message afterward will disconnect.
    // -> Error: libaws-c-mqtt: AWS_ERROR_MQTT_UNEXPECTED_HANGUP, The connection was closed unexpectedly.
    const cfnPolicy = new iot.CfnPolicy(this, 'Thing-' + policyName, {
      policyName: thingPolicyName,
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Action: [ "iot:Subscribe" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topicfilter/${streamingLocationTopicFilter}`]
          },
          {
            Effect: "Allow",
            Action: [ "iot:Publish", "iot:Receive" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topic/${streamingLocationTopicFilter}`]
          },
          {
            Effect: "Allow",
            Action: [ "iot:Connect" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:client/${clientFilter}`],
            // TODO: Test less permissive way to connect iot devices
            // https://docs.aws.amazon.com/iot/latest/developerguide/audit-chk-iot-policy-permissive.html
            //"Condition": {
            //  "Bool": { "iot:Connection.Thing.IsAttached": "true" },
            //  "StringEquals": {"${iot:Connection.Thing.ThingName}": `${thingName}`}
            //}
          },
          {
            Effect: "Allow",
            Action: [ "iot:Publish" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topic/${streamIdRequestTopicFilter}`]
          },
          {
            Effect: "Allow",
            Action: [ "iot:Subscribe" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topicfilter/${streamIdReplyTopicFilter}`]
          },
          {
            Effect: "Allow",
            Action: [ "iot:Receive" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topic/${streamIdReplyTopicFilter}`]
          }
        ]
      }
    });

    const iotThing = new IotThing(this, 'ThingStack-' + thingName, {
      cfnPolicy: cfnPolicy,
      thingName: thingName
    });

    //Rule for query topic
    const sqlSelect = `SELECT deviceId, ts as timestamp, fv as firmwareVersion, batt as battery, `
      + `gps.lat as gps_lat, gps.lng as gps_lng, gps.alt as gps_alt, seq, `
      + `timestamp() as server_timestamp, topic() as topic FROM '${streamingLocationTopic}'`
    const sqsRequestRule = new iot.CfnTopicRule(this, 'IotSqsQueryRule-' + thingName, {
      topicRulePayload: {
        sql: sqlSelect,
        description: "LaFleet - Sends messages to SQS from GPS devices",
        ruleDisabled: false,
        awsIotSqlVersion: '2016-03-23',
        actions: [
          {
            sqs: {
              roleArn: props.sqsQueueRoleArn,
              queueUrl: props.sqsQueueUrl,
              useBase64: false
            },
          },
          {
            cloudwatchLogs: {
              roleArn: iotThing.iamLogRole.roleArn,
              logGroupName: iotThing.logGroupOk.logGroupName
            }
          }
        ],
        errorAction: {
          cloudwatchLogs: {
            roleArn: iotThing.iamLogRole.roleArn,
            logGroupName: iotThing.logGroupErr.logGroupName
          }
        }
      },
    });

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
  }
}
