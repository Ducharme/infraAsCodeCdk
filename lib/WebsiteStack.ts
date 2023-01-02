import { CfnOutput, RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import { CiCd } from './CiCd';
import { ReactCdn } from './ReactCdn';
import { ReactCdnElb } from './ReactCdnElb';
import { Construct } from 'constructs';
var fs = require('fs');


export interface WebsiteStackProps extends StackProps {
  readonly repoCodeFolder : string;
}

export class WebsiteStack extends Stack {

  public readonly react_web_bucket: s3.Bucket;

  constructor(scope: Construct, id: string, props: WebsiteStackProps) {
    super(scope, id);

    const awsAccountId : string = Stack.of(this).account;

    const repoName = process.env.REACT_REPO;
    if (!repoName) {
      throw new Error("Environement variable REACT_REPO is not defined");
    }

    const repoDesc = process.env.REACT_DESC;
    if (!repoDesc) {
      throw new Error("Environement variable REACT_DESC is not defined");
    }

    const branchName = process.env.CODEBUILD_BRANCH_NAME;
    if (!branchName) {
      throw new Error("Environement variable CODEBUILD_BRANCH_NAME is not defined");
    }

    const react_web_bucket_name = process.env.S3_REACT_WEB;
    if (!react_web_bucket_name) {
      throw new Error("Environement variable S3_REACT_WEB is not defined");
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

    const s3props = {
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      versioned: true,
      enforceSSL: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      publicReadAccess: false
    };
    this.react_web_bucket = new s3.Bucket(this,
      "S3BUCKET_REACT_WEB", {...s3props,
        bucketName: react_web_bucket_name
    });

    const s3ReactWebBucketNameOutput = new CfnOutput(this, "S3ReactWebBucketName", {
      value: this.react_web_bucket.bucketName,
      description: '',
      exportName: 'S3ReactWebBucketName',
    });

    const imported_object_store_bucket = s3.Bucket.fromBucketName(this,
      'imported-object_store_bucket',
      object_store_bucket_name
    );

    var reactCdn = new ReactCdn(this, "ReactCdn", {
        object_store_bucket_name: object_store_bucket_name,
        react_web_bucket_name: react_web_bucket_name,
        object_store_bucket: imported_object_store_bucket,
        react_web_bucket: this.react_web_bucket
    });

    var fs = new ReactCdnElb(this, "ReactCdnElb", {
        cdn_distribution: reactCdn.distribution
    });

    var cicd = new CiCd(this, "CICD-" + repoName, {
        repoName: repoName,
        repoDescription: repoDesc,
        registryRepoName: undefined,
        repoCodeFolder: props.repoCodeFolder,
        sourceVersionBranchName: branchName,
        object_store_bucket_name: object_store_bucket_name,
        codebuild_artifact_bucket_name: codebuild_artifact_bucket_name,
        codepipeline_artifact_bucket_name: codepipeline_artifact_bucket_name
    });

    this.react_web_bucket.grantReadWrite(cicd.codeBuildProject);
      
    // Add Cloudfront invalidation permissions to the project
    const distributionArn = `arn:aws:cloudfront::${awsAccountId}:distribution/${reactCdn.distribution.distributionId}`;
    const invalidatePolicy = new iam.PolicyStatement({
      resources: [distributionArn],
      actions: ['cloudfront:CreateInvalidation']
    });
    cicd.codeBuildProject.addToRolePolicy(invalidatePolicy);
    cicd.codePipeline.addToRolePolicy(invalidatePolicy);

    // TODO: Might have race condition with s3 env config file replication if build is faster than cdk to copy

  }
}