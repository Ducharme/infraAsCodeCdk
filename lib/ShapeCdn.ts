import { CfnOutput } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cdn from 'aws-cdk-lib/aws-cloudfront';
import * as cfo from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';

export interface ShapeCdnProps {
  readonly shape_web_bucket_name: string,
  readonly shape_web_bucket: s3.IBucket;
}

export class ShapeCdn extends Construct {

  readonly distribution : cdn.Distribution;

  constructor(scope: Construct, id: string, props: ShapeCdnProps) {
    super(scope, id);

    const awsRegionValue = process.env.AWS_REGION_VALUE;
    if (!awsRegionValue) {
      throw new Error("Environement variable AWS_REGION_VALUE is not defined");
    }
    
    // Creates a distribution from an S3 bucket.
    const shapeCachePolicy = new cdn.CachePolicy(this, 'ShapeCachePolicy', {
        queryStringBehavior: cdn.CacheQueryStringBehavior.allowList('versionId')
    });

    this.distribution = new cdn.Distribution(this, 's3ShapeDist', {
        defaultBehavior: {
            origin: new cfo.S3Origin(props.shape_web_bucket), // s3origin,
            viewerProtocolPolicy: cdn.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
            allowedMethods: cdn.AllowedMethods.ALLOW_GET_HEAD,
            cachedMethods: cdn.CachedMethods.CACHE_GET_HEAD,
            cachePolicy: shapeCachePolicy,
            compress: false
        },
        comment: "LaFleet Shape Cache",
        httpVersion: cdn.HttpVersion.HTTP2,
        minimumProtocolVersion: cdn.SecurityPolicyProtocol.TLS_V1_2_2021,
    });

    const cdnDistIdOutput = new CfnOutput(this, "ShapeCloudFrontDistributionId", {
        value: this.distribution.distributionId,
        description: '',
        exportName: 'Shape-CloudFront-DistributionId',
    });

    const cdnDistDomainNameOutput = new CfnOutput(this, "ShapeCloudFrontDistributionDomainName", {
        value: this.distribution.distributionDomainName,
        description: '',
        exportName: 'Shape-CloudFront-DomainName',
    });
  }
}
