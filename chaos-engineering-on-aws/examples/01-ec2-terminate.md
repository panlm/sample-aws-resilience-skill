# Example 1: EC2 Instance Termination — Auto Scaling Recovery Validation

**Architecture pattern**: Traditional EC2 + ALB + Auto Scaling Group
**FIS Action**: `aws:ec2:terminate-instances`
**Validation target**: ASG automatically launches replacement instances, ALB health check passes, requests uninterrupted

---

## Steady-State Hypothesis

After terminating 1 EC2 instance in the ASG:
- ALB request success rate >= 99.5% (5min window)
- P99 latency <= 500ms
- ASG replenishes a new instance and passes health check within 300s
- Zero data loss

### What does this enable you to verify?

- Auto Scaling Group replacement speed and health check configuration
- ALB target deregistration delay and health check sensitivity
- Application statelessness (no session affinity issues when instance is lost)
- CloudWatch alarm fires for `UnHealthyHostCount` within 1 minute
- No customer-visible errors during instance replacement

## Stop Conditions

```json
{
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:{region}:{account}:alarm:chaos-stop-5xx-rate"
    }
  ]
}
```

Corresponding CloudWatch Alarm:
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "chaos-stop-5xx-rate" \
  --namespace "AWS/ApplicationELB" \
  --metric-name "HTTPCode_Target_5XX_Count" \
  --statistic Sum \
  --period 60 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --treat-missing-data notBreaching \
  --alarm-actions "arn:aws:sns:{region}:{account}:chaos-alerts"
```

## FIS Experiment Template

```json
{
  "description": "Terminate one EC2 instance in ASG to validate auto-recovery",
  "targets": {
    "ec2-instances": {
      "resourceType": "aws:ec2:instance",
      "resourceArns": [
        "arn:aws:ec2:{region}:{account}:instance/{instance-id}"
      ],
      "selectionMode": "COUNT(1)"
    }
  },
  "actions": {
    "terminate-instance": {
      "actionId": "aws:ec2:terminate-instances",
      "parameters": {},
      "targets": {
        "Instances": "ec2-instances"
      }
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:{region}:{account}:alarm:chaos-stop-5xx-rate"
    }
  ],
  "roleArn": "arn:aws:iam::{account}:role/FISExperimentRole",
  "tags": {
    "Purpose": "chaos-engineering",
    "RiskId": "R-001"
  }
}
```

## Execution Commands

```bash
# Create template
aws fis create-experiment-template \
  --cli-input-json file://examples/ec2-terminate-template.json

# Start experiment
aws fis start-experiment --experiment-template-id <template-id>

# Monitor experiment status
aws fis get-experiment --id <experiment-id> \
  --query 'experiment.state.status'
```

## Observation Metrics

| Metric | Namespace | MetricName | Dimensions |
|------|-----------|------------|------|
| 5xx error count | AWS/ApplicationELB | HTTPCode_Target_5XX_Count | LoadBalancer, TargetGroup |
| Request count | AWS/ApplicationELB | RequestCount | LoadBalancer |
| Healthy host count | AWS/ApplicationELB | HealthyHostCount | TargetGroup |
| ASG instance count | AWS/AutoScaling | GroupInServiceInstances | AutoScalingGroupName |

## Expected Results

| Phase | Time | Expected |
|------|------|------|
| Injection | T+0s | Target instance terminated |
| Detection | T+10-30s | ALB health check detects instance unavailable |
| ASG Response | T+30-60s | ASG launches new instance |
| Recovery | T+180-300s | New instance passes health check, traffic restored |

**If failed**: Indicates ASG configuration issues (min capacity, health check interval, launch template). Check ASG policies and Launch Template.
