# Database Connection Limit Exhaustion — FIS Template

> Source: [aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library/tree/main/database-connection-limit-exhaustion) | License: MIT-0

## Hypothesis Template

> When the database connection limit is approaching its limit, the circuit breaker should remain closed.
> When the connection limit is exhausted, the circuit breaker should open, the UI should degrade gracefully,
> and an alarm should fire within {y} minutes. After connections drain, the circuit breaker should close
> within {z} minutes and steady state should resume.

## How It Works

1. FIS triggers SSM Automation document
2. SSM dynamically creates an ephemeral EC2 instance as load generator
3. EC2 bootstraps with the appropriate DB client (PostgreSQL / MySQL / SQL Server)
4. Script opens and holds connections to exhaust the connection limit
5. After specified duration, connections are released
6. Ephemeral EC2 instance is terminated

**Supported engines**: Aurora PostgreSQL, Aurora MySQL, RDS PostgreSQL, RDS MySQL, RDS SQL Server

## Files

| File | Description |
|------|-------------|
| `experiment-template.json` | FIS experiment template |
| `ssm-automation.yaml` | SSM Automation document (multi-step orchestration) |
| `fis-role-iam-policy.json` | IAM policy for FIS execution role |
| `ssm-role-iam-policy.json` | IAM policy for SSM Automation execution role |
| `fis-iam-trust-relationship.json` | Trust policy for FIS role |
| `ssm-iam-trust-relationship.json` | Trust policy for SSM role |

## Deployment

```bash
# 1. Create IAM roles
aws iam create-role --role-name FIS-DbConnExhaustion --assume-role-policy-document file://fis-iam-trust-relationship.json
aws iam put-role-policy --role-name FIS-DbConnExhaustion --policy-name fis-policy --policy-document file://fis-role-iam-policy.json

aws iam create-role --role-name SSM-DbConnExhaustion --assume-role-policy-document file://ssm-iam-trust-relationship.json
aws iam put-role-policy --role-name SSM-DbConnExhaustion --policy-name ssm-policy --policy-document file://ssm-role-iam-policy.json

# 2. Create SSM Automation document
aws ssm create-document --name db-connection-exhaustion --document-type Automation --content file://ssm-automation.yaml --document-format YAML

# 3. Update experiment-template.json with your account/region/role ARNs, then:
aws fis create-experiment-template --cli-input-json file://experiment-template.json
```

## Key Parameters to Customize

- RDS/Aurora endpoint and credentials
- Database engine type
- Target connection count
- Duration to hold connections
- Subnet and security group for ephemeral EC2
- IAM role ARNs

## What to Verify

- [ ] Connection pool monitoring alarm fires before limit is reached
- [ ] Circuit breaker activates when connections are exhausted
- [ ] Application degrades gracefully (no cascading failures)
- [ ] After connections drain, circuit breaker closes and traffic resumes
- [ ] Ephemeral EC2 is properly terminated (no resource leak)
