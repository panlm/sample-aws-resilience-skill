# Example 2: RDS Aurora Failover — Database HA Validation

**Architecture pattern**: Aurora Cluster (Writer + Reader)
**FIS Action**: `aws:rds:failover-db-cluster`
**Validation target**: Reader promoted to Writer, application connections auto-recover, zero data loss

---

## Steady-State Hypothesis

After triggering Aurora cluster failover:
- Database write recovery time <= 30s
- Application request success rate >= 99% (brief drop allowed during failover)
- Data integrity 100% after failover
- Application connection pool auto-reconnects without manual intervention

### What does this enable you to verify?

- Database connection pool reconnection logic and DNS TTL settings
- Application error handling during brief write unavailability
- Aurora cluster endpoint DNS propagation speed
- Read replica promotion and writer/reader role swap correctness
- CloudWatch alarm for `AuroraReplicaLag` and failover events

## Stop Conditions

```json
{
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:{region}:{account}:alarm:chaos-stop-db-connections"
    }
  ]
}
```

Corresponding Alarm (alert if connections drop to zero for over 5 minutes):
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "chaos-stop-db-connections" \
  --namespace "AWS/RDS" \
  --metric-name "DatabaseConnections" \
  --dimensions Name=DBClusterIdentifier,Value={cluster-id} \
  --statistic Average \
  --period 60 \
  --threshold 0 \
  --comparison-operator LessThanOrEqualToThreshold \
  --evaluation-periods 5 \
  --treat-missing-data notBreaching \
  --alarm-actions "arn:aws:sns:{region}:{account}:chaos-alerts"
```

## FIS Experiment Template

```json
{
  "description": "Failover Aurora cluster to validate HA and application reconnect",
  "targets": {
    "aurora-cluster": {
      "resourceType": "aws:rds:cluster",
      "resourceArns": [
        "arn:aws:rds:{region}:{account}:cluster:{cluster-id}"
      ],
      "selectionMode": "ALL"
    }
  },
  "actions": {
    "failover-cluster": {
      "actionId": "aws:rds:failover-db-cluster",
      "parameters": {},
      "targets": {
        "Clusters": "aurora-cluster"
      }
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:{region}:{account}:alarm:chaos-stop-db-connections"
    }
  ],
  "roleArn": "arn:aws:iam::{account}:role/FISExperimentRole",
  "tags": {
    "Purpose": "chaos-engineering",
    "RiskId": "R-002"
  }
}
```

## Execution Commands

```bash
# Confirm current Writer
aws rds describe-db-clusters --db-cluster-identifier {cluster-id} \
  --query 'DBClusters[0].DBClusterMembers[?IsClusterWriter==`true`].DBInstanceIdentifier'

# Create and start experiment
aws fis create-experiment-template --cli-input-json file://examples/rds-failover-template.json
aws fis start-experiment --experiment-template-id <template-id>

# Verify Writer has switched
aws rds describe-db-clusters --db-cluster-identifier {cluster-id} \
  --query 'DBClusters[0].DBClusterMembers[?IsClusterWriter==`true`].DBInstanceIdentifier'
```

## Observation Metrics

| Metric | Namespace | MetricName | Description |
|------|-----------|------------|------|
| Connection count | AWS/RDS | DatabaseConnections | Drops to zero during failover |
| Write latency | AWS/RDS | CommitLatency | Should return to normal after failover |
| Replica lag | AWS/RDS | AuroraReplicaLag | New Writer sync status |
| Application error rate | Application layer | 5xx / connection refused | Validate connection pool reconnect |

## Expected Results

| Phase | Time | Expected |
|------|------|------|
| Injection | T+0s | Failover triggered |
| Impact | T+5-15s | Database connections interrupted, writes fail |
| Switchover | T+15-30s | Reader promoted to Writer |
| Recovery | T+20-35s | Application connection pool reconnects, writes resume |

**If failed**: Common causes — application not using Aurora cluster endpoint (using instance endpoint instead), connection pool lacks retry logic, DNS TTL too long. Check connection string and retry configuration.
