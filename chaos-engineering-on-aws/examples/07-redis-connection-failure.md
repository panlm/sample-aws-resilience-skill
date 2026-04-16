# Example 7: ElastiCache Redis Connection Failure — Cache Layer Resilience

**Architecture pattern**: Application → ElastiCache Redis (replication group)
**Injection method**: SSM Automation (Security Group rule removal → restore)
**Validates**: Circuit breaker, retry storm prevention, degraded mode, cache rebuild

> Template source: [aws-samples/fis-template-library/elasticache-redis-connection-failure](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-connection-failure)
> Embedded template: `references/fis-templates/redis-connection-failure/`

---

## Hypothesis

When Redis connections are disrupted:
- Application circuit breaker should activate within 30 seconds
- Client retry storms should be prevented (no exponential amplification)
- Application should continue in degraded mode (fall back to database or return cached defaults)
- No cascading failures to upstream or downstream services
- CloudWatch alarm for Redis connectivity should fire within 2 minutes

When Redis connectivity is restored:
- Normal operations should resume within 60 seconds
- Cache warming/rebuild should complete without impacting performance
- Circuit breaker should transition: Open → Half-Open → Closed

### What does this enable you to verify?

- Redis client circuit breaker and retry configuration
- Cache-aside pattern fallback behavior (DB query on cache miss)
- Application degradation strategy when cache layer is unavailable
- Security Group-based fault injection as a reusable pattern
- Cache rebuild behavior and performance impact after restoration

## Prerequisites

- [ ] ElastiCache Redis replication group tagged with `FIS-Ready=True`
- [ ] Application instances in same VPC with Security Group allowing Redis access
- [ ] FIS IAM Role created with `redis-connection-failure-fis-role-iam-policy.json`
- [ ] SSM Automation IAM Role created with `redis-connection-failure-ssm-role-iam-policy.json`
- [ ] SSM Automation Document deployed from `redis-connection-failure-automation.yaml`
- [ ] Application circuit breaker configured for Redis connections
- [ ] CloudWatch alarm for Redis `ReplicationLag` or custom connectivity metric

## Setup

### 1. Deploy IAM Roles

```bash
# FIS Role
aws iam create-role \
  --role-name FIS-RedisConnFailure \
  --assume-role-policy-document file://references/fis-templates/redis-connection-failure/fis-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name FIS-RedisConnFailure \
  --policy-name fis-policy \
  --policy-document file://references/fis-templates/redis-connection-failure/redis-connection-failure-fis-role-iam-policy.json

# SSM Role
aws iam create-role \
  --role-name SSM-RedisConnFailure \
  --assume-role-policy-document file://references/fis-templates/redis-connection-failure/ssm-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name SSM-RedisConnFailure \
  --policy-name ssm-policy \
  --policy-document file://references/fis-templates/redis-connection-failure/redis-connection-failure-ssm-role-iam-policy.json
```

### 2. Deploy SSM Automation Document

```bash
aws ssm create-document \
  --name redis-connection-failure \
  --document-type Automation \
  --content file://references/fis-templates/redis-connection-failure/redis-connection-failure-automation.yaml \
  --document-format YAML
```

### 3. Create FIS Experiment

```bash
# Update template with your role ARNs and region
aws fis create-experiment-template \
  --cli-input-json file://references/fis-templates/redis-connection-failure/redis-connection-failure-experiment-template.json
```

## Execution

```bash
# Start the experiment
aws fis start-experiment --experiment-template-id {TEMPLATE_ID}

# Monitor Redis connectivity
watch -n 5 'redis-cli -h {REDIS_ENDPOINT} ping 2>&1'

# Monitor Security Group changes
watch -n 10 'aws ec2 describe-security-groups \
  --group-ids {SG_ID} \
  --query "SecurityGroups[0].IpPermissions" \
  --output table'
```

## Observation Metrics

| Metric | Source | Expected Behavior |
|--------|--------|-------------------|
| Redis `ping` | redis-cli | Success → Timeout → Success |
| Application error rate | Application metrics | Brief spike, then stabilize in degraded mode |
| Cache hit rate | Application metrics | Drop to 0% during outage, gradually recover |
| Database query rate | CloudWatch RDS | Increase (fallback queries) during Redis outage |
| Circuit breaker state | Application logs | Closed → Open → Half-Open → Closed |

## Cleanup

The SSM Automation document automatically restores Security Group rules.

If manual cleanup is needed:
```bash
# Check current SG rules — verify Redis port (6379) inbound rule is restored
aws ec2 describe-security-groups \
  --group-ids {SG_ID} \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`6379\`]"

# Manually restore if missing
aws ec2 authorize-security-group-ingress \
  --group-id {SG_ID} \
  --protocol tcp \
  --port 6379 \
  --source-group {APP_SG_ID}
```
