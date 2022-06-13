import { Duration, CfnOutput, CfnCustomResource, Stack } from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cr from 'aws-cdk-lib/custom-resources';
import * as njs from 'aws-cdk-lib/aws-lambda-nodejs';
import { Construct } from 'constructs';


export interface IotCertificateWithNodejsProps {
  readonly object_store_bucket_name : string;
}

export class IotCertificateWithNodejs extends Construct {

  readonly certificateId : string;
  readonly certificateArn : string;

  constructor(scope: Construct, id: string, props: IotCertificateWithNodejsProps) {
    super(scope, id);

    const lambdaExecutionRole = new iam.Role(this, 'LambdaExecutionRole', {
      assumedBy: new iam.CompositePrincipal(
        new iam.ServicePrincipal('lambda.amazonaws.com'),
      ),
    });

    lambdaExecutionRole.addToPolicy(
      new iam.PolicyStatement({
        resources: ['arn:aws:logs:*:*:*'],
        actions: [
          'logs:CreateLogGroup',
          'logs:CreateLogStream',
          'logs:PutLogEvents',
        ],
      }),
    );

    lambdaExecutionRole.addToPolicy(
      new iam.PolicyStatement({
        resources: ['*'],
        actions: ['iot:*'],
      }),
    );

    //props.object_store_bucket.grantReadWrite(arp);
    var arp = new iam.AccountRootPrincipal();
    var s3actions = ['s3:Get*', 's3:Put*', 's3:List*'];
    const object_store_bucket = s3.Bucket.fromBucketName(this,
      "imported_object_store_bucket_name_for_iot",
      props.object_store_bucket_name);
    var s3res = [object_store_bucket.bucketArn, object_store_bucket.arnForObjects('*')];

    object_store_bucket.addToResourcePolicy(new iam.PolicyStatement({
      actions: s3actions,
      resources: s3res,
      principals: [arp, lambdaExecutionRole]
    }));

    lambdaExecutionRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: s3actions,
      resources: s3res
    }));

    var lambdaLayer = new lambda.LayerVersion (this, "LambdaLayerNpmInstall", {
      compatibleRuntimes: [
        lambda.Runtime.NODEJS_14_X,
      ],
      code: lambda.Code.fromAsset(`${__dirname}/../tmp/lambda-layers/aws-sdk-client-iot-layer.zip`)
    });

    // https://github.com/devops-at-home/cdk-iot-core-certificates
    // NOTE: Could try "code/bundling/command npm install" instead of a layer
    // https://stackoverflow.com/questions/58855739/how-to-install-external-modules-in-a-python-lambda-function-created-by-aws-cdk
    const lambdaForCerts = new njs.NodejsFunction(this, 'Lambda::Certificates::NodejsFunction', {
      memorySize: 128,
      timeout: Duration.seconds(15),
      runtime: lambda.Runtime.NODEJS_14_X,
      entry: `${__dirname}/lambda-handlers/certificates/index.ts`,
      handler: 'handler',
      bundling: {
        // Layers are already available in the lambda env
        // TODO: This could be dynamic. cat lib/lambda-layers/package.json | jq -r '.dependencies | keys'
        externalModules: ['@aws-sdk/client-iot', '@aws-sdk/client-s3', '@aws-sdk/client-sts'],
      },
      role: lambdaExecutionRole,
      layers: [lambdaLayer],
      logRetention: logs.RetentionDays.ONE_DAY,
      environment: {
        object_store_bucket_name: props.object_store_bucket_name,
        accountId: Stack.of(this).account,
        region: Stack.of(this).region
      },
    });

    const lambdaProvider = new cr.Provider(this, 'Lambda::Certificates::CustomResourceProvider', {
      onEventHandler: lambdaForCerts,
      logRetention: logs.RetentionDays.ONE_DAY,
    });

    const lambdaCustomResource = new CfnCustomResource(
      this,
      'lambdaCustomResourceCfn',
      {
        serviceToken: lambdaProvider.serviceToken,
      },
    );

    // https://github.com/aws/aws-cdk/issues/17613
    const outputIotCertificateId = new CfnOutput(this, "CustomResource::Output::CertificateId", {
      value: lambdaCustomResource.getAtt('certificateId').toString(),
      description: '',
      exportName: 'Iot-CertificateId',
    });
    this.certificateId = outputIotCertificateId.value;

    const outputIotCertificateArn = new CfnOutput(this, "CustomResource::Output::CertificateArn", {
      value: lambdaCustomResource.getAtt('certificateArn').toString(),
      description: '',
      exportName: 'Iot-CertificateArn',
    });
    this.certificateArn = outputIotCertificateArn.value;
  }

}
