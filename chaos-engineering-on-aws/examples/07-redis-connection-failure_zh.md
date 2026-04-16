# 示例 7: ElastiCache Redis 连接中断 — 缓存层韧性验证

**架构模式**：应用 → ElastiCache Redis（复制组）
**注入方式**：SSM 自动化（安全组规则删除 → 恢复）
**验证点**：熔断器、重试风暴抑制、降级模式、缓存重建

> 模板来源：[aws-samples/fis-template-library/elasticache-redis-connection-failure](https://github.com/aws-samples/fis-template-library/tree/main/elasticache-redis-connection-failure)
> 内嵌模板：`references/fis-templates/redis-connection-failure/`

---

## 假设

当 Redis 连接被中断时：
- 应用熔断器应在 30 秒内激活
- 客户端重试风暴应被抑制（无指数放大）
- 应用应在降级模式下继续运行（回退到数据库查询或返回缓存默认值）
- 不向上下游服务产生级联故障
- Redis 连接 CloudWatch 告警应在 2 分钟内触发

当 Redis 连接恢复后：
- 正常运行应在 60 秒内恢复
- 缓存预热/重建应完成且不影响性能
- 熔断器应经历：Open → Half-Open → Closed

### 验证要点

- Redis 客户端熔断器和重试配置
- Cache-aside 模式的回退行为（缓存未命中时查数据库）
- 缓存层不可用时的应用降级策略
- 安全组故障注入作为可复用模式
- 恢复后的缓存重建行为和性能影响

## 前置条件

- [ ] ElastiCache Redis 复制组已打标签 `FIS-Ready=True`
- [ ] 应用实例在同一 VPC，安全组允许 Redis 访问
- [ ] 已创建 FIS IAM Role
- [ ] 已创建 SSM Automation IAM Role
- [ ] 已部署 SSM 自动化文档
- [ ] 应用已配置 Redis 连接熔断器
- [ ] 已配置 Redis 连接相关 CloudWatch 告警

## 部署

### 1. 部署 IAM 角色

```bash
aws iam create-role \
  --role-name FIS-RedisConnFailure \
  --assume-role-policy-document file://references/fis-templates/redis-connection-failure/fis-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name FIS-RedisConnFailure \
  --policy-name fis-policy \
  --policy-document file://references/fis-templates/redis-connection-failure/redis-connection-failure-fis-role-iam-policy.json

aws iam create-role \
  --role-name SSM-RedisConnFailure \
  --assume-role-policy-document file://references/fis-templates/redis-connection-failure/ssm-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name SSM-RedisConnFailure \
  --policy-name ssm-policy \
  --policy-document file://references/fis-templates/redis-connection-failure/redis-connection-failure-ssm-role-iam-policy.json
```

### 2. 部署 SSM 自动化文档

```bash
aws ssm create-document \
  --name redis-connection-failure \
  --document-type Automation \
  --content file://references/fis-templates/redis-connection-failure/redis-connection-failure-automation.yaml \
  --document-format YAML
```

### 3. 创建 FIS 实验

```bash
aws fis create-experiment-template \
  --cli-input-json file://references/fis-templates/redis-connection-failure/redis-connection-failure-experiment-template.json
```

## 执行

```bash
aws fis start-experiment --experiment-template-id {TEMPLATE_ID}

# 监控 Redis 连接
watch -n 5 'redis-cli -h {REDIS_ENDPOINT} ping 2>&1'

# 监控安全组变更
watch -n 10 'aws ec2 describe-security-groups \
  --group-ids {SG_ID} \
  --query "SecurityGroups[0].IpPermissions" \
  --output table'
```

## 观测指标

| 指标 | 来源 | 预期行为 |
|------|------|---------|
| Redis `ping` | redis-cli | 成功 → 超时 → 成功 |
| 应用错误率 | 应用指标 | 短暂升高，降级模式下稳定 |
| 缓存命中率 | 应用指标 | 故障期间降至 0%，恢复后逐渐回升 |
| 数据库查询率 | CloudWatch RDS | Redis 故障期间增加（回退查询） |
| 熔断器状态 | 应用日志 | Closed → Open → Half-Open → Closed |

## 清理

SSM 自动化文档会自动恢复安全组规则。

如需手动清理：
```bash
# 检查安全组规则 — 验证 Redis 端口 (6379) 入站规则已恢复
aws ec2 describe-security-groups \
  --group-ids {SG_ID} \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`6379\`]"

# 如缺失则手动恢复
aws ec2 authorize-security-group-ingress \
  --group-id {SG_ID} \
  --protocol tcp \
  --port 6379 \
  --source-group {APP_SG_ID}
```
