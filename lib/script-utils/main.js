import { CloudFormationClient, ListExportsCommand } from "@aws-sdk/client-cloudformation"; // ES Modules import
import { S3Client, PutObjectCommand, GetBucketPolicyCommand, PutBucketPolicyCommand } from "@aws-sdk/client-s3";
import { exit } from "process";
import * as fs from "fs";

const awsRegion = process.env.AWS_REGION_VALUE;
const shapeRepo = process.env.S3_SHAPE_REPO;
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
    const line2=`STREAMING_LOCATION_TOPIC=${iotTopic}`;
    const line3=`STREAMID_REQUEST_TOPIC=${iotTopic}`;
    const line4=`STREAMID_REPLY_TOPIC=${iotTopic}`;
    const line5=`INTERVAL=1000`;
    const line6=`COUNT=0`;
    const line7=`CA_FILE=./certs/root-ca.crt`;
    const line8=`CERT_FILE=./certs/certificate.pem.crt`;
    const line9=`KEY_FILE=./certs/private.pem.key`;
    const content = `${line1}\n${line2}\n${line3}\n${line4}\n\n${line5}\n${line6}\n${line7}\n${line8}\n${line9}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_iotServer() {
    const sourceCodeRepoName = "iotServer";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const iotEndpoint = getValue(exportedValues.Exports, "Iot-EndpointAddress");
    const iotTopic = getValue(exportedValues.Exports, "Iot-ThingTopic");

    const line1=`ENDPOINT=${iotEndpoint}`;
    const line2=`STREAMID_REQUEST_TOPIC=${iotTopic}`;
    const line3=`STREAMID_REPLY_TOPIC=${iotTopic}`;
    const line4=`CA_FILE=./certs/root-ca.crt`;
    const line5=`CERT_FILE=./certs/certificate.pem.crt`;
    const line6=`KEY_FILE=./certs/private.pem.key`;
    const content = `${line1}\n${line2}\n${line3}\n${line4}\n\n${line5}\n${line6}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_shape() {
    const scriptFile = process.argv[1];
    const lio = scriptFile.lastIndexOf("/");
    const scriptDir = scriptFile.substring(0, lio); // Does not end with "/"

    const shapeBucketName = getValue(exportedValues.Exports, "S3ShapeRepoBucketName");
    const newUrl = getValue(exportedValues.Exports, "ApiGw-UploadShapeLink");
    const content = fs.readFileSync(scriptDir + '/shape/index.html', {encoding:'utf8', flag:'r'});
    const newpage = content.replaceAll("NEW_URL", newUrl);
    uploadFileToS3(newpage, shapeBucketName, "index.html");

    const error = fs.readFileSync(scriptDir + '/shape/error.html', {encoding:'utf8', flag:'r'});
    uploadFileToS3(error, shapeBucketName, "error.html");

    handler_addGetObjectVersionToShapeS3Policy();
}

function handler_sqsDeviceConsumerToRedisearch() {
    const sourceCodeRepoName = "sqsDeviceConsumerToRedisearch";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const sqsQueueUrl = getValue(exportedValues.Exports, "SqsQueueUrl-device");

    const line1=`REDIS_HOST=redisearch-service`;
    const line2=`AWS_REGION=${awsRegion}`;
    const line3=`SQS_QUEUE_URL=${sqsQueueUrl}`;
    const content = `${line1}\n${line2}\n${line3}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_sqsShapeConsumerToRedisearch() {
    const sourceCodeRepoName = "sqsShapeConsumerToRedisearch";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const sqsQueueUrl = getValue(exportedValues.Exports, "SqsQueueUrl-shape");

    const line1=`REDIS_HOST=redisearch-service`;
    const line2=`AWS_REGION=${awsRegion}`;
    const line3=`SQS_QUEUE_URL=${sqsQueueUrl}`;
    const content = `${line1}\n${line2}\n${line3}`;
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
    const sourceCodeRepoName = "redisearchQueryClient";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");

    const line1="REDIS_HOST=redisearch-service";
    const line2="REDIS_PORT=6379";
    const content = `${line1}\n${line2}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

function handler_reactFrontend() {
    const sourceCodeRepoName = "reactFrontend";
    const objectKey = `config/${sourceCodeRepoName}/${EnvCfgFilename}`;
    const objectBucketName = getValue(exportedValues.Exports, "S3ObjectStoreBucketName");
    const reactBucketName = getValue(exportedValues.Exports, "S3ReactWebBucketName");
    const domainName = getValue(exportedValues.Exports, "React-CloudFront-DomainName");
    const distId = getValue(exportedValues.Exports, "React-CloudFront-DistributionId");

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
    const line3=`REACT_CDN=https://${domainName}.cloudfront.net/query`;
    const line4=`SHAPES_CDN=https://${domainName}.cloudfront.net/shapes`;
    const line5=`MAPBOX_TOKEN=${mapbox_token}`;
    const line6=`MAPBOX_STYLE_LIGHT=mapbox://styles/mapbox/light-v9`;
    const line7=`MAPBOX_STYLE_BASIC=mapbox://styles/mapbox/basic-v9`;
    const content = `${line1}\n${line2}\n${line3}\n\n${line4}\n${line5}\n${line6}\n${line7}`;
    uploadFileToS3(content, objectBucketName, objectKey);
    return true;
}

const handler_addGetObjectVersionToShapeS3Policy = async () => {

    const s3client = new S3Client({ region: awsRegion })
    var getPolCmd = new GetBucketPolicyCommand({Bucket: shapeRepo});
    const resGetPol = await s3client.send(getPolCmd);

    if (resGetPol.$metadata.httpStatusCode != 200)
        throw `GetBucketPolicy httpStatusCode is ${resGetPol.$metadata.httpStatusCode}, exiting`;
    if (resGetPol.Policy === undefined)
        throw `Bucket policy is undefined, exiting`;


    var changed = false;
    var policy = JSON.parse(resGetPol.Policy);
    for (var i=0; i < policy.Statement.length; i++) {
        if (policy.Statement[i].Effect != "Allow")
            continue;

        if (policy.Statement[i].Action != "s3:GetObject")
            continue;
        
        if (policy.Statement[i].Resource != `arn:aws:s3:::${shapeRepo}/*`)
            continue;
        
        policy.Statement[i].Action = ["s3:GetObject", "s3:GetObjectVersion"];
        changed = true;
    }
    console.log("Policy changed: " + changed);

    if (changed) {
        var policyStr = JSON.stringify(policy);
        var putPolCmd = new PutBucketPolicyCommand({Bucket: shapeRepo, Policy: policyStr});
        const resPutPol = await s3client.send(putPolCmd);
        console.log(resPutPol);
    }
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
            case "iotServer":
                handler_iotServer();
                break;
            case "shape":
                handler_shape();
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
