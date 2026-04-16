# AWS FIS Template Library — Scenario Index

> Source: [aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library) (commit: e2c94c3)
> License: MIT-0
> Last synced: 2026-04-16

This index catalogs all 19 experiment templates from the AWS FIS Template Library.
Each template includes a ready-to-deploy FIS experiment JSON, IAM policies, and (where applicable) SSM Automation documents.

Templates marked with ⭐ are embedded in `references/fis-templates/` for direct use.

---

## Compute

### ec2-instances-terminate
- **Fault type**: Instance termination
- **Injection method**: FIS native (`aws:ec2:terminate-instances`)
- **Target**: EC2 instances tagged `FIS-Ready=True`, selection mode `COUNT(25%)`
- **Hypothesis**: Application remains available as 25% of EC2 servers within the ASG are terminated
- **Applicable architectures**: Any EC2-based workload with Auto Scaling
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/ec2-instances-terminate)

### ec2-spot-interruption
- **Fault type**: Spot Instance interruption signal
- **Injection method**: FIS native (`aws:ec2:send-spot-instance-interruptions`)
- **Target**: EC2 Spot Instances tagged `FIS-Ready=True`, 25% selection, 4-min warning
- **Hypothesis**: Spot Instances gracefully terminate; apps auto-restart on new Spot or On-Demand instances with seamless load balancer failover
- **Applicable architectures**: Cost-optimized workloads using Spot Instances
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/ec2-spot-interruption)

### ec2-windows-stop-iis
- **Fault type**: Windows IIS service stop
- **Injection method**: SSM Automation (PowerShell Stop-Service)
- **Target**: Windows EC2 instances tagged `FIS-Ready=True` with SSM Agent
- **Hypothesis**: Application remains available when IIS crashes on one Windows instance
- **Applicable architectures**: Windows/.NET workloads on EC2
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/ec2-windows-stop-iis)

---

## Database — RDS/Aurora

### aurora-cluster-failover
- **Fault type**: Aurora cluster failover (reader↔writer promotion)
- **Injection method**: FIS native (`aws:rds:failover-db-cluster`)
- **Target**: Aurora clusters tagged `FIS-Ready=True`
- **Hypothesis**: Brief request failures during failover, automatic recovery, application continues normally
- **Applicable architectures**: Any Aurora-backed application with Multi-AZ
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/aurora-cluster-failover)

### aurora-postgres-cluster-loadtest-failover
- **Fault type**: CPU overload + failover under load
- **Injection method**: SSM Automation (EC2 load generator → pgbench) + FIS failover
- **Target**: Aurora PostgreSQL cluster + EC2 load generator, both tagged `FIS-Ready=True`
- **Hypothesis**: System restores normal operation with minimal disruption under stress; near 100% request success rate after failover
- **Applicable architectures**: Aurora PostgreSQL workloads needing stress + failover validation
- **⚠️ Creates test tables in target database**
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/aurora-postgres-cluster-loadtest-failover)

### aurora-global-region-failover ⭐
- **Fault type**: Global database cross-region failover/switchover
- **Injection method**: SSM Automation (Aurora Global DB switchover/failover API)
- **Target**: Aurora Global Database tagged `FIS-Ready=True`
- **Hypothesis**: Regional failover completes with planned switchover (no data loss) or emergency failover (allowing data loss)
- **Applicable architectures**: Multi-region DR with Aurora Global Database
- Embedded: `references/fis-templates/aurora-global-failover/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/aurora-global-region-failover)

### mysql-rds-loadtest-failover
- **Fault type**: CPU overload + Multi-AZ failover under load
- **Injection method**: SSM Automation (EC2 load generator → MySQL queries) + FIS failover
- **Target**: MySQL RDS Multi-AZ instance + EC2 load generator, both tagged `FIS-Ready=True`
- **Hypothesis**: ~25s downtime during failover; apps with proper connection handling reconnect at near 100% success
- **Applicable architectures**: MySQL RDS Multi-AZ workloads
- **⚠️ Creates test tables in target database**
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/mysql-rds-loadtest-failover)

### database-connection-limit-exhaustion ⭐
- **Fault type**: Database connection pool exhaustion
- **Injection method**: SSM Automation (dynamic EC2 creation → DB client → hold connections → cleanup)
- **Target**: RDS/Aurora instances (PostgreSQL, MySQL, SQL Server)
- **Hypothesis**: Circuit breaker activates, graceful degradation, alarm fires, recovery after connections drain
- **Applicable architectures**: Any RDS/Aurora-backed application
- **Key pattern**: Dynamic resource injection — creates ephemeral EC2, exhausts connections, auto-cleans up
- Embedded: `references/fis-templates/database-connection-exhaustion/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/database-connection-limit-exhaustion)

