# Aurora Global Database Regional Failover — FIS Template

> Source: [aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library/tree/main/aurora-global-region-failover) | License: MIT-0

## Hypothesis Template

> When a regional failure affects the primary Aurora cluster, the global database should
> complete failover/switchover to the secondary region. Planned switchover should have
> zero data loss. Emergency failover may allow data loss but should complete within the
> defined RTO.

## Failover Types

| Type | Use Case | Data Loss | Duration |
|------|----------|-----------|----------|
| **Switchover** (default) | Planned maintenance, testing | None | Minutes |
| **Failover** | Emergency DR | Possible | Faster |

## How It Works

1. FIS triggers SSM Automation document
2. SSM validates the Aurora Global Database cluster status
3. SSM executes switchover or failover via Aurora Global Database API
4. Secondary cluster is promoted to primary
5. Former primary becomes secondary (switchover) or is detached (failover)

## Files

| File | Description |
|------|-------------|
| `aurora-global-region-failover-experiment-template.json` | FIS experiment template |
| `aurora-global-region-failover-automation.yaml` | SSM Automation document |
| `aurora-global-region-failover-fis-role-iam-policy.json` | IAM policy for FIS role |
| `aurora-global-region-failover-ssm-automation-role-iam-policy.json` | IAM policy for SSM role |
| `fis-iam-trust-relationship.json` | Trust policy for FIS role |
| `ssm-iam-trust-relationship.json` | Trust policy for SSM role |

## Deployment

```bash
# 1. Create IAM roles
aws iam create-role --role-name FIS-AuroraGlobalFailover --assume-role-policy-document file://fis-iam-trust-relationship.json
aws iam put-role-policy --role-name FIS-AuroraGlobalFailover --policy-name fis-policy --policy-document file://aurora-global-region-failover-fis-role-iam-policy.json

aws iam create-role --role-name SSM-AuroraGlobalFailover --assume-role-policy-document file://ssm-iam-trust-relationship.json
aws iam put-role-policy --role-name SSM-AuroraGlobalFailover --policy-name ssm-policy --policy-document file://aurora-global-region-failover-ssm-automation-role-iam-policy.json

# 2. Create SSM Automation document
aws ssm create-document --name aurora-global-failover --document-type Automation --content file://aurora-global-region-failover-automation.yaml --document-format YAML

# 3. Tag Aurora Global Database with FIS-Ready=True

# 4. Update experiment template with:
#    - globalClusterIdentifier
#    - failoverType (switchover or failover)
#    - AutomationAssumeRole ARN
#    - FIS roleArn
aws fis create-experiment-template --cli-input-json file://aurora-global-region-failover-experiment-template.json
```

## Key Parameters

- `globalClusterIdentifier`: Aurora Global Database cluster identifier (required)
- `failoverType`: `switchover` (planned, no data loss) or `failover` (emergency, allows data loss)
- `AutomationAssumeRole`: IAM role ARN for SSM Automation execution

## What to Verify

- [ ] Secondary cluster successfully promoted to primary
- [ ] Application endpoints updated to use new primary region
- [ ] Data consistency verified post-failover (RPO met)
- [ ] Failover completed within RTO target
- [ ] Monitoring detects the regional failover event
- [ ] DNS/Route53 health checks trigger traffic rerouting (if applicable)
