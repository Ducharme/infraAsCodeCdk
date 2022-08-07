import { CfnOutput, RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';


export interface SqsQueueProps {
  readonly label: string;
  readonly sqsQueueName: string;
}

export class SqsQueue extends Construct {
  public readonly sqsQueueName: string;
  public readonly sqsDlqName: string;

  public readonly sqsQueue: sqs.Queue;
  public readonly sqsQueueRole : iam.Role;
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