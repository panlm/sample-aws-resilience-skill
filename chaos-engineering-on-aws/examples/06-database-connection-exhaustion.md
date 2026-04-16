# Example 6: Database Connection Limit Exhaustion — Connection Pool Resilience

**Architecture pattern**: Application → Connection Pool → RDS/Aurora (PostgreSQL, MySQL, or SQL Server)
**Injection method**: SSM Automation (dynamic EC2 load generator → exhaust connections → cleanup)
**Validates**: Circuit breaker activation, graceful degradation, connection pool monitoring, auto-recovery

> Template source: [aws-samples/fis-template-library/database-connection-limit-exhaustion](https://github.com/aws-samples/fis-template-library/tree/main/database-connection-limit-exhaustion)
> Embedded template: `references/fis-templates/database-connection-exhaustion/`

---

## Hypothesis

When the database connection limit is approaching its limit, the application should:
- Detect connection pressure via monitoring (CloudWatch `DatabaseConnections` metric)
- Trigger a leading alarm before connections are fully exhausted
- Circuit breaker should remain closed while connections are available

When the connection limit is fully exhausted:
- Circuit breaker should open, preventing new connection attempts
- UI should degrade gracefully (affected features unavailable, other features continue)
- Alarm should fire and DevOps team notified within {y} minutes
- Other services not sharing this database should remain unaffected

After connections are released:
- Circuit breaker should close within {z} minutes
- Steady state of {n} transactions per second should resume

### What does this enable you to verify?

- Database connection pool monitoring and alerting is properly configured
- Application circuit breaker works as expected under connection exhaustion
- Graceful degradation prevents cascading failures to unrelated services
- Recovery is automatic when connections become available again
- Ephemeral load generator is properly cleaned up (no resource leak)

## Prerequisites

- [ ] RDS or Aurora instance accessible from a VPC subnet
- [ ] Target database tagged with `FIS-Ready=True`
- [ ] FIS IAM Role created with `fis-role-iam-policy.json`
- [ ] SSM Automation IAM Role created with `ssm-role-iam-policy.json`
- [ ] SSM Automation Document deployed from `ssm-automation.yaml`
- [ ] CloudWatch alarm for `DatabaseConnections` metric
- [ ] Application circuit breaker configured for database connections

## Setup

### 1. Deploy IAM Roles

```bash
# FIS Role
aws iam create-role \
  --role-name FIS-DbConnExhaustion \
  --assume-role-policy-document file://references/fis-templates/database-connection-exhaustion/fis-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name FIS-DbConnExhaustion \
  --policy-name fis-policy \
  --policy-document file://references/fis-templates/database-connection-exhaustion/fis-role-iam-policy.json

# SSM Role
aws iam create-role \
  --role-name SSM-DbConnExhaustion \
  --assume-role-policy-document file://references/fis-templates/database-connection-exhaustion/ssm-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name SSM-DbConnExhaustion \
  --policy-name ssm-policy \
  --policy-document file://references/fis-templates/database-connection-exhaustion/ssm-role-iam-policy.json
```

### 2. Deploy SSM Automation Document

```bash
aws ssm create-document \
  --name db-connection-exhaustion \
  --document-type Automation \
  --content file://references/fis-templates/database-connection-exhaustion/ssm-automation.yaml \
  --document-format YAML
```

### 3. Create FIS Experiment

Edit `experiment-template.json` to replace:
- `{ACCOUNT_ID}` with your AWS account ID
- `{REGION}` with target region
- `{FIS_ROLE_ARN}` with the FIS role ARN
- Database endpoint, credentials, engine type, and connection count parameters

```bash
aws fis create-experiment-template \
  --cli-input-json file://references/fis-templates/database-connection-exhaustion/experiment-template.json
```

## Execution

```bash
# Start the experiment
aws fis start-experiment --experiment-template-id {TEMPLATE_ID}

# Monitor database connections
watch -n 10 'aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value={INSTANCE_ID} \
  --start-time $(date -u -d "10 minutes ago" +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Maximum \
  --output table'
```

## Observation Metrics

| Metric | Source | Expected Behavior |
|--------|--------|-------------------|
| `DatabaseConnections` | CloudWatch RDS | Ramp up → plateau at max → drop to normal |
| Application error rate | Application metrics | Spike when connections exhausted, recover after |
| Circuit breaker state | Application logs | Closed → Open → Half-Open → Closed |
| Connection pool wait time | Application metrics | Increase as pool exhausts |
| Ephemeral EC2 status | EC2 Console | Created → Running → Terminated |

## Cleanup

The SSM Automation document handles cleanup automatically:
- Releases all held database connections
- Terminates the ephemeral EC2 load generator instance
- No manual cleanup required under normal operation

If the experiment is manually stopped or fails:
```bash
# Check for leftover EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Purpose,Values=FIS-Connection-Exhaustion" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId'

# Terminate if found
aws ec2 terminate-instances --instance-ids {INSTANCE_ID}
```
