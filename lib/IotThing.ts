import { CfnOutput, Fn, RemovalPolicy } from 'aws-cdk-lib';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import { IotCertificate } from './IotCertificateWithNodejs';
import { Construct } from 'constructs';


export interface IotThingProps {
  readonly thingName : string; // mockIotGpsDeviceAwsSdkV2 OR iotServer
  readonly cfnPolicy : iot.CfnPolicy;
}

export class IotThing extends Construct {

  public iamLogRole : iam.Role;
  public logGroupOk : logs.LogGroup;
  public logGroupErr : logs.LogGroup;

  constructor(scope: Construct, id: string, props: IotThingProps) {
    super(scope, id);

    const projectName = process.env.PROJECT_NAME;
    if (!projectName) {
      throw new Error("Environement variable PROJECT_NAME is not defined");
    }

    const object_store_bucket_name = process.env.S3_OBJECT_STORE;
    if (!object_store_bucket_name) {
      throw new Error("Environement variable S3_OBJECT_STORE is not defined");
    }
    
    const thingName = props.thingName;
    const cwIotDeviceLogsLogGroup : string = "/" + projectName + "/iot/" + thingName + "-logs";
    const cwIotDeviceErrorsLogGroup : string = "/" + projectName + "/iot/" + thingName + "-error-logs";

    const iotCertificateWithNodejs = new IotCertificate(this, 'IotCertificate', {
      object_store_bucket_name: object_store_bucket_name,
      thingName: props.thingName
    });

    var certificateId = iotCertificateWithNodejs.certificateId;
    var certificateArn = iotCertificateWithNodejs.certificateArn;

    if (certificateId === undefined || certificateArn === undefined) {
      certificateId = Fn.importValue('Iot-CertificateId');
      certificateArn = Fn.importValue('Iot-CertificateArn');
    }

    // Need samples for AWS IoT https://github.com/aws-samples/aws-cdk-examples/issues/655
    // How to create IOT thing with certificate and policy https://github.com/aws/aws-cdk/issues/19303
    const cfnThing = new iot.CfnThing(this, 'Thing', {
      thingName: thingName,
    });
    cfnThing.applyRemovalPolicy(RemovalPolicy.DESTROY);
    props.cfnPolicy.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const outputIotPolicyName = new CfnOutput(this, "CustomResource::Output::PolicyName", {
      value: props.cfnPolicy.policyName!,
      description: '',
      exportName: 'Iot-PolicyName-' + props.thingName,
    });

    const policyPrincipalAttachment = new iot.CfnPolicyPrincipalAttachment(
      this,
      'PolicyPrincipalAttachment',
      {
        policyName: props.cfnPolicy.policyName!,
        principal: certificateArn
      },
    );
    policyPrincipalAttachment.addDependency(props.cfnPolicy);
    policyPrincipalAttachment.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const attachCert = new iot.CfnThingPrincipalAttachment(
      this,
      'ThingPrincipalAttachment',
      {
        thingName: cfnThing.thingName!,
        principal: certificateArn
      }
    );
    attachCert.addDependency(cfnThing);
    attachCert.applyRemovalPolicy(RemovalPolicy.DESTROY);


    const logActions = ['logs:CreateLogGroup', 'logs:CreateLogStream', 'logs:PutLogEvents'];
    const logPrincipals = [new iam.ServicePrincipal('iot.amazonaws.com')];

    this.logGroupOk = new logs.LogGroup(this, 'LogGroup-IotSuccess', {
      logGroupName: cwIotDeviceLogsLogGroup,
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: RemovalPolicy.DESTROY
    });
    this.logGroupOk.addToResourcePolicy(new iam.PolicyStatement({
      actions: logActions,
      principals: logPrincipals,
      resources: [this.logGroupOk.logGroupArn],
    }));
    //logGroupOk.grantWrite(iamLogRole);

    this.logGroupErr = new logs.LogGroup(this, 'LogGroup-IotErrors', {
      logGroupName: cwIotDeviceErrorsLogGroup,
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: RemovalPolicy.DESTROY
    });
    this.logGroupErr.addToResourcePolicy(new iam.PolicyStatement({
      actions: logActions,
      principals: logPrincipals,
      resources: [this.logGroupErr.logGroupArn],
    }));
    //logGroupErr.grantWrite(iamLogRole);

    this.iamLogRole = new iam.Role(this, 'LogRole', {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com')
    });
    this.iamLogRole.addToPolicy(
      new iam.PolicyStatement({
        resources: [this.logGroupOk.logGroupArn, this.logGroupErr.logGroupArn],
        actions: logActions,
      }),
    );
  }
}