---

## Cache — ElastiCache Redis

### elasticache-redis-connection-failure ⭐
- **Fault type**: Redis connection disruption
- **Injection method**: SSM Automation (Security Group rule removal → restore)
- **Target**: ElastiCache Redis clusters tagged `FIS-Ready=True`
- **Hypothesis**: Circuit breaker activates within 30s, no retry storms, degraded mode without cascading failures, recovery within 60s of restore
- **Applicable architectures**: Any application using ElastiCache Redis
- **Key pattern**: Security Group manipulation for service isolation
- Embedded: `references/fis-templates/redis-connection-failure/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-connection-failure)

### elasticache-redis-primary-node-failover
- **Fault type**: Redis primary node failover (replica promotion)
- **Injection method**: SSM Automation (ElastiCache TestFailover API)
- **Target**: ElastiCache Redis clusters with Multi-AZ + AutomaticFailover, tagged `FIS-Ready=True`
- **Hypothesis**: Apps detect failover and reconnect to new primary within 30s; no data loss; DNS endpoint updates correctly
- **Applicable architectures**: Redis cluster-mode or replication group setups
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-primary-node-failover)

### elasticache-redis-primary-node-reboot
- **Fault type**: Redis primary node reboot
- **Injection method**: SSM Automation (ElastiCache RebootCacheCluster API)
- **Target**: ElastiCache Redis clusters with Multi-AZ, tagged `FIS-Ready=True`
- **Hypothesis**: Brief connection disruption; apps reconnect within 30s; node recovers in 1-3 minutes
- **Applicable architectures**: Any ElastiCache Redis deployment
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-primary-node-reboot)

---

## CDN — CloudFront

### cloudfront-impairment ⭐
- **Fault type**: CloudFront origin failure (S3 origin access blocked)
- **Injection method**: SSM Automation (S3 bucket deny policy → restore)
- **Target**: CloudFront distributions tagged `FIS-Ready=True` with origin groups configured
- **Hypothesis**: CloudFront fails over to secondary origin within 30s; alarm fires within 2-3 min; resumes primary within 30s after restore
- **Applicable architectures**: CloudFront + S3 origin with origin group failover
- **Key pattern**: IAM/resource policy denial for service impairment
- Embedded: `references/fis-templates/cloudfront-impairment/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/cloudfront-impairment)

---

## NoSQL — DynamoDB

### dynamodb-region-impairment
- **Fault type**: DynamoDB complete regional failure (replication pause + access block)
- **Injection method**: FIS native (`aws:dynamodb:global-table-pause-replication`) + SSM Automation (resource policy denial)
- **Target**: DynamoDB global tables tagged `FIS-Ready=True`
- **Hypothesis**: App fails over to healthy region within 2 min; alarm within 5 min; resumes cross-region operation within 5 min after restore
- **Applicable architectures**: Multi-region with DynamoDB Global Tables
- **Note**: Dual-action with 10s stagger to prevent resource policy race conditions
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/dynamodb-region-impairment)

### dynamodb-traffic-blackhole-region-impairment
- **Fault type**: Network-level DynamoDB blackhole
- **Injection method**: FIS native (`aws:network:disrupt-connectivity` scope=dynamodb)
- **Target**: EC2 subnets tagged `FIS-Ready=True`
- **Hypothesis**: Monitoring detects within 2-3 min; failover activates within 10 min; all DynamoDB ops fail with timeout during 10-min impairment
- **Applicable architectures**: VPC-based apps accessing DynamoDB
- **Key difference from dynamodb-region-impairment**: Network-layer (NACL) vs application-layer (resource policy) — tests different failure modes
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/dynamodb-traffic-blackhole-region-impairment)

