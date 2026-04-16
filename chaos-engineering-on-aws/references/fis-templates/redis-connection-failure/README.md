# ElastiCache Redis Connection Failure — FIS Template

> Source: [aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-connection-failure) | License: MIT-0

## Hypothesis Template

> When Redis connections are disrupted, applications should gracefully handle the failure through
> circuit breaker mechanisms within 30 seconds. Client retry storms should be prevented.
> Once Redis connectivity is restored, normal operations should resume within 60 seconds.

## How It Works

1. FIS triggers SSM Automation document
2. SSM scans ElastiCache replication groups for clusters tagged `FIS-Ready=True`
3. SSM removes security group inbound rules to block application → Redis traffic
4. Connection disruption is maintained for specified duration
5. SSM restores original security group rules

**Key technique**: Security Group manipulation — more flexible than FIS native network actions (which only support subnet-level). This targets specific service connections.

## Files

| File | Description |
|------|-------------|
| `redis-connection-failure-experiment-template.json` | FIS experiment template |
| `redis-connection-failure-automation.yaml` | SSM Automation document |
| `redis-connection-failure-fis-role-iam-policy.json` | IAM policy for FIS role |
| `redis-connection-failure-ssm-role-iam-policy.json` | IAM policy for SSM role |
| `fis-iam-trust-relationship.json` | Trust policy for FIS role |
| `ssm-iam-trust-relationship.json` | Trust policy for SSM role |

## Deployment

```bash
# 1. Create IAM roles
aws iam create-role --role-name FIS-RedisConnFailure --assume-role-policy-document file://fis-iam-trust-relationship.json
aws iam put-role-policy --role-name FIS-RedisConnFailure --policy-name fis-policy --policy-document file://redis-connection-failure-fis-role-iam-policy.json

aws iam create-role --role-name SSM-RedisConnFailure --assume-role-policy-document file://ssm-iam-trust-relationship.json
aws iam put-role-policy --role-name SSM-RedisConnFailure --policy-name ssm-policy --policy-document file://redis-connection-failure-ssm-role-iam-policy.json

# 2. Create SSM Automation document
aws ssm create-document --name redis-connection-failure --document-type Automation --content file://redis-connection-failure-automation.yaml --document-format YAML

# 3. Update experiment template with your role ARNs, then:
aws fis create-experiment-template --cli-input-json file://redis-connection-failure-experiment-template.json
```

## What to Verify

- [ ] Redis connectivity monitoring detects the failure
- [ ] Application circuit breaker activates (no retry storms)
- [ ] Application operates in degraded mode without cascading failures
- [ ] After SG rules are restored, Redis connections recover
- [ ] Cache rebuild/warm-up completes within acceptable time
