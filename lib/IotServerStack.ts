import { Aws, Stack, StackProps } from 'aws-cdk-lib';
import * as iot from 'aws-cdk-lib/aws-iot';
import { CiCd } from './CiCd';
import { Construct } from 'constructs';
import { IotThing } from './IotThing';


export interface IotServerStackProps extends StackProps {
  readonly repoCodeFolder : string;
}

export class IotServerStack extends Stack {

  constructor(scope: Construct, id: string, props: IotServerStackProps) {
    super(scope, id);


    const projectName = process.env.PROJECT_NAME;
    if (!projectName) {
      throw new Error("Environement variable PROJECT_NAME is not defined");
    }

    const repoName = process.env.IOT_SERVER_REPO;
    if (!repoName) {
      throw new Error("Environement variable IOT_SERVER_REPO is not defined");
    }

    const repoDesc = process.env.IOT_SERVER_DESC;
    if (!repoDesc) {
      throw new Error("Environement variable IOT_SERVER_DESC is not defined");
    }

    const imageRepo = process.env.IOT_SERVER_IMAGE_REPO;
    if (!imageRepo) {
      throw new Error("Environement variable IOT_SERVER_IMAGE_REPO is not defined");
    }

    const branchName = process.env.CODEBUILD_BRANCH_NAME;
    if (!branchName) {
      throw new Error("Environement variable CODEBUILD_BRANCH_NAME is not defined");
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
    // Replace + by * for policy so access is more standardized like IAM
    // https://docs.aws.amazon.com/iot/latest/developerguide/pub-sub-policy.html
    const streamIdRequestTopicFilter = streamIdRequestTopic.replace("+", "*");
    const streamIdReplyTopicFilter = streamIdReplyTopic.replace("+", "*");
    const clientFilter = "${iot:ClientId}";
    // NOTE: When not set properly the connect might success but first message afterward will disconnect.
    // -> Error: libaws-c-mqtt: AWS_ERROR_MQTT_UNEXPECTED_HANGUP, The connection was closed unexpectedly.
    // NOTE: Explore retained messages for device streamId requests (could accumulate too muchover time)
    // https://aws.amazon.com/about-aws/whats-new/2021/08/aws-iot-core-supports-mqtt-retained-messages/
    const cfnPolicy = new iot.CfnPolicy(this, 'Thing-' + policyName, {
      policyName: thingPolicyName,
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Action: [ "iot:Publish" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topic/${streamIdReplyTopicFilter}`]
          },
          {
            Effect: "Allow",
            Action: [ "iot:Subscribe" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topicfilter/${streamIdRequestTopicFilter}`]
          },
          {
            Effect: "Allow",
            Action: [ "iot:Receive" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topic/${streamIdRequestTopicFilter}`]
          },
          {
            Effect: "Allow",
            Action: [ "iot:Connect" ],
            Resource: [`arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:client/${clientFilter}`],
          }
        ]
      }
    });

    const iotThing = new IotThing(this, 'ThingStackFor-' + thingName, {
      cfnPolicy: cfnPolicy,
      thingName: thingName
    });

    //Rule for query topic
    const requestSqlSelect = `SELECT deviceId, timestamp() as server_timestamp, topic() as topic FROM '${streamIdRequestTopic}'`;
    this.CreateTopicRule('IotRequestCloudWatchRule-' + thingName, requestSqlSelect, "LaFleet - Sends request messages to CloudWatch", iotThing);

    const replySqlSelect = `SELECT deviceId, streamId, seq, serverId, timestamp() as server_timestamp, topic() as topic FROM '${streamIdRequestTopic}'`;
    this.CreateTopicRule('IotReplyCloudWatchRule-' + thingName, replySqlSelect, "LaFleet - Sends reply messages to CloudWatch", iotThing);

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

  private CreateTopicRule(id: string, sqlQuery: string, description: string, iotThing: IotThing) {
    new iot.CfnTopicRule(this, id, {
      topicRulePayload: {
        sql: sqlQuery,
        description: description,
        ruleDisabled: false,
        awsIotSqlVersion: '2016-03-23',
        actions: [
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
  }
}
