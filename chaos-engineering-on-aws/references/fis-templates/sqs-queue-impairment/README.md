# SQS Queue Impairment — FIS Template

> Source: [aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library/tree/main/sqs-queue-impairment) | License: MIT-0

## Hypothesis Template

> When SQS is experiencing an impairment, an alarm should be raised within 5 minutes.
> Functionality relating to the affected component should not be available to end users,
> but other components should continue normally. Once resolved, the affected component
> should recover within 5 minutes.

## How It Works

This experiment simulates progressive SQS impairment through 4 escalating rounds:

| Round | Block Duration | Recovery Window |
|-------|---------------|----------------|
| 1 | 2 minutes | 3 minutes |
| 2 | 5 minutes | 3 minutes |
| 3 | 7 minutes | 2 minutes |
| 4 | 15 minutes | — |

Each round:
1. SSM Automation adds a deny-all statement to the SQS queue policy
2. All `SendMessage`, `ReceiveMessage`, etc. operations return `AccessDenied`
3. After the duration, SSM removes the deny statement

**Key technique**: Resource policy denial — simulates service unavailability at the IAM layer.

## Files

| File | Description |
|------|-------------|
| `sqs-queue-impairment-tag-based-experiment-template.json` | FIS experiment template |
| `sqs-queue-impairment-tag-based-automation.yaml` | SSM Automation document |
| `sqs-queue-impairment-tag-based-fis-role-iam-policy.json` | IAM policy for FIS role |
| `sqs-queue-impairment-tag-based-ssm-automation-role-iam-policy.json` | IAM policy for SSM role |
| `fis-iam-trust-relationship.json` | Trust policy for FIS role |
| `ssm-iam-trust-relationship.json` | Trust policy for SSM role |

## Deployment

```bash
# 1. Create IAM roles
aws iam create-role --role-name FIS-SqsImpairment --assume-role-policy-document file://fis-iam-trust-relationship.json
aws iam put-role-policy --role-name FIS-SqsImpairment --policy-name fis-policy --policy-document file://sqs-queue-impairment-tag-based-fis-role-iam-policy.json

aws iam create-role --role-name SSM-SqsImpairment --assume-role-policy-document file://ssm-iam-trust-relationship.json
aws iam put-role-policy --role-name SSM-SqsImpairment --policy-name ssm-policy --policy-document file://sqs-queue-impairment-tag-based-ssm-automation-role-iam-policy.json

# 2. Create SSM Automation document
aws ssm create-document --name sqs-queue-impairment --document-type Automation --content file://sqs-queue-impairment-tag-based-automation.yaml --document-format YAML

# 3. Tag target SQS queues with FIS-Ready=True

# 4. Update experiment template with your role ARNs, then:
aws fis create-experiment-template --cli-input-json file://sqs-queue-impairment-tag-based-experiment-template.json
```

## What to Verify

- [ ] SQS monitoring alarm fires within 5 minutes of first impairment
- [ ] Affected component becomes unavailable but other components unaffected
- [ ] Dead letter queue captures failed messages (if configured)
- [ ] Producer implements backpressure when queue is unavailable
- [ ] Between impairment rounds, message processing resumes normally
- [ ] After final round, full recovery within 5 minutes