---

## Messaging — SQS

### sqs-queue-impairment ⭐
- **Fault type**: SQS queue access denied (progressive impairment)
- **Injection method**: SSM Automation (SQS queue policy deny → restore, 4 escalating rounds)
- **Target**: SQS queues tagged `FIS-Ready=True`
- **Hypothesis**: Alarm within 5 min; affected component unavailable but other components unaffected; recovery within 5 min after restore
- **Applicable architectures**: Any application using SQS for async messaging
- **Key pattern**: Progressive impairment — 2min → 5min → 7min → 15min with recovery windows between rounds
- Embedded: `references/fis-templates/sqs-queue-impairment/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sqs-queue-impairment)

---

## Networking

### direct-connect-resiliency
- **Fault type**: Direct Connect virtual interface disconnect
- **Injection method**: FIS native (`aws:directconnect:virtual-interface-disconnect`)
- **Target**: DX virtual interfaces tagged `FIS-Ready=True`, 10-min duration
- **Hypothesis**: Hybrid cloud app maintains connectivity via failover to VPN or secondary DX
- **Applicable architectures**: Hybrid cloud with Direct Connect
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/direct-connect-resiliency)

---

## SAP Workloads

### sap-ebs-pause-database-data
- **Fault type**: EBS volume I/O pause on SAP database data volume
- **Injection method**: FIS native (`aws:ebs:pause-volume-io`)
- **Target**: EC2 hosting SAP DB, tagged `FIS-Application=SAP`, `FIS-SAP-App-Tier=Database`, `FIS-SAP-Database-Type=Data`
- **Hypothesis**: Failover to standby in another AZ within 15-30 min (RTO 30min, RPO ~0)
- **Applicable architectures**: SAP on AWS with HA database clustering
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sap-ebs-pause-database-data)

### sap-ec2-instance-stop-ascs
- **Fault type**: SAP ASCS instance stop
- **Injection method**: FIS native (`aws:ec2:stop-instances`)
- **Target**: EC2 hosting SAP ASCS, tagged `FIS-Application=SAP`, `FIS-SAP-App-Tier=Application`, `FIS-SAP-HA-Node=Primary`
- **Hypothesis**: ASCS fails over to ERS standby within 5-15 min
- **Applicable architectures**: SAP S/4HANA with ASCS/ERS HA clustering
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sap-ec2-instance-stop-ascs)

### sap-ec2-instance-stop-database
- **Fault type**: SAP database instance stop
- **Injection method**: FIS native (`aws:ec2:stop-instances`)
- **Target**: EC2 hosting SAP DB, tagged `FIS-Application=SAP`, `FIS-SAP-App-Tier=Database`, `FIS-SAP-HA-Node=Primary`
- **Hypothesis**: Failover to standby in another AZ within 15-30 min (RTO 30min, RPO ~0)
- **Applicable architectures**: SAP on AWS with HA database clustering
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sap-ec2-instance-stop-database)

---

## Injection Method Summary

| Method | Scenarios | Characteristics |
|--------|-----------|----------------|
| **FIS Native Action** | ec2-terminate, ec2-spot, aurora-failover, dynamodb-blackhole, dx-disconnect, SAP (3) | Simplest; single API call; auto-rollback |
| **SSM Automation** | db-connection-exhaustion, aurora-loadtest, mysql-loadtest, aurora-global, redis-failover, redis-reboot | Multi-step orchestration; can create/destroy resources |
| **Security Group Manipulation** | redis-connection-failure | Blocks traffic at network level; more flexible than FIS network actions |
| **Resource Policy Denial** | cloudfront-impairment, sqs-queue-impairment, dynamodb-region-impairment | Blocks at IAM/resource policy level; simulates service unavailability |
| **Network ACL Manipulation** | dynamodb-traffic-blackhole | FIS manages NACL cloning; subnet-level traffic blocking |
