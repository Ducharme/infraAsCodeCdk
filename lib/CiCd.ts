import { Duration, RemovalPolicy, Stack } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cc from 'aws-cdk-lib/aws-codecommit';
import * as cb from 'aws-cdk-lib/aws-codebuild';
import * as cp from 'aws-cdk-lib/aws-codepipeline';
import * as cpa from 'aws-cdk-lib/aws-codepipeline-actions';
import * as cps from 'aws-cdk-lib/pipelines';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';


export interface CiCdProps {
  readonly repoName: string;
  readonly repoDescription: string;
  readonly registryRepoName: string | undefined,
  //readonly repoUrl: string;
  readonly repoCodeFolder : string;
  readonly sourceVersionBranchName: string;
  readonly object_store_bucket_name: string;
  readonly codebuild_artifact_bucket_name: string;
  readonly codepipeline_artifact_bucket_name: string;
}

export class CiCd extends Construct {
  public readonly repoName: string;
  public readonly repoDescription: string;
  public readonly sourceVersionBranchName: string;
  public readonly ecrRepo: ecr.Repository | undefined;
  public readonly codeCommitRepo: cc.Repository;
  public readonly codeBuildProject: cb.Project;
  public readonly codePipeline: cp.Pipeline;

  constructor(scope: Construct, id: string, props: CiCdProps) {
    super(scope, id);

    this.repoName = props.repoName;
    this.repoDescription = props.repoDescription;
    const projectName = process.env.PROJECT_NAME;
    if (!projectName) {
      //throw new Error("Environement variable PROJECT_NAME is not defined");
      console.log("Environement variable PROJECT_NAME is not defined");
    }

    if (props.registryRepoName !== undefined) {
      this.ecrRepo = new ecr.Repository(this, 'ElasticContainerRegistry::' + this.repoName, {
        repositoryName: props.registryRepoName,
        encryption: ecr.RepositoryEncryption.AES_256,
        imageTagMutability: ecr.TagMutability.MUTABLE,
        imageScanOnPush: false,
        removalPolicy: RemovalPolicy.DESTROY // TODO: Generates error -> cannot be deleted because it still contains images
      });
    }

    this.codeCommitRepo = new cc.Repository(this, 'CodeCommit::' + this.repoName, {
      repositoryName: this.repoName,
      description: this.repoDescription,
      code : cc.Code.fromDirectory(props.repoCodeFolder),
    });

    const imported_codebuild_artifact_bucket = s3.Bucket.fromBucketName(this,
      'imported-codebuild_artifact_bucket::' + this.repoName,
      props.codebuild_artifact_bucket_name
    );
    const imported_object_store_bucket = s3.Bucket.fromBucketName(this,
      'imported-object_store_bucket::' + this.repoName,
      props.object_store_bucket_name
    );

    var imageRepoName = props.registryRepoName === undefined ? this.repoName : props.registryRepoName;

    const logGroupName = `/${projectName}/codebuild/${this.repoName}`;
    const logGroup = new logs.LogGroup(this, logGroupName, {
      logGroupName: logGroupName,
      removalPolicy: RemovalPolicy.DESTROY,
      retention: logs.RetentionDays.ONE_WEEK,
    });

    this.codeBuildProject = new cb.Project(this, 'CodeBuild::' +  this.repoName, {
      projectName: this.repoName,
      description: this.repoDescription,
      source: cb.Source.codeCommit({
        repository: this.codeCommitRepo,
        branchOrRef: this.sourceVersionBranchName,
        cloneDepth: 1
      }),
      // https://github.com/aws/aws-cdk/issues/11116
      // [module] codebuild.Cache.none() should resolve to NO_CACHE instead of undefined
      // https://docs.aws.amazon.com/cdk/api/v2/docs/aws-cdk-lib.aws_codebuild.Cache.html
      cache: cb.Cache.none(), // { type: 'NO_CACHE' }
      environment: {
        buildImage: cb.LinuxBuildImage.STANDARD_5_0,
        computeType: cb.ComputeType.SMALL,
        privileged: true,
      },
      environmentVariables:  {
        AWS_DEFAULT_REGION: { value: Stack.of(this).region },
        AWS_ACCOUNT_ID: { value: Stack.of(this).account },
        IMAGE_REPO_NAME: { value: imageRepoName },
        IMAGE_TAG: { value: "latest" },
        S3_OBJECT_STORE: { value: props.object_store_bucket_name },
      },
      buildSpec: cb.BuildSpec.fromSourceFilename("buildspec.yml"),
      artifacts: cb.Artifacts.s3({
        bucket: imported_codebuild_artifact_bucket,
        //includeBuildId: true,
        packageZip: true,
        path: this.repoName,
        name: this.repoName,
        encryption: true
      }),
      logging: {
        cloudWatch: {
          logGroup: logGroup,
        }
      },
      timeout: Duration.minutes(15),
      queuedTimeout: Duration.minutes(30),
      concurrentBuildLimit: 5,
    });

    if (this.ecrRepo !== undefined) {
      this.ecrRepo.grantPullPush(this.codeBuildProject);
    }
    imported_object_store_bucket.grantRead(this.codeBuildProject);


    const source = cps.CodePipelineSource.codeCommit(this.codeCommitRepo, props.sourceVersionBranchName);

    const imported_codepipeline_artifact_bucket = s3.Bucket.fromBucketName(this,
      'imported-codepipeline_artifact_bucket:: ' + this.repoName,
      props.codepipeline_artifact_bucket_name
    );

    const sourceOutput = new cp.Artifact();
    const sourceAction = new cpa.CodeCommitSourceAction({
      actionName: 'CodeCommit',
      repository: this.codeCommitRepo,
      output: sourceOutput,
      branch: props.sourceVersionBranchName,
      trigger: cpa.CodeCommitTrigger.POLL,
    });

    const buildOutput = new cp.Artifact();
    const buildAction = new cpa.CodeBuildAction({
      actionName: 'CodeBuild',
      project: this.codeBuildProject,
      input: sourceOutput,
      outputs: [buildOutput], // optional
      variablesNamespace: "BuildVariables"
    });

    const deployAction = new cpa.S3DeployAction({
      actionName: 'CodeDeploy',
      bucket: imported_codepipeline_artifact_bucket,
      input: buildOutput,
      extract: false,
      objectKey: this.repoName + "-codepipeline.zip",
      variablesNamespace: "DeployVariables"
    });

    this.codePipeline = new cp.Pipeline(scope, 'CodePipeline::' + this.repoName, {
      pipelineName: this.repoName,
      artifactBucket: imported_codepipeline_artifact_bucket,
      //role: CODEPIPELINE_ARN
      stages: [
        {stageName: 'One-Source', actions: [sourceAction]},
        {stageName: 'Two-Build', actions: [buildAction]},
        {stageName: 'Three-Copy', actions: [deployAction]},
      ]
    });

  }
}
