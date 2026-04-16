# CloudFront Distribution Impairment — FIS Template

> Source: [aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library/tree/main/cloudfront-impairment) | License: MIT-0

## Hypothesis Template

> When S3 origins serving CloudFront are impaired, CloudFront should failover to secondary
> origins within 30 seconds. An alarm should fire within 2-3 minutes. Once resolved,
> CloudFront should resume using the primary origin within 30 seconds.

## How It Works

1. FIS triggers SSM Automation document
2. SSM discovers CloudFront distributions tagged `FIS-Ready=True`
3. SSM applies deny policy to S3 buckets serving as origins → blocks CloudFront access
4. CloudFront receives errors from primary origin and fails over to origin group secondary
5. After duration, SSM removes deny policy → primary origin resumes

**Key technique**: S3 bucket policy denial — simulates origin failure without touching CloudFront itself.

**Prerequisite**: CloudFront distributions must have **origin groups** configured with primary + secondary origins.

## Files

| File | Description |
|------|-------------|
| `cloudfront-impairment-tag-based-experiment-template.json` | FIS experiment template |
| `cloudfront-impairment-tag-based-automation.yaml` | SSM Automation document |
| `cloudfront-impairment-tag-based-fis-role-iam-policy.json` | IAM policy for FIS role |
| `cloudfront-impairment-tag-based-ssm-automation-role-iam-policy.json` | IAM policy for SSM role |
| `fis-iam-trust-relationship.json` | Trust policy for FIS role |
| `ssm-iam-trust-relationship.json` | Trust policy for SSM role |

## Deployment

```bash
# 1. Create IAM roles
aws iam create-role --role-name FIS-CloudFrontImpairment --assume-role-policy-document file://fis-iam-trust-relationship.json
aws iam put-role-policy --role-name FIS-CloudFrontImpairment --policy-name fis-policy --policy-document file://cloudfront-impairment-tag-based-fis-role-iam-policy.json

aws iam create-role --role-name SSM-CloudFrontImpairment --assume-role-policy-document file://ssm-iam-trust-relationship.json
aws iam put-role-policy --role-name SSM-CloudFrontImpairment --policy-name ssm-policy --policy-document file://cloudfront-impairment-tag-based-ssm-automation-role-iam-policy.json

# 2. Create SSM Automation document
aws ssm create-document --name cloudfront-impairment --document-type Automation --content file://cloudfront-impairment-tag-based-automation.yaml --document-format YAML

# 3. Tag CloudFront distributions with FIS-Ready=True
# 4. Ensure origin groups are configured on target distributions

# 5. Update experiment template with your role ARNs, then:
aws fis create-experiment-template --cli-input-json file://cloudfront-impairment-tag-based-experiment-template.json
```

## What to Verify

- [ ] CloudFront error rate alarm fires when primary origin fails
- [ ] Origin group failover activates within 30 seconds
- [ ] Content continues to be served from secondary origin
- [ ] Application-level monitoring detects degradation
- [ ] After primary origin restore, CloudFront resumes using it
