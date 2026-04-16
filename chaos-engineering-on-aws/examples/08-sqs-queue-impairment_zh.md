# 示例 8: SQS 队列不可用 — 消息队列韧性验证

**架构模式**：生产者 → SQS 队列 → 消费者（异步消息）
**注入方式**：SSM 自动化（SQS 队列策略拒绝 → 恢复，4 轮递增）
**验证点**：死信队列处理、消息背压、组件隔离、渐进式故障容忍

> 模板来源：[aws-samples/fis-template-library/sqs-queue-impairment](https://github.com/aws-samples/fis-template-library/tree/main/sqs-queue-impairment)
> 内嵌模板：`references/fis-templates/sqs-queue-impairment/`

---

## 假设

当 SQS 队列访问被拒绝时（渐进式故障 — 4 轮）：
- 第一轮故障后 5 分钟内告警触发
- 组件 A（依赖此队列）应对终端用户不可用
- 其他组件（B、C）应继续正常运行
- 生产者应实现背压（停止接受无法入队的工作）
- 死信队列应捕获失败消息（如已配置）

故障轮次间（恢复窗口）：
- 消息处理应恢复正常
- 积压消息应被处理且不压垮消费者

所有故障轮次完成后：
- 5 分钟内完全恢复
- 无消息丢失（所有消息最终被处理或进入死信队列）

### 验证要点

- SQS 队列不可用时的监控和告警
- 生产者端错误处理和背压机制
- 消费者对间歇性队列访问故障的韧性
- 死信队列配置和消息捕获
- 组件隔离 — 一个队列故障不级联
- 渐进式故障容忍（系统能否应对恶化条件？）

## 前置条件

- [ ] SQS 队列已打标签 `FIS-Ready=True`
- [ ] 已创建 FIS IAM Role
- [ ] 已创建 SSM Automation IAM Role
- [ ] 已部署 SSM 自动化文档
- [ ] 已配置 `NumberOfMessagesSent` 或 `ApproximateNumberOfMessagesVisible` CloudWatch 告警
- [ ] 目标队列已配置死信队列（推荐）
- [ ] 应用健康检查端点可访问

## 渐进式故障时间表

| 轮次 | 阻断时长 | 恢复窗口 | 累计时间 |
|------|---------|---------|---------|
| 1 | 2 分钟 | 3 分钟 | 0-5 分钟 |
| 2 | 5 分钟 | 3 分钟 | 5-13 分钟 |
| 3 | 7 分钟 | 2 分钟 | 13-22 分钟 |
| 4 | 15 分钟 | — | 22-37 分钟 |

**实验总时长：约 37 分钟**

## 部署

### 1. 部署 IAM 角色

```bash
aws iam create-role \
  --role-name FIS-SqsImpairment \
  --assume-role-policy-document file://references/fis-templates/sqs-queue-impairment/fis-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name FIS-SqsImpairment \
  --policy-name fis-policy \
  --policy-document file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-fis-role-iam-policy.json

aws iam create-role \
  --role-name SSM-SqsImpairment \
  --assume-role-policy-document file://references/fis-templates/sqs-queue-impairment/ssm-iam-trust-relationship.json

aws iam put-role-policy \
  --role-name SSM-SqsImpairment \
  --policy-name ssm-policy \
  --policy-document file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-ssm-automation-role-iam-policy.json
```

### 2. 部署 SSM 自动化文档

```bash
aws ssm create-document \
  --name sqs-queue-impairment \
  --document-type Automation \
  --content file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-automation.yaml \
  --document-format YAML
```

### 3. 创建 FIS 实验

```bash
aws fis create-experiment-template \
  --cli-input-json file://references/fis-templates/sqs-queue-impairment/sqs-queue-impairment-tag-based-experiment-template.json
```

## 执行

```bash
aws fis start-experiment --experiment-template-id {TEMPLATE_ID}

# 监控队列可访问性（故障轮次期间应出现 AccessDenied）
watch -n 5 'aws sqs send-message \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --message-body "chaos-test-$(date +%s)" \
  --region {REGION} \
  --no-cli-pager 2>&1 | tail -1'

# 监控队列深度
watch -n 10 'aws sqs get-queue-attributes \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --attribute-names ApproximateNumberOfMessagesVisible ApproximateNumberOfMessagesNotVisible \
  --output table'
```

## 观测指标

| 指标 | 来源 | 预期行为 |
|------|------|---------|
| `NumberOfMessagesSent` | CloudWatch SQS | 故障期间降至 0，轮次间恢复 |
| `ApproximateNumberOfMessagesVisible` | CloudWatch SQS | 生产者缓冲时累积 |
| `NumberOfMessagesReceived` | CloudWatch SQS | 故障期间下降，恢复期间激增 |
| 队列组件应用错误率 | 应用指标 | 故障期间出错，轮次间恢复 |
| 其他组件应用错误率 | 应用指标 | 全程稳定 — 无级联 |
| 死信队列消息数 | CloudWatch SQS (DLQ) | 消息超过重试限制时增加 |

## 清理

SSM 自动化文档会自动从 SQS 队列策略中移除拒绝声明。

如需手动清理：
```bash
# 检查当前队列策略是否有拒绝声明
aws sqs get-queue-attributes \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --attribute-names Policy

# 如仍有拒绝声明，清空策略
aws sqs set-queue-attributes \
  --queue-url "https://sqs.{REGION}.amazonaws.com/{ACCOUNT}/{QUEUE_NAME}" \
  --attributes '{"Policy": ""}'
```
