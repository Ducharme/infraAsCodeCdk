import { CfnOutput, Stack } from 'aws-cdk-lib';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { Effect } from 'aws-cdk-lib/aws-iam';


export interface SqsQueueProps {
  readonly label: string;
  readonly sqsQueueName: string;
}

export class SqsQueue extends Construct {
  public readonly sqsQueueName: string;
  public readonly sqsDlqName: string;

  public readonly sqsQueue: sqs.Queue;
  public readonly sqsQueueRole : iam.Role; // For SQS IoT Rule
  public readonly sqsDeadLetterQueue: sqs.DeadLetterQueue;

  public readonly maxMessageSizeBytes = 2048;
  public readonly maxReceiveCount = 3;


  constructor(scope: Construct, id: string, props: SqsQueueProps) {
    super(scope, id);

    this.sqsQueueName = props.sqsQueueName;
    this.sqsDlqName = this.sqsQueueName + "-dlq";
    
    const sqsProps = { maxMessageSizeBytes: this.maxMessageSizeBytes };
    const sqs_queue_dlq : sqs.Queue = new sqs.Queue(this,
      "SQS_DLQ-" + this.sqsQueueName, {...sqsProps,
        queueName: this.sqsDlqName
    });
    this.sqsDeadLetterQueue = {maxReceiveCount: this.maxReceiveCount, queue: sqs_queue_dlq };
    this.sqsQueue = new sqs.Queue(this,
      "SQS_QUEUE-" + this.sqsQueueName, {...sqsProps,
        queueName: this.sqsQueueName,
        deadLetterQueue: this.sqsDeadLetterQueue
    });

    const sqsRole1 = new iam.Role(this, 'SQS_ROLE-' + this.sqsQueueName, {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com')
    });

    sqsRole1.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['sqs:SendMessage', 'sqs:ReceiveMessage'],
        resources: [this.sqsQueue.queueArn, this.sqsDeadLetterQueue.queue.queueArn],
      }),
    );

    this.sqsQueueRole = sqsRole1;
    //this.sqsQueue.grantConsumeMessages(sqsRole1);

    // Service will get roles from eksctl -> PROJECT_NAME-eks-sa-sqsshapeconsumer
    // Not availaible for SQS -> "aws:ResourceAccount": awsAccountId,
    // Not availaible for on webpage below ->"aws:SourceOwner": awsAccountId,
    // https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html
    const awsAccountId : string = Stack.of(this).account;
    const anyPrincipal = new iam.AnyPrincipal();
    const sqsGrantPolicy = new iam.PolicyStatement({
        actions: ['sqs:DeleteMessage', 'sqs:ReceiveMessage'],
        principals: [anyPrincipal],
        resources: [this.sqsQueue.queueArn],
        conditions: {
          StringEquals: {
            "aws:PrincipalAccount": awsAccountId,
            "AWS:SourceAccount": awsAccountId
          }
        }
    });
    this.sqsQueue.addToResourcePolicy(sqsGrantPolicy);

    const sqsQueueNameOutput = new CfnOutput(this, "SqsQueueName-" + props.label, {
      value: this.sqsQueue.queueName,
      description: '',
      exportName: 'SqsQueueName-' + props.label,
    });

    const sqsQueueUrlOutput = new CfnOutput(this, "SqsQueueUrl-" + props.label, {
      value: this.sqsQueue.queueUrl,
      description: '',
      exportName: 'SqsQueueUrl-' + props.label,
    });
  }
}