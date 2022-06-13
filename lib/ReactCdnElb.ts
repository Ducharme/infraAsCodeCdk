import * as cdn from 'aws-cdk-lib/aws-cloudfront';
import * as cfo from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';


export interface ReactCdnElbProps {
  readonly cdn_distribution: cdn.Distribution;
}

export class ReactCdnElb extends Construct {

  constructor(scope: Construct, id: string, props: ReactCdnElbProps) {
    super(scope, id);

    const elb_dns_name = process.env.ELB_DNS_NAME;
    if (!elb_dns_name) {
        throw new Error("Environment variable ELB_DNS_NAME is not defined");
    } else if (elb_dns_name == "NOT_READY") {
      //throw new Error("Environment variable ELB_DNS_NAME is not ready yet");
      console.warn("SKIPPING ELB RELATED BEHAVIORS ON WEBSITE. Environment variable ELB_DNS_NAME is not ready yet");
    }

    console.log("ELB_DNS_NAME: " + elb_dns_name);
    var httpOrigin = new cfo.HttpOrigin(elb_dns_name, {
        protocolPolicy: cdn.OriginProtocolPolicy.HTTP_ONLY,
        httpPort: 80
    });

    props.cdn_distribution.addBehavior("/query/*",  httpOrigin, {
        compress: false,
        viewerProtocolPolicy: cdn.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cdn.AllowedMethods.ALLOW_ALL,
        cachedMethods: cdn.CachedMethods.CACHE_GET_HEAD,
        cachePolicy: cdn.CachePolicy.CACHING_DISABLED,
        originRequestPolicy: cdn.OriginRequestPolicy.ALL_VIEWER,
        responseHeadersPolicy: cdn.ResponseHeadersPolicy.CORS_ALLOW_ALL_ORIGINS_WITH_PREFLIGHT_AND_SECURITY_HEADERS
    });

    props.cdn_distribution.addBehavior("/analytics/*",  httpOrigin, {
        compress: false,
        viewerProtocolPolicy: cdn.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cdn.AllowedMethods.ALLOW_ALL,
        cachedMethods: cdn.CachedMethods.CACHE_GET_HEAD,
        cachePolicy: cdn.CachePolicy.CACHING_DISABLED,
        originRequestPolicy: cdn.OriginRequestPolicy.ALL_VIEWER,
        responseHeadersPolicy: undefined
    });

  }
}
