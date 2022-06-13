#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { CommonStack } from '../lib/CommonStack';
import { DeviceStack } from '../lib/DeviceStack';
import { WebsiteStack } from '../lib/WebsiteStack';
import { ConsumerStack } from '../lib/ConsumerStack';
import { QueryStack } from '../lib/QueryStack';
import { AnalyticsStack } from '../lib/AnalyticsStack';

const app = new cdk.App();


const commonStack = new CommonStack(app, 'LaFleet-CommonStack', {});

const deviceStack = new DeviceStack(app, 'LaFleet-DeviceStack', {
    repoCodeFolder: "./tmp/github/mockIotGpsDeviceAwsSdkV2-main",
    sqsQueueRoleArn: commonStack.sqsQueueRole.roleArn,
    sqsQueueUrl: commonStack.sqsQueue.queueUrl
});

const consumerStack = new ConsumerStack(app, 'LaFleet-ConsumerStack', {
    repoCodeFolder: "./tmp/github/sqsConsumerToRedisearchJs-main"
});

const queryStack = new QueryStack(app, 'LaFleet-QueryStack', {
    repoCodeFolder: "./tmp/github/redisearchQueryClient-main"
});

const analyticsStack = new AnalyticsStack(app, 'LaFleet-AnalyticsStack', {
    repoCodeFolder: "./tmp/github/redisPerformanceAnalyticsPy-main"
});

const websiteStack = new WebsiteStack(app, 'LaFleet-WebsiteStack', {
    repoCodeFolder: "./tmp/github/reactFrontend-main"
});
