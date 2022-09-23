import {  Duration, RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import { HttpApi, HttpMethod } from '@aws-cdk/aws-apigatewayv2-alpha';
import { HttpUrlIntegration, HttpLambdaIntegration } from '@aws-cdk/aws-apigatewayv2-integrations-alpha';
import { Construct } from 'constructs';
import { SqsQueue } from './SqsQueue';
import { ShapeCdn } from './ShapeCdn';


export interface ShapeStackProps extends StackProps {

}

export class ShapeStack extends Stack {
    public readonly shapeSqSQueue : SqsQueue;
  
    constructor(scope: Construct, id: string, props: ShapeStackProps) {
        super(scope, id);

        const projectName = process.env.PROJECT_NAME;
        if (!projectName) {
            throw new Error("Environement variable PROJECT_NAME is not defined");
        }

        const shape_repo_bucket_name = process.env.S3_SHAPE_REPO;
        if (!shape_repo_bucket_name) {
          throw new Error("Environement variable S3_SHAPE_REPO is not defined");
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

        var shape_repo_bucket = new s3.Bucket(this,
            "S3BUCKET_SHAPE_REPO",  {...s3props,
            bucketName: shape_repo_bucket_name
        });

        /********** SQS QUEUES **********/

        const sqsShapeQueueName : string = projectName + "-shape-messages";
        this.shapeSqSQueue = new SqsQueue(this, "SqsQueue-" + sqsShapeQueueName, { sqsQueueName: sqsShapeQueueName, label: "shape" });

        shape_repo_bucket.addEventNotification(s3.EventType.OBJECT_CREATED,
            new s3n.SqsDestination(this.shapeSqSQueue.sqsQueue),
            {prefix: 'latest/', suffix: '.json'});


        /********** CLOUDFRONT **********/
      
        var shapeCdn = new ShapeCdn(this, "ShapeCdn", {
            shape_web_bucket_name: shape_repo_bucket_name,
            shape_web_bucket: shape_repo_bucket
        });

        /********** LAMBDA **********/

        const lambdaExecutionRole = new iam.Role(this, 'LambdaExecutionRole2', {
            assumedBy: new iam.CompositePrincipal(
                new iam.ServicePrincipal('lambda.amazonaws.com'),
            ),
        });
        
        lambdaExecutionRole.addToPolicy(
            new iam.PolicyStatement({
                resources: [`arn:aws:logs:${Stack.of(this).region}:${Stack.of(this).account}:*`],
                actions: [
                    'logs:CreateLogGroup'
                ],
            })
        );

        lambdaExecutionRole.addToPolicy(
            new iam.PolicyStatement({
                resources: [`arn:aws:logs:${Stack.of(this).region}:${Stack.of(this).account}:*:*`],
                actions: [
                    'logs:CreateLogStream',
                    'logs:PutLogEvents',
                ],
            })
        );

        var arp = new iam.AccountRootPrincipal();
        var s3actions = ['s3:GetObject', 's3:PutObject', 's3:GetObjectVersion'];
        var s3res = [shape_repo_bucket.bucketArn, shape_repo_bucket.arnForObjects('*')];
    
        var ps = new iam.PolicyStatement({
            actions: s3actions,
            resources: s3res,
            principals: [arp, lambdaExecutionRole]
        });
        shape_repo_bucket.policy?.document.addStatements(ps);
        shape_repo_bucket.addToResourcePolicy(ps);
    
        lambdaExecutionRole.addToPolicy(new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: s3actions,
          resources: s3res
        }));

        var lambdaLayer = new lambda.LayerVersion (this, "LambdaLayerSubmitShape", {
            compatibleRuntimes: [
              lambda.Runtime.NODEJS_16_X,
            ],
            code: lambda.Code.fromAsset(`${__dirname}/../tmp/lambda-layers/aws-sdk-client-layer.zip`)
          });

        const uploadShapeFunction = new lambda.Function(this, 'UploadShapeFunction', {
            runtime: lambda.Runtime.NODEJS_16_X,
            handler: 'index.handler',
            code: lambda.Code.fromAsset(`${__dirname}/lambda-handlers/upload-shape`),
            architecture: lambda.Architecture.ARM_64,
            layers: [ lambdaLayer ],
            timeout: Duration.seconds(3), // Below 0.5 second
        });

        const shapeSubmittedFunction = new lambda.Function(this, 'ShapeSubmittedFunction', {
            runtime: lambda.Runtime.NODEJS_16_X,
            handler: 'index.handler',
            code: lambda.Code.fromAsset(`${__dirname}/lambda-handlers/submitted-shape`),
            architecture: lambda.Architecture.ARM_64,
            layers: [ lambdaLayer ],
            role: lambdaExecutionRole,
            timeout: Duration.seconds(5), // Below 2 seconds
        });

        const httpApi = new HttpApi(this, 'ShapesHttpApi');
        // TODO: Set timeout to 3 seconds on integrations instead of 30 seconds
        // The number of milliseconds that API Gateway should wait for a response from the integration before timing out.
        const uploadShapeIntegration = new HttpLambdaIntegration('UploadShapeIntegration', uploadShapeFunction);
        const shapeSubmittedIntegration = new HttpLambdaIntegration('ShapeSubmittedIntegration', shapeSubmittedFunction);

        httpApi.addRoutes({
            path: '/upload-shape',
            methods: [ HttpMethod.GET ],
            integration: uploadShapeIntegration,
        });

        httpApi.addRoutes({
            path: '/upload-shape',
            methods: [ HttpMethod.POST ],
            integration: shapeSubmittedIntegration,
        });

    }
}
