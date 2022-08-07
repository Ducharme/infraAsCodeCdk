import { Aws, Stack, StackProps, CfnOutput, Fn, RemovalPolicy } from 'aws-cdk-lib';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as cr from 'aws-cdk-lib/custom-resources';
import { IotCertificateWithNodejs } from './IotCertificateWithNodejs';
import { CiCd } from './CiCd';
import { Construct } from 'constructs';


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

    const thingTopic = process.env.THING_TOPIC;
    if (!thingTopic) {
      throw new Error("Environement variable THING_TOPIC is not defined");
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
    const cwIotDeviceLogsLogGroup : string = "/" + projectName + "/iot/" + projectName + "-" + thingName + "-logs";
    const cwIotDeviceErrorsLogGroup : string = "/" + projectName + "/iot/" + projectName + "-" + thingName + "-error-logs";

    const devicePolicyName : string = "device-policy";
    const thingPolicyName : string = projectName + "-" + devicePolicyName;

    const iotCertificateWithNodejs = new IotCertificateWithNodejs(this, 'IotCertificateWithNodejs', {
      object_store_bucket_name: object_store_bucket_name
    });

    var certificateId = iotCertificateWithNodejs.certificateId;
    var certificateArn = iotCertificateWithNodejs.certificateArn;

    if (certificateId === undefined || certificateArn === undefined) {
      certificateId = Fn.importValue('Iot-CertificateId');
      certificateArn = Fn.importValue('Iot-CertificateArn');
    }

    // Need samples for AWS IoT https://github.com/aws-samples/aws-cdk-examples/issues/655
    // How to create IOT thing with certificate and policy https://github.com/aws/aws-cdk/issues/19303
    const cfnThing = new iot.CfnThing(this, 'Thing-' + thingName, {
      thingName: thingName,
    });
    cfnThing.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const topicFilter = thingTopic.replace("+", "${iot:ClientId}");
    const clientFilter = "${iot:ClientId}";
    // NOTE: When not set properly the connect might success but first message afterward will disconnect.
    // -> Error: libaws-c-mqtt: AWS_ERROR_MQTT_UNEXPECTED_HANGUP, The connection was closed unexpectedly.
    const cfnPolicy = new iot.CfnPolicy(this, 'Thing-' + devicePolicyName, {
      policyName: thingPolicyName,
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Action: [
              "iot:Publish",
              "iot:Receive",
              "iot:Subscribe"
            ],
            Resource: [
              `arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:topic/${topicFilter}`
            ]
          },
          {
            Effect: "Allow",
            Action: [
              "iot:Connect"
            ],
            Resource: [
              `arn:aws:iot:${Aws.REGION}:${Aws.ACCOUNT_ID}:client/${clientFilter}`
            ]
          }
        ]
      },
    });
    cfnPolicy.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const outputIotPolicyName = new CfnOutput(this, "CustomResource::Output::PolicyName", {
      value: cfnPolicy.policyName!,
      description: '',
      exportName: 'Iot-PolicyName',
    });

    const policyPrincipalAttachment = new iot.CfnPolicyPrincipalAttachment(
      this,
      'PolicyPrincipalAttachment',
      {
        policyName: cfnPolicy.policyName!,
        principal: certificateArn
      },
    );
    policyPrincipalAttachment.addDependsOn(cfnPolicy);
    policyPrincipalAttachment.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const attachCert = new iot.CfnThingPrincipalAttachment(
      this,
      'ThingPrincipalAttachment',
      {
        thingName: cfnThing.thingName!,
        principal: certificateArn
      }
    );
    attachCert.addDependsOn(cfnThing);
    attachCert.applyRemovalPolicy(RemovalPolicy.DESTROY);


    const logActions = ['logs:CreateLogGroup', 'logs:CreateLogStream', 'logs:PutLogEvents'];
    const logPrincipals = [new iam.ServicePrincipal('iot.amazonaws.com')];

    const logGroupOk = new logs.LogGroup(this, 'LogGroup-IotSuccess', {
      logGroupName: cwIotDeviceLogsLogGroup,
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: RemovalPolicy.DESTROY
    });
    logGroupOk.addToResourcePolicy(new iam.PolicyStatement({
      actions: logActions,
      principals: logPrincipals,
      resources: [logGroupOk.logGroupArn],
    }));
    //logGroupOk.grantWrite(iamLogRole);

    const logGroupErr = new logs.LogGroup(this, 'LogGroup-IotErrors', {
      logGroupName: cwIotDeviceErrorsLogGroup,
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: RemovalPolicy.DESTROY
    });
    logGroupErr.addToResourcePolicy(new iam.PolicyStatement({
      actions: logActions,
      principals: logPrincipals,
      resources: [logGroupErr.logGroupArn],
    }));
    //logGroupErr.grantWrite(iamLogRole);

    const iamLogRole = new iam.Role(this, 'DeviceLogRole', {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com')
    });
    iamLogRole.addToPolicy(
      new iam.PolicyStatement({
        resources: [logGroupOk.logGroupArn, logGroupErr.logGroupArn],
        actions: logActions,
      }),
    );

    //Rule for query topic
    const sqsRequestRule = new iot.CfnTopicRule(this, 'IotSqsQueryRule', {
      topicRulePayload: {
        sql: `SELECT deviceId, ts as timestamp, fv as firmwareVersion, batt as battery, gps.lat as gps_lat, gps.lng as gps_lng, gps.alt as gps_alt, seq, timestamp() as server_timestamp, topic() as topic FROM '${thingTopic}'`,
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
              roleArn: iamLogRole.roleArn,
              logGroupName: logGroupOk.logGroupName
            }
          }
        ],
        errorAction: {
          cloudwatchLogs: {
            roleArn: iamLogRole.roleArn,
            logGroupName: logGroupErr.logGroupName
          }
        }
      },
    });

    const getIoTEndpoint = new cr.AwsCustomResource(this, 'IoTEndpoint', {
      onCreate: {
        service: 'Iot',
        action: 'describeEndpoint',
        physicalResourceId: cr.PhysicalResourceId.fromResponse('endpointAddress'),
        parameters: {
          "endpointType": "iot:Data-ATS"
        }
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE})
    });

    const iotEp = getIoTEndpoint.getResponseField('endpointAddress')
    const outputIotEndpoint = new CfnOutput(this, "EndpointAddress", {
      value: iotEp.toString(),
      description: '',
      exportName: 'Iot-EndpointAddress',
    });

    const outputThingTopic = new CfnOutput(this, "ThingTopic", {
      value: thingTopic,
      description: '',
      exportName: 'Iot-ThingTopic',
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
