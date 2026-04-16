# AWS FIS 模板库 — 场景索引

> 来源：[aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library)（commit: e2c94c3）
> 许可：MIT-0
> 同步日期：2026-04-16

本索引收录 AWS FIS Template Library 的全部 19 个实验模板。
每个模板包含可直接部署的 FIS 实验 JSON、IAM 策略，以及（适用时）SSM 自动化文档。

标记 ⭐ 的场景已内嵌到 `references/fis-templates/` 目录，可直接使用。

---

## 计算

### ec2-instances-terminate
- **故障类型**：实例终止
- **注入方式**：FIS 原生（`aws:ec2:terminate-instances`）
- **目标**：标签 `FIS-Ready=True` 的 EC2 实例，选择 25%
- **假设**：ASG 中 25% 实例被终止时，应用保持可用
- **适用架构**：任何使用 Auto Scaling 的 EC2 工作负载
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/ec2-instances-terminate)

### ec2-spot-interruption
- **故障类型**：Spot 实例中断信号
- **注入方式**：FIS 原生（`aws:ec2:send-spot-instance-interruptions`）
- **目标**：标签 `FIS-Ready=True` 的 Spot 实例，25% 选择，4 分钟预警
- **假设**：Spot 实例优雅终止；应用自动在新 Spot 或按需实例上重启，负载均衡器无缝切换
- **适用架构**：使用 Spot 实例的成本优化工作负载
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/ec2-spot-interruption)

### ec2-windows-stop-iis
- **故障类型**：Windows IIS 服务停止
- **注入方式**：SSM 自动化（PowerShell Stop-Service）
- **目标**：安装 SSM Agent 且标签 `FIS-Ready=True` 的 Windows EC2
- **假设**：一台 Windows 实例 IIS 崩溃时，应用保持可用
- **适用架构**：EC2 上的 Windows/.NET 工作负载
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/ec2-windows-stop-iis)

---

## 数据库 — RDS/Aurora

### aurora-cluster-failover
- **故障类型**：Aurora 集群故障转移（读写实例切换）
- **注入方式**：FIS 原生（`aws:rds:failover-db-cluster`）
- **目标**：标签 `FIS-Ready=True` 的 Aurora 集群
- **假设**：故障转移期间短暂请求失败，自动恢复，应用正常继续运行
- **适用架构**：任何多可用区 Aurora 应用
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/aurora-cluster-failover)

### aurora-postgres-cluster-loadtest-failover
- **故障类型**：负载下的 CPU 过载 + 故障转移
- **注入方式**：SSM 自动化（EC2 负载生成器 → pgbench）+ FIS 故障转移
- **目标**：Aurora PostgreSQL 集群 + EC2 负载生成器，均标签 `FIS-Ready=True`
- **假设**：压力下系统以最小中断恢复正常；故障转移后请求成功率接近 100%
- **适用架构**：需要压力+故障转移验证的 Aurora PostgreSQL 工作负载
- **⚠️ 会在目标数据库创建测试表**
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/aurora-postgres-cluster-loadtest-failover)

### aurora-global-region-failover ⭐
- **故障类型**：全局数据库跨区域故障转移/切换
- **注入方式**：SSM 自动化（Aurora Global DB switchover/failover API）
- **目标**：标签 `FIS-Ready=True` 的 Aurora 全局数据库
- **假设**：计划切换无数据丢失；紧急故障转移允许数据丢失
- **适用架构**：Aurora 全局数据库的多区域 DR
- 内嵌：`references/fis-templates/aurora-global-failover/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/aurora-global-region-failover)

### mysql-rds-loadtest-failover
- **故障类型**：负载下的 CPU 过载 + 多可用区故障转移
- **注入方式**：SSM 自动化（EC2 负载生成器 → MySQL 查询）+ FIS 故障转移
- **目标**：MySQL RDS 多可用区实例 + EC2 负载生成器，均标签 `FIS-Ready=True`
- **假设**：故障转移约 25 秒停机；正确实现连接处理的应用接近 100% 成功率重连
- **适用架构**：MySQL RDS 多可用区工作负载
- **⚠️ 会在目标数据库创建测试表**
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/mysql-rds-loadtest-failover)

### database-connection-limit-exhaustion ⭐
- **故障类型**：数据库连接池耗尽
- **注入方式**：SSM 自动化（动态创建 EC2 → 安装 DB 客户端 → 占满连接 → 清理）
- **目标**：RDS/Aurora 实例（PostgreSQL、MySQL、SQL Server）
- **假设**：熔断器激活、优雅降级、告警触发、连接释放后恢复
- **适用架构**：任何 RDS/Aurora 应用
- **关键模式**：动态资源注入 — 创建临时 EC2，耗尽连接，自动清理
- 内嵌：`references/fis-templates/database-connection-exhaustion/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/database-connection-limit-exhaustion)

