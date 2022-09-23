/*global atob*/

const { S3Client, PutObjectCommand, GetObjectCommand, ListObjectsV2Command } = require("@aws-sdk/client-s3");


const dateTimeRegex = new RegExp("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}[:][0-9]{2}:[0-9]{2}\.[0-9]{3}Z");
const semVerRegex = new RegExp("^(0|([1-9]*))(\.0|([1-9]*))(\.(0|([1-9]*)))$");
const indexRegex = new RegExp("^[0-9a-z]{15}$");

const validTypes = "PARKING/NOPARKING/LIMIT/NOGO".split('/');
const validStatus = "ACTIVE/INACTIVE/DELETED".split('/');

const undefinedString = "UNDEFINED";
const defaultName = "NAME";

async function uploadFileToS3(config, content, bucketName, objectKey) {
    const client = new S3Client(config);
    const input = {Body: content,
        Bucket: bucketName,
        Key: objectKey
    };
    const command = new PutObjectCommand(input);
    const response = await client.send(command);
    //console.log(response);
    const sc = response.$metadata.httpStatusCode;
    return sc >= 200 && sc < 300;
}

async function getObjectContent(config, bucketName, key) {
  const streamToString = (stream) =>
    new Promise(async(resolve, reject) => {
      try {
        const chunks = [];
        stream.on("data", (chunk) => chunks.push(chunk));
        stream.on("error", reject);
        stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
      } catch (err) {
        console.error(err);
        reject("error");
      }
    }
  );

  const client = new S3Client(config);
  var input = {Bucket: bucketName, Key: key};
  const command = new GetObjectCommand(input);
  const response = await client.send(command);
  if (response.$metadata.httpStatusCode == 200) {
    if (response.Body) {
      const body = await streamToString(response.Body);
      return body;
    } else {
      console.warn(`GetObject did not have body for ${bucketName}/${key}`);
      return undefined;
    }
  } else {
    var str = JSON.stringify(response.$metadata);
    console.warn(`GetObject did not receive 200 for ${bucketName}/${key}. Metadata is ${str}`);
    return undefined;
  }
}

async function listBucket(config, bucketName, prefix) {
  const client = new S3Client(config);
  const input = { Bucket: bucketName, Prefix: prefix, MaxKeys: 10 };
  const command = new ListObjectsV2Command(input);
  const response = await client.send(command);
  //console.log(response);
  const sc = response.$metadata.httpStatusCode;
    if (sc >= 200 && sc < 300) {
      return response.Contents.map(item => item.Key);
    } else {
      return [];
    }
}

function validateVersion (fieldName, fieldValue) {
  if (fieldValue === undefined || fieldValue.length == 0)
    throw `Invalid ` + fieldName;
    
  var tokens = fieldValue.split(".");
  if (tokens.length != 3)
      throw `Invalid ` + fieldName;
  
  var major = parseInt(tokens[0]);
  var minor = parseInt(tokens[1]);
  var build = parseInt(tokens[2]);
  // BUG: RegEx does not behave as expected
  //if (semVerRegex.test(fieldValue))
  //  throw `Invalid ${fieldName} format for ${fieldValue}`;
  return true;
}

function validateDate(fieldName, fieldValue) {
  // 2001-01-01T00:01:02.123
  if (fieldValue === undefined || (fieldValue.length > 0 && fieldValue.length != 23))
    throw `Invalid ` + fieldName;
  if (dateTimeRegex.test(fieldValue))
     throw `Invalid ${fieldName} format`;
  return true;
}

function checkPolygon(fieldName, fieldValue) {
  if (fieldValue === undefined || fieldValue.length < 3)
    throw `Invalid ${fieldName}`;
  for (var i=0; i < fieldValue.length; i++) {
    // latitude, longitude
    var coordinates = fieldValue[i];
    var lat = coordinates[0];
    var lon = coordinates[1];
    if (lat < -90 || lat > 90)
      throw `Invalid latitude ${lat} in ${fieldName} at index ${i}`;
    if (lon < -180 || lon > 180)
      throw `Invalid longitude ${lon} in ${fieldName} at index ${i}`;
  }
}

function checkResolutions(fieldName, fieldValue) {
  if (fieldValue === undefined)
    throw `Invalid ${fieldName}`;
  var keys = Object.keys(fieldValue);
  var counter = 0;
  for (const key of keys) {
    if (!key.startsWith("h3r"))
      throw `Invalid ${fieldName} key`;

    var ss = key.substring("h3r".length);
    var res = parseInt(ss);
    if (res < 0 || res > 15)
      throw `Invalid resolution key ${key}`;
    if (res != counter)
      throw `Unexpected key ${key} at index ${counter}`;

    var arr = fieldValue[key];
    if (arr.length == 0)
      throw `Empty array for ${fieldName}[${key}]`;
    for (const index of arr) {

      if (index == undefinedString) {
        if (arr.length == 1)
          continue;
        throw `${undefinedString} cannot co-exist in ${fieldName}[${key}]`;
      }
      if (!indexRegex.test(index))
        throw `Invalid ${fieldName} index ${index}`;
    }
    counter++;
  }
}

function getType(p) {
    if (Array.isArray(p))
      return 'array';
    else if (typeof p == 'string')
      return 'string';
    else if (p != null && typeof p == 'object')
      return 'object';
    else
      return 'other';
}

function AddToArray(arr, item) {
  var index = arr.indexOf(item);
  if (index < 0)
    arr.push(item);
  return arr;
}

function RemoveFromArray(arr, item) {
  var index = arr.indexOf(item);
  if (index > -1)
    arr.splice(index, 1);
  return arr;
}


