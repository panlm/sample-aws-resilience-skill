# 示例 6: 数据库连接池耗尽 — 连接池韧性验证

**架构模式**：应用 → 连接池 → RDS/Aurora（PostgreSQL、MySQL 或 SQL Server）
**注入方式**：SSM 自动化（动态创建 EC2 负载生成器 → 耗尽连接 → 清理）
**验证点**：熔断器激活、优雅降级、连接池监控、自动恢复

> 模板来源：[aws-samples/fis-template-library/database-connection-limit-exhaustion](https://github.com/aws-samples/fis-template-library/tree/main/database-connection-limit-exhaustion)
> 内嵌模板：`references/fis-templates/database-connection-exhaustion/`

---

## 假设

当数据库连接数接近上限时，应用应当：
- 通过监控检测连接压力（CloudWatch `DatabaseConnections` 指标）
- 在连接完全耗尽前触发前导告警
- 连接仍可用时熔断器保持关闭

当连接完全耗尽时：
- 熔断器应打开，阻止新的连接尝试
- UI 应优雅降级（受影响功能不可用，其他功能正常）
- 告警应在 {y} 分钟内触发并通知运维团队
- 不共享该数据库的其他服务不受影响

连接释放后：
- 熔断器应在 {z} 分钟内关闭
- 稳态 {n} 事务/秒应恢复

### 验证要点

- 数据库连接池监控和告警是否正确配置
- 应用熔断器在连接耗尽时是否按预期工作
- 优雅降级是否防止了级联故障
- 连接可用后恢复是否自动
- 临时负载生成器是否正确清理（无资源泄漏）

## 前置条件

- [ ] VPC 子网可访问的 RDS 或 Aurora 实例
- [ ] 目标数据库已打标签 `FIS-Ready=True`
- [ ] 已创建 FIS IAM Role（使用 `fis-role-iam-policy.json`）
- [ ] 已创建 SSM Automation IAM Role（使用 `ssm-role-iam-policy.json`）
- [ ] 已部署 SSM 自动化文档（`ssm-automation.yaml`）
- [ ] 已配置 `DatabaseConnections` CloudWatch 告警
- [ ] 应用已配置数据库连接熔断器

## 部署

### 1. 部署 IAM 角色

```bash
# FIS 角色
aws iam create-role \
  --role-name FIS-DbConnExhaustion \
  --assume-role-policy-document file://references/fis-templates/database-connection-exhaustion/fis-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name FIS-DbConnExhaustion \
  --policy-name fis-policy \
  --policy-document file://references/fis-templates/database-connection-exhaustion/fis-role-iam-policy.json

# SSM 角色
aws iam create-role \
  --role-name SSM-DbConnExhaustion \
  --assume-role-policy-document file://references/fis-templates/database-connection-exhaustion/ssm-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name SSM-DbConnExhaustion \
  --policy-name ssm-policy \
  --policy-document file://references/fis-templates/database-connection-exhaustion/ssm-role-iam-policy.json
```

### 2. 部署 SSM 自动化文档

```bash
aws ssm create-document \
  --name db-connection-exhaustion \
  --document-type Automation \
  --content file://references/fis-templates/database-connection-exhaustion/ssm-automation.yaml \
  --document-format YAML
```

### 3. 创建 FIS 实验

编辑 `experiment-template.json`，替换：
- `{ACCOUNT_ID}` — AWS 账户 ID
- `{REGION}` — 目标区域
- `{FIS_ROLE_ARN}` — FIS 角色 ARN
- 数据库端点、凭证、引擎类型和连接数参数

```bash
aws fis create-experiment-template \
  --cli-input-json file://references/fis-templates/database-connection-exhaustion/experiment-template.json
```

## 执行

```bash
# 启动实验
aws fis start-experiment --experiment-template-id {TEMPLATE_ID}

# 监控数据库连接数
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

## 观测指标

| 指标 | 来源 | 预期行为 |
|------|------|---------|
| `DatabaseConnections` | CloudWatch RDS | 上升 → 到达上限持平 → 恢复正常 |
| 应用错误率 | 应用指标 | 连接耗尽时升高，恢复后降低 |
| 熔断器状态 | 应用日志 | Closed → Open → Half-Open → Closed |
| 连接池等待时间 | 应用指标 | 随连接池耗尽而增加 |
| 临时 EC2 状态 | EC2 控制台 | 创建 → 运行 → 终止 |

## 清理

SSM 自动化文档会自动处理清理：
- 释放所有持有的数据库连接
- 终止临时 EC2 负载生成器实例
- 正常情况下无需手动清理

如果实验被手动停止或失败：
```bash
# 检查残留 EC2 实例
aws ec2 describe-instances \
  --filters "Name=tag:Purpose,Values=FIS-Connection-Exhaustion" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId'

# 如有则终止
aws ec2 terminate-instances --instance-ids {INSTANCE_ID}
```
