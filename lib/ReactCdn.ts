import { CfnOutput, Duration } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cdn from 'aws-cdk-lib/aws-cloudfront';
import * as cfo from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';

export interface ReactCdnProps {
  readonly object_store_bucket_name: string,
  readonly react_web_bucket_name: string,
  readonly object_store_bucket: s3.IBucket;
  readonly react_web_bucket: s3.IBucket;
}

export class ReactCdn extends Construct {

  readonly distribution : cdn.Distribution;

  constructor(scope: Construct, id: string, props: ReactCdnProps) {
    super(scope, id);

    const awsRegionValue = process.env.AWS_REGION_VALUE;
    if (!awsRegionValue) {
      throw new Error("Environement variable AWS_REGION_VALUE is not defined");
    }
    
    // Creates a distribution from an S3 bucket.
    const errorPagePath = "/error.html";
    const errorMinTtl = Duration.seconds(300);

    this.distribution = new cdn.Distribution(this, 's3ReactDist', {
        defaultBehavior: {
            origin: new cfo.S3Origin(props.react_web_bucket), // s3origin,
            viewerProtocolPolicy: cdn.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
            allowedMethods: cdn.AllowedMethods.ALLOW_GET_HEAD,
            cachedMethods: cdn.CachedMethods.CACHE_GET_HEAD,
            cachePolicy: cdn.CachePolicy.CACHING_OPTIMIZED,
            compress: false
        },
        comment: "LaFleet React Website",
        defaultRootObject: "index.html",
        httpVersion: cdn.HttpVersion.HTTP2,
        minimumProtocolVersion: cdn.SecurityPolicyProtocol.TLS_V1_2_2021,
        errorResponses: [
            {
                httpStatus: 400,
                responseHttpStatus: 400,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 403,
                responseHttpStatus: 403,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 404,
                responseHttpStatus: 404,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 405,
                responseHttpStatus: 405,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 414,
                responseHttpStatus: 414,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 416,
                responseHttpStatus: 416,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 500,
                responseHttpStatus: 500,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 501,
                responseHttpStatus: 501,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 502,
                responseHttpStatus: 502,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 503,
                responseHttpStatus: 503,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            },
            {
                httpStatus: 504,
                responseHttpStatus: 504,
                responsePagePath: errorPagePath,
                ttl: errorMinTtl
            }
        ]
    });


    const cdnDistIdOutput = new CfnOutput(this, "ReactCloudFrontDistributionId", {
        value: this.distribution.distributionId,
        description: '',
        exportName: 'React-CloudFront-DistributionId',
    });

    const cdnDistDomainNameOutput = new CfnOutput(this, "ReactCloudFrontDistributionDomainName", {
        value: this.distribution.distributionDomainName,
        description: '',
        exportName: 'React-CloudFront-DomainName',
    });
  }
}