exports.handler = async (event, context, callback) => {
    var tokens = JSON.stringify(context.invokedFunctionArn).split(':');
    var awsRegion = tokens[3];
    var accountId = tokens[4];
    const shapeRepo = "lafleet-shape-repo-" + accountId;
    const config = { region: awsRegion };
    
    try {
        // Receiving as Base64
        var body = event.body;
        if (body === undefined || body.length == 0)
          throw `body is empty`;
          
        var sj = {};
        if (event.isBase64Encoded) {
          var decodedHex = atob(body);
          if (decodedHex === undefined || decodedHex.length == 0)
            throw `decoded body is empty`;
            
          var decodedUri = decodeURIComponent(decodedHex); // decodeURI(decodedHex);
          if (decodedUri === undefined || decodedUri.length == 0)
            throw `decoded body is empty`;
            
          var payload = decodedUri.replace("shapeJson=", "")
            .replaceAll("\r\n", "").replaceAll("+", " ");
          sj = JSON.parse(payload);
        } else {
          var t = getType(body);
          if (t == 'object')
            sj = body;
          else if (t == 'string')
            sj = JSON.parse(body);
          else
            throw `Unknown type for json`;
        }

        if (sj === undefined || sj.length == 0)
          throw `json is empty`;
    
        var shapeId = sj.shapeId;
        if (shapeId === undefined || shapeId.length != 36)
          throw `Invalid shapeId (should be UUID)`;
    
        var name = sj.name;
        if (name === undefined || name.length == 0 || name == defaultName)
          throw `Invalid name`;
    
        var type = sj.type;
        if (type === undefined || type.length == 0 || !validTypes.includes(type))
          throw `Invalid type`;
    
        var status = sj.status;
        if (status === undefined || status.length == 0 || !validStatus.includes(status))
          throw `Invalid status`;
    
        // TODO: modifiedAt and deletedAt must be after createdAt
        validateDate("createdAt", sj.createdAt);
        validateDate("modifiedAt", sj.modifiedAt);
        validateDate("deletedAt", sj.deletedAt);

        // TODO: Validate against previous version
        validateVersion("shapeVersion", sj.shapeVersion);
        validateVersion("schemaVersion", sj.schemaVersion);
        
        checkPolygon("polygon", sj.polygon);
        checkResolutions("filter", sj.filter);
        checkResolutions("shape", sj.shape);
        
        var objectBucketName = shapeRepo;
        var objectKey = shapeId;
        var content = JSON.stringify(sj);
        console.log(`Saving shape to s3://${objectBucketName}/${objectKey}`);
        var res = await uploadFileToS3(config, content, objectBucketName, objectKey);
        console.log(`File uploaded successfully to s3://${objectBucketName}/${objectKey}`);
        
        // TODO: Download latest file from this type
        var latestObjectKey = "latest/" + type + ".json";
        
        const latestFiles = await listBucket(config, objectBucketName, "latest/");
        console.log(latestFiles);
        
        if (latestFiles.includes(latestObjectKey)) {
          const latestContent = await getObjectContent(config, objectBucketName, latestObjectKey);
          console.log(latestContent);
          const latestJson = JSON.parse(latestContent);
          var active = latestJson['active'];
          var inactive = latestJson['inactive'];
          var deleted = latestJson['deleted'];
          
          switch (status) {
            case "ACTIVE":
              AddToArray(active, shapeId);
              RemoveFromArray(inactive, shapeId);
              RemoveFromArray(deleted, shapeId);
              break;
            case "INACTIVE":
              RemoveFromArray(active, shapeId);
              AddToArray(inactive, shapeId);
              RemoveFromArray(deleted, shapeId);
              break;
            case "DELETED":
              RemoveFromArray(active, shapeId);
              RemoveFromArray(inactive, shapeId);
              AddToArray(deleted, shapeId);
              break;
            default:
              console.warn(`Unknown status ${status}`);
              break;
          }
          
          const latestNewJson = {
          	"type": type,
          	"active" : active,
          	"inactive" : inactive,
          	"deleted" : deleted
          };
          const latestNewContent = JSON.stringify(latestNewJson, null, 2);
          var latestRes = await uploadFileToS3(config, latestNewContent, objectBucketName, latestObjectKey);
          console.log(`File uploaded successfully to s3://${objectBucketName}/${latestRes}`);
        } else {
          var active = [];
          var inactive = [];
          var deleted = [];
          
          switch (status) {
            case "ACTIVE":
              AddToArray(active, shapeId);
              break;
            case "INACTIVE":
              AddToArray(inactive, shapeId);
              break;
            case "DELETED":
              RemoveFromArray(inactive, shapeId);
              break;
            default:
              console.warn(`Unknown status ${status}`);
              break;
          }
          
          const latestNewJson = {
          	"type": type,
          	"active" : active,
          	"inactive" : inactive,
          	"deleted" : deleted
          };
          const latestNewContent = JSON.stringify(latestNewJson, null, 2);
          var latestRes = await uploadFileToS3(config, latestNewContent, objectBucketName, latestObjectKey);
          console.log(`File uploaded successfully to s3://${objectBucketName}/${latestRes}`);
        }
        
        const response = {
            statusCode: 200,
            headers: {
                "Content-Type": "text/html"
            },
            body: `Shape ${name} uploaded successfully as ${objectKey}`,
            isBase64Encoded: false
        };
        callback(null, response);
    } catch (err) {
        console.log(err);
        const response = {
            statusCode: 500,
            headers: {
                "Content-Type": "text/html"
            },
            body: JSON.stringify(err),
            isBase64Encoded: false
        };
        callback(Error(err));
    }
};