---

## 缓存 — ElastiCache Redis

### elasticache-redis-connection-failure ⭐
- **故障类型**：Redis 连接中断
- **注入方式**：SSM 自动化（安全组规则删除 → 恢复）
- **目标**：标签 `FIS-Ready=True` 的 ElastiCache Redis 集群
- **假设**：熔断器 30 秒内激活，无重试风暴，降级运行无级联故障，恢复后 60 秒内恢复正常
- **适用架构**：任何使用 ElastiCache Redis 的应用
- **关键模式**：安全组操作实现服务隔离
- 内嵌：`references/fis-templates/redis-connection-failure/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-connection-failure)

### elasticache-redis-primary-node-failover
- **故障类型**：Redis 主节点故障转移（副本提升）
- **注入方式**：SSM 自动化（ElastiCache TestFailover API）
- **目标**：启用多可用区 + 自动故障转移的 Redis 集群，标签 `FIS-Ready=True`
- **假设**：应用 30 秒内检测故障转移并重连新主节点；无数据丢失；DNS 端点正确更新
- **适用架构**：Redis 集群模式或复制组部署
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-primary-node-failover)

### elasticache-redis-primary-node-reboot
- **故障类型**：Redis 主节点重启
- **注入方式**：SSM 自动化（ElastiCache RebootCacheCluster API）
- **目标**：启用多可用区的 Redis 集群，标签 `FIS-Ready=True`
- **假设**：短暂连接中断；应用 30 秒内重连；节点 1-3 分钟恢复
- **适用架构**：任何 ElastiCache Redis 部署
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-primary-node-reboot)

---

## CDN — CloudFront

### cloudfront-impairment ⭐
- **故障类型**：CloudFront 源站故障（S3 源站访问阻断）
- **注入方式**：SSM 自动化（S3 存储桶拒绝策略 → 恢复）
- **目标**：标签 `FIS-Ready=True` 且配置了源站组的 CloudFront 分发
- **假设**：CloudFront 30 秒内故障转移到备用源站；2-3 分钟内告警；恢复后 30 秒内切回主源站
- **适用架构**：CloudFront + S3 源站 + 源站组故障转移
- **关键模式**：IAM/资源策略拒绝实现服务不可用模拟
- 内嵌：`references/fis-templates/cloudfront-impairment/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/cloudfront-impairment)

---

## NoSQL — DynamoDB

### dynamodb-region-impairment
- **故障类型**：DynamoDB 区域级完全故障（复制暂停 + 访问阻断）
- **注入方式**：FIS 原生（`aws:dynamodb:global-table-pause-replication`）+ SSM 自动化（资源策略拒绝）
- **目标**：标签 `FIS-Ready=True` 的 DynamoDB 全局表
- **假设**：应用 2 分钟内故障转移到健康区域；5 分钟内告警；恢复后 5 分钟内恢复跨区域运行
- **适用架构**：DynamoDB 全局表的多区域部署
- **注意**：双操作 10 秒交错执行，防止资源策略竞态条件
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/dynamodb-region-impairment)

### dynamodb-traffic-blackhole-region-impairment
- **故障类型**：网络层 DynamoDB 流量黑洞
- **注入方式**：FIS 原生（`aws:network:disrupt-connectivity` scope=dynamodb）
- **目标**：标签 `FIS-Ready=True` 的 EC2 子网
- **假设**：监控 2-3 分钟内检测；故障转移 10 分钟内激活；10 分钟实验期间所有 DynamoDB 操作超时失败
- **适用架构**：VPC 内访问 DynamoDB 的应用
- **与 dynamodb-region-impairment 区别**：网络层（NACL）vs 应用层（资源策略）— 测试不同故障模式
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/dynamodb-traffic-blackhole-region-impairment)

