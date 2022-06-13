
import { IoTClient, CreateKeysAndCertificateCommand } from "@aws-sdk/client-iot";
import { S3Client, ListObjectsV2Command, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
//import { STSClient, GetCallerIdentityCommand } from "@aws-sdk/client-sts";
const https = require('https');
const fs = require('fs');


const THING_TXT_FILENAME = "certificate-id.txt";
const THING_CRT_FILENAME = "certificate.pem.crt";
const THING_PUB_FILENAME = "public.pem.key";
const THING_PRV_FILENAME = "private.pem.key";
const THING_RCA_FILENAME = "root-ca.crt";
const AWS_RCA_URL = "https://www.amazontrust.com/repository/AmazonRootCA1.pem";

async function downloadFile (url : string, dest : string, cb : Function) {

  return new Promise((resolve, reject) => {

      const file = fs.createWriteStream(dest);

      const request = https.get(url, (response : any) => {
          // check if response is success
          if (response.statusCode !== 200) {
              return reject('Response status was ' + response.statusCode);
          }
    
          response.pipe(file);
      });
    
      // close() is async, call cb after close completes
      file.on('finish', () => {
           file.close(cb("Finished writting file " + file.path));
           resolve("File written");
      });
    
      request.on('error', (err : any) => {
          // delete the (partial) file and then return the error
          fs.unlink(dest, () => cb(err.message));
          reject("Request error");
      });
    
      file.on('error', (err : any) => {
          // delete the (partial) file and then return the error
          fs.unlink(dest, () => cb(err.message));
          reject("File error");
      });
})};

async function writeFile (filename : string, content : string) {
  return new Promise((resolve, reject) => {
      fs.writeFile(filename, content, function(err : any) {
        if (err) {
          reject(err);
        } else {
          resolve("Success");
        }
    });
})};

function readFile(filename : string, enc : any){
  return new Promise(function (fulfill, reject){
    fs.readFile(filename, enc, function (err : any, res : any){
      if (err) reject(err);
      else fulfill(res);
    });
  });
}

async function getObjectContent(bucketName: string, key: string) {

  const streamToString = (stream : any) =>
  new Promise((resolve, reject) => {
      const chunks : any = [];
      stream.on("data", (chunk : any) => chunks.push(chunk));
      stream.on("error", reject);
      stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    });

  var input = {Bucket: bucketName, Key: key};
  const client = new S3Client();
  const command = new GetObjectCommand(input);
  const response = await client.send(command);

  const body = await streamToString(response.Body);
  console.log(body);
  return body;
}

async function putObjectFromContent(bucketName: string, key: string, body: string) {
  var input = {Bucket: bucketName, Key: key, Body: body};
  const client = new S3Client();
  const command = new PutObjectCommand(input);

  try {
    const response = await client.send(command);
    console.log("Successfully uploaded object: " + bucketName + "/" + key);
    return response;
  } catch (err) {
    console.log("Error", err);
  }
};

async function putObjectFromFile(bucketName: string, key: string, file: string) {
  const fileStream = fs.createReadStream(file);

  var input = {Bucket: bucketName, Key: key, Body: fileStream};
  const client = new S3Client();
  const command = new PutObjectCommand(input);

  try {
    const response = await client.send(command);
    console.log("Successfully uploaded object: " + bucketName + "/" + key);
    return response;
  } catch (err) {
    console.log("Error", err);
  }
};

async function createKeysAndCertificate() {
  console.log("starting slow promise");
  var params = { setAsActive: true };

  const client = new IoTClient();
  const command = new CreateKeysAndCertificateCommand(params);
  const response = await client.send(command);
  console.log(response);
  return response;
}

async function listBucketFiles (bucketName: string, prefix: string) {
  const client = new S3Client();
  const command = new ListObjectsV2Command({Bucket: bucketName, Prefix: prefix});
  const response = await client.send(command);
  console.log(response);
  return response;
}

async function read(bucketName: string, accountId: string, region: string) {
  const keyName = "certs/certificate-id.txt";

  var lst = await listBucketFiles(bucketName, keyName);
  var cnt = parseInt(lst.MaxKeys);
  var certExists = false;
  console.log("certExists = false");
  if (lst.Contents === undefined) {
    console.log("lst.Contents === undefined");
  } else if (cnt > 0) {
    for (var i=0; i < cnt; i++) {
      try {
        console.log("File["+i+"]:" + lst.Contents[i].Key);
        certExists = true;
        console.log("certExists = true");
        break;
      } catch (e) {
        console.log("catched:" + e);
      }
    } 
  } else {
    console.log("cnt == 0");
  }

  if (certExists) {
    var certificateId = await getObjectContent(bucketName, keyName);
    console.log("Content: " + certificateId);

    const certificateArn = `arn:aws:iot:${region}:${accountId}:cert/${certificateId}`;
    return {certificateArn: certificateArn, certificateId: certificateId};
  } else {
    console.log("Certificate not found");
    return undefined;
  }
}

async function create(bucketName: string, accountId: string, region: string) {

  var cb = (msg : any) => { console.log("Callback called: " + msg)};
  await downloadFile(AWS_RCA_URL, "/tmp/" + THING_RCA_FILENAME, cb);
  console.log("AWS RCA downloaded");

  var kac = await createKeysAndCertificate();
  // CreateKeysAndCertificateCommandOutput
  await writeFile("/tmp/" + THING_TXT_FILENAME, kac.certificateId);
  await writeFile("/tmp/" + THING_CRT_FILENAME, kac.certificatePem);
  await writeFile("/tmp/" + THING_PUB_FILENAME, kac.keyPair.PublicKey);
  await writeFile("/tmp/" + THING_PRV_FILENAME, kac.keyPair.PrivateKey);


  await putObjectFromFile(bucketName, "certs/" + THING_TXT_FILENAME, "/tmp/" + THING_TXT_FILENAME);
  await putObjectFromFile(bucketName, "certs/" + THING_CRT_FILENAME, "/tmp/" + THING_CRT_FILENAME);
  await putObjectFromFile(bucketName, "certs/" + THING_PUB_FILENAME, "/tmp/" + THING_PUB_FILENAME);
  await putObjectFromFile(bucketName, "certs/" + THING_PRV_FILENAME, "/tmp/" + THING_PRV_FILENAME);
  await putObjectFromFile(bucketName, "certs/" + THING_RCA_FILENAME, "/tmp/" + THING_RCA_FILENAME);

  const certificateArn = `arn:aws:iot:${region}:${accountId}:cert/${kac.certificateId}`;
  return {certificateArn: certificateArn, certificateId: kac.certificateId};
}

async function get(bucketName: string, accountId: string, region: string) {
  const data = await read(bucketName, accountId, region);
  if (data === undefined) {
    return create(bucketName, accountId, region);
  } else {
    return data;
  }
}

exports.handler = async function(event : any, context : any) {
  console.log("Starting function");
  const id = event.PhysicalResourceId; // only for "Update" and "Delete"
  const props = event.ResourceProperties;
  const oldProps = event.OldResourceProperties; // only for "Update"

  console.log("JSON.stringify(event) -->> \n" + JSON.stringify(event));
  console.log("JSON.stringify(context) -->> \n" + JSON.stringify(context));

  var bucketName = process.env.object_store_bucket_name!;
  var accountId = process.env.accountId!;
  var region = process.env.region!;
  var thingName = process.env.thingName!;
  console.log(`accountId: ${accountId}, region: ${region}, bucketName: ${bucketName}, thingName: ${thingName}`);

  try {
    if (event.RequestType === 'Create') {
      const { certificateArn, certificateId } = await get(bucketName, accountId, region);
      return {
        Status: 'SUCCESS',
        PhysicalResourceId: certificateArn,
        LogicalResourceId: event.LogicalResourceId,
        RequestId: event.RequestId,
        StackId: event.StackId,
        Data: {
          certificateArn: certificateArn,
          certificateId: certificateId
        },
      };
    } else if (event.RequestType === 'Delete') {
      //await thingHandler.delete(thingName);
      const { certificateArn, certificateId } = await get(bucketName, accountId, region);
      console.log(`Deleting thing`);
      return {
        Status: 'SUCCESS',
        PhysicalResourceId: event.PhysicalResourceId,
        LogicalResourceId: event.LogicalResourceId,
        RequestId: event.RequestId,
        StackId: event.StackId,
        Data: {
          certificateArn: certificateArn,
          certificateId: certificateId
        },
      };
    } else if (event.RequestType === 'Update') {
      const { certificateArn, certificateId } = await get(bucketName, accountId, region);
      //console.log(`Updating thing: ${thingName}`);
      console.log(`Updating thing`);
      return {
        Status: 'SUCCESS',
        PhysicalResourceId: event.PhysicalResourceId,
        LogicalResourceId: event.LogicalResourceId,
        RequestId: event.RequestId,
        StackId: event.StackId,
        Data: {
          certificateArn: certificateArn,
          certificateId: certificateId
        },
      };
    } else {
      throw new Error('Received invalid request type');
    }
  } catch (err : any) {
    return {
      Status: 'FAILED',
      Reason: err.message,
      RequestId: event.RequestId,
      StackId: event.StackId,
      LogicalResourceId: event.LogicalResourceId,
      // @ts-ignore
      PhysicalResourceId: event.PhysicalResourceId || event.LogicalResourceId,
      Data: {
        certificateArn: "",
        certificateId: ""
      },
    };
  }
}