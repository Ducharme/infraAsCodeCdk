import { CloudFormationClient, ListExportsCommand } from "@aws-sdk/client-cloudformation"; // ES Modules import
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { exit } from "process";
import * as fs from "fs";

const awsRegion = process.env.AWS_REGION_VALUE;
const config = { region: awsRegion };
const EnvCfgFilename=".env.production";
const exportedValues = await getExportedValues();

function getValue(json, exportName) {
    if (!json || !exportName)
        return undefined;
    
    var element = json.find(item => {return item.Name == exportName});
    if (!element)
        return undefined;
    
    return element.Value;
}

async function getExportedValues () {
    const input = { NextToken: undefined };
    const client = new CloudFormationClient(config);
    const command = new ListExportsCommand(input);
    const response = await client.send(command);
    //console.log(response);
    return response;
}

async function uploadFileToS3(content, bucketName, objectKey) {
    const client = new S3Client(config);
    const input = {Body: content,
        Bucket: bucketName,
        Key: objectKey
    };
    const command = new PutObjectCommand(input);
    const response = await client.send(command);
    const sc = response.$metadata.httpStatusCode;
    return sc >= 200 && sc < 300;
}

function handler_mockIotGpsDeviceAwsSdkV2() {
    const sourceCodeRepoName = "mockIotGpsDeviceAwsSdkV2";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const iotEndpoint = getValue(exportedValues.Exports, "Iot-EndpointAddress");
    const iotTopic = getValue(exportedValues.Exports, "Iot-ThingTopic");

    const line1=`ENDPOINT=${iotEndpoint}`;
    const line2=`TOPIC=${iotTopic}`;
    const line3=`INTERVAL=1000`;
    const line4=`COUNT=0`;
    const line5=`CA_FILE=./certs/root-ca.crt`;
    const line6=`CERT_FILE=./certs/certificate.pem.crt`;
    const line7=`KEY_FILE=./certs/private.pem.key`;
    const content = `${line1}\n${line2}\n${line3}\n${line4}\n\n${line5}\n${line6}\n${line7}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_sqsDeviceConsumerToRedisearch() {
    const sourceCodeRepoName = "sqsDeviceConsumerToRedisearch";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const sqsQueueUrl = getValue(exportedValues.Exports, "SqsQueueUrl-device");
    const iotTopic = getValue(exportedValues.Exports, "Iot-ThingTopic");

    const line1=`REDIS_HOST=redisearch-service`;
    const line2=`AWS_REGION=${awsRegion}`;
    const line3=`SQS_QUEUE_URL=${sqsQueueUrl}`;
    const line4=`TOPIC=${iotTopic}`;
    const content = `${line1}\n${line2}\n${line3}\n${line4}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_sqsShapeConsumerToRedisearch() {
    const sourceCodeRepoName = "sqsShapeConsumerToRedisearch";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const sqsQueueUrl = getValue(exportedValues.Exports, "SqsQueueUrl-shape");
    const iotTopic = getValue(exportedValues.Exports, "Iot-ThingTopic");

    const line1=`REDIS_HOST=redisearch-service`;
    const line2=`AWS_REGION=${awsRegion}`;
    const line3=`SQS_QUEUE_URL=${sqsQueueUrl}`;
    const line4=`TOPIC=${iotTopic}`;
    const content = `${line1}\n${line2}\n${line3}\n${line4}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_redisPerformanceAnalyticsPy() {
    const sourceCodeRepoName = "redisPerformanceAnalyticsPy";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");

    const line1="REDIS_HOST=redisearch-service";
    const line2="REDIS_PORT=6379";
    const line3="DEBUG=False";
    const content = `${line1}\n${line2}\n${line3}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_redisearchQueryClient() {
    return true;
}

function handler_reactFrontend() {
    const sourceCodeRepoName = "reactFrontend";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const reactBucketName = getValue(exportedValues.Exports, "S3ReactWebBucketName");
    const domainName = getValue(exportedValues.Exports, "CloudFront-DomainName");
    const distId = getValue(exportedValues.Exports, "CloudFront-DistributionId");

    var str = fs.readFileSync(EnvCfgFilename, 'utf8');
    const lines = str.split(/\r?\n/);
    var matches = lines.filter(e => e.startsWith("MAPBOX_TOKEN="));
    var mapbox_token = "";
    if (matches.length > 0) {
        mapbox_token = matches[0].replace("MAPBOX_TOKEN=", "");
    } else {
        throw new Error("MAPBOX_TOKEN token is missing from " + EnvCfgFilename);
    }

    const line1=`CDN_DIST_ID=${distId}`;
    const line2=`S3_WEB_BUCKET=${reactBucketName}`;
    const line3=`GET_CNT_FCN=https://${domainName}/query/h3/aggregate/device-count`;
    const line4=`MAPBOX_TOKEN=${mapbox_token}`;
    const line5=`MAPBOX_STYLE_LIGHT=mapbox://styles/mapbox/light-v9`;
    const line6=`MAPBOX_STYLE_BASIC=mapbox://styles/mapbox/basic-v9`;
    const content = `${line1}\n${line2}\n${line3}\n\n${line4}\n${line5}\n${line6}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

var args = process.argv.slice(2);
console.log(args);

if (args.length == 0) {
    console.error("Argument specifying the config to generate is missing");
    exit(1);
} else {
    if (!awsRegion) {
        throw new Error("Environement variable AWS_REGION_VALUE is not defined");
    }

    for (var i=0; i < args.length; i++) {
        var arg = args[i];
        switch (arg) {
            case "mockIotGpsDeviceAwsSdkV2":
                handler_mockIotGpsDeviceAwsSdkV2();
                break;
            case "sqsDeviceConsumerToRedisearch":
                handler_sqsDeviceConsumerToRedisearch();
                break;
            case "sqsShapeConsumerToRedisearch":
                handler_sqsShapeConsumerToRedisearch();
                break;
            case "reactFrontend":
                handler_reactFrontend();
                break;
            case "redisearchQueryClient":
                handler_redisearchQueryClient();
                break;
            case "redisPerformanceAnalyticsPy":
                handler_redisPerformanceAnalyticsPy();
                break;
            default:
                console.log(`Argument ${arg} has no matching config`);
                exit(2);
        }
    }
}