---

## 消息 — SQS

### sqs-queue-impairment ⭐
- **故障类型**：SQS 队列访问拒绝（渐进式故障）
- **注入方式**：SSM 自动化（SQS 队列策略拒绝 → 恢复，4 轮递增）
- **目标**：标签 `FIS-Ready=True` 的 SQS 队列
- **假设**：5 分钟内告警；受影响组件不可用但其他组件正常；恢复后 5 分钟内恢复
- **适用架构**：任何使用 SQS 异步消息的应用
- **关键模式**：渐进式故障 — 2分钟 → 5分钟 → 7分钟 → 15分钟，轮间有恢复窗口
- 内嵌：`references/fis-templates/sqs-queue-impairment/`
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sqs-queue-impairment)

---

## 网络

### direct-connect-resiliency
- **故障类型**：Direct Connect 虚拟接口断连
- **注入方式**：FIS 原生（`aws:directconnect:virtual-interface-disconnect`）
- **目标**：标签 `FIS-Ready=True` 的 DX 虚拟接口，10 分钟持续
- **假设**：混合云应用通过 VPN 或备用 DX 保持连通
- **适用架构**：使用 Direct Connect 的混合云
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/direct-connect-resiliency)

---

## SAP 工作负载

### sap-ebs-pause-database-data
- **故障类型**：SAP 数据库数据卷 EBS I/O 暂停
- **注入方式**：FIS 原生（`aws:ebs:pause-volume-io`）
- **目标**：标签 `FIS-Application=SAP`, `FIS-SAP-App-Tier=Database`, `FIS-SAP-Database-Type=Data` 的 EC2
- **假设**：15-30 分钟内故障转移到另一可用区备用实例（RTO 30min，RPO ≈0）
- **适用架构**：AWS 上的 SAP HA 数据库集群
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sap-ebs-pause-database-data)

### sap-ec2-instance-stop-ascs
- **故障类型**：SAP ASCS 实例停止
- **注入方式**：FIS 原生（`aws:ec2:stop-instances`）
- **目标**：标签 `FIS-Application=SAP`, `FIS-SAP-App-Tier=Application`, `FIS-SAP-HA-Node=Primary` 的 EC2
- **假设**：ASCS 5-15 分钟内故障转移到 ERS 备用实例
- **适用架构**：SAP S/4HANA ASCS/ERS HA 集群
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sap-ec2-instance-stop-ascs)

### sap-ec2-instance-stop-database
- **故障类型**：SAP 数据库实例停止
- **注入方式**：FIS 原生（`aws:ec2:stop-instances`）
- **目标**：标签 `FIS-Application=SAP`, `FIS-SAP-App-Tier=Database`, `FIS-SAP-HA-Node=Primary` 的 EC2
- **假设**：15-30 分钟内故障转移到另一可用区备用实例（RTO 30min，RPO ≈0）
- **适用架构**：AWS 上的 SAP HA 数据库集群
- [GitHub](https://github.com/aws-samples/fis-template-library/tree/main/sap-ec2-instance-stop-database)

---

## 注入方式汇总

| 方式 | 场景数 | 特点 |
|------|--------|------|
| **FIS 原生动作** | ec2-terminate, ec2-spot, aurora-failover, dynamodb-blackhole, dx-disconnect, SAP (3) | 最简单；单 API 调用；自动回滚 |
| **SSM 自动化** | db-connection-exhaustion, aurora-loadtest, mysql-loadtest, aurora-global, redis-failover, redis-reboot | 多步编排；可创建/销毁资源 |
| **安全组操作** | redis-connection-failure | 网络层阻断流量；比 FIS 网络动作更灵活 |
| **资源策略拒绝** | cloudfront-impairment, sqs-queue-impairment, dynamodb-region-impairment | IAM/资源策略层阻断；模拟服务不可用 |
| **网络 ACL 操作** | dynamodb-traffic-blackhole | FIS 管理 NACL 克隆；子网级流量阻断 |
