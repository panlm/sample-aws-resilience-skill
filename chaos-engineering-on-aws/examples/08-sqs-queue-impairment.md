# Example 8: SQS Queue Impairment — Message Queue Resilience

**Architecture pattern**: Producer → SQS Queue → Consumer (async messaging)
**Injection method**: SSM Automation (SQS queue policy deny → restore, 4 escalating rounds)
**Validates**: DLQ handling, message backpressure, component isolation, progressive failure tolerance

> Template source: [aws-samples/fis-template-library/sqs-queue-impairment](https://github.com/aws-samples/fis-template-library/tree/main/sqs-queue-impairment)
> Embedded template: `references/fis-templates/sqs-queue-impairment/`

---

## Hypothesis

When SQS queue access is denied (progressive impairment — 4 rounds):
- Alarm should fire within 5 minutes of first impairment round
- Component A (dependent on this queue) should become unavailable to end users
- Other components (B, C) should continue operating normally
- Producer should implement backpressure (stop accepting work it cannot queue)
- Dead Letter Queue should capture failed messages (if configured)

Between impairment rounds (recovery windows):
- Message processing should resume normally
- Accumulated messages should be processed without overwhelming consumers

After all impairment rounds complete:
- Full recovery within 5 minutes
- No message loss (all messages eventually processed or in DLQ)

### What does this enable you to verify?

- SQS monitoring and alerting for queue unavailability
- Producer-side error handling and backpressure mechanisms
- Consumer resilience to intermittent queue access failures
- Dead Letter Queue configuration and message capture
- Component isolation — failure in one queue doesn't cascade
- Progressive failure tolerance (can the system handle worsening conditions?)

## Prerequisites

- [ ] SQS queue tagged with `FIS-Ready=True`
- [ ] FIS IAM Role created with `sqs-queue-impairment-tag-based-fis-role-iam-policy.json`
- [ ] SSM Automation IAM Role created with `sqs-queue-impairment-tag-based-ssm-automation-role-iam-policy.json`
- [ ] SSM Automation Document deployed from `sqs-queue-impairment-tag-based-automation.yaml`
- [ ] CloudWatch alarm for `NumberOfMessagesSent` or `ApproximateNumberOfMessagesVisible`
- [ ] Dead Letter Queue configured on target queue (recommended)
- [ ] Application health check endpoints accessible

## Progressive Impairment Schedule

| Round | Block Duration | Recovery Window | Cumulative Time |
|-------|---------------|----------------|----------------|
| 1 | 2 min | 3 min | 0-5 min |
| 2 | 5 min | 3 min | 5-13 min |
| 3 | 7 min | 2 min | 13-22 min |
| 4 | 15 min | — | 22-37 min |

**Total experiment duration: ~37 minutes**

## Setup

### 1. Deploy IAM Roles

```bash
aws iam create-role \
  --role-name FIS-SqsImpairment \
  --assume-role-policy-document file://references/fis-templates/sqs-queue-impairment/fis-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name FIS-SqsImpairment \
  --policy-name fis-policy \
  --policy-document file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-fis-role-iam-policy.json

aws iam create-role \
  --role-name SSM-SqsImpairment \
  --assume-role-policy-document file://references/fis-templates/sqs-queue-impairment/ssm-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name SSM-SqsImpairment \
  --policy-name ssm-policy \
  --policy-document file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-ssm-automation-role-iam-policy.json
```

### 2. Deploy SSM Automation Document

```bash
aws ssm create-document \
  --name sqs-queue-impairment \
  --document-type Automation \
  --content file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-automation.yaml \
  --document-format YAML
```

### 3. Create FIS Experiment

```bash
aws fis create-experiment-template \
  --cli-input-json file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-experiment-template.json
```

## Execution

```bash
# Start the experiment
aws fis start-experiment --experiment-template-id {TEMPLATE_ID}

# Monitor queue accessibility (should see AccessDenied during impairment rounds)
watch -n 5 'aws sqs send-message \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --message-body "chaos-test-$(date +%s)" \
  --region {REGION} \
  --no-cli-pager 2>&1 | tail -1'

# Monitor queue depth
watch -n 10 'aws sqs get-queue-attributes \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --attribute-names ApproximateNumberOfMessagesVisible ApproximateNumberOfMessagesNotVisible \
  --output table'
```

## Observation Metrics

| Metric | Source | Expected Behavior |
|--------|--------|-------------------|
| `NumberOfMessagesSent` | CloudWatch SQS | Drop to 0 during impairment, resume between rounds |
| `ApproximateNumberOfMessagesVisible` | CloudWatch SQS | Accumulate during impairment if producer buffers |
| `NumberOfMessagesReceived` | CloudWatch SQS | Drop during impairment, spike during recovery |
| Application error rate (queue component) | Application metrics | Errors during impairment, recovery between rounds |
| Application error rate (other components) | Application metrics | Stable throughout — no cascading |
| DLQ message count | CloudWatch SQS (DLQ) | Increment if messages exceed retry limit |

## Cleanup

The SSM Automation document automatically removes deny statements from the SQS queue policy.

If manual cleanup is needed:
```bash
# Check current queue policy for deny statements
aws sqs get-queue-attributes \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --attribute-names Policy

# If deny statement remains, remove it by setting the policy without the deny
aws sqs set-queue-attributes \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --attributes '{"Policy": ""}'
```
