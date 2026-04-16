# 混沌工程工作流指南 — 详细指令

> 本文件包含运行混沌实验的详细步骤指令。
> 主 SKILL 文件 (SKILL_ZH.md) 提供概览和指针。
> 需要某个步骤的完整流程时，read 本文件。

## 前置输入

### 输入方式（M1 支持三种）

1. **方式 1**：指定 Assessment 报告路径 → 解析 Markdown 结构化章节
2. **方式 2**：指定独立 chaos-input 文件 → 解析 `{project}-chaos-input-{date}.md`
3. **方式 3**：指定 `eks-resilience-checker` 的 assessment.json → 解析 K8s 韧性检查结果

无报告 → 引导先运行 `aws-resilience-modeling` Skill。
需 EKS 韧性检查 → 引导先运行 `eks-resilience-checker` Skill。

#### 方式 3：eks-resilience-checker 集成

用户提供 `assessment.json` 时：
1. 读取 `experiment_recommendations` 数组
2. 按 `priority` 排序（P0 → P1 → P2）
3. 每个建议含：`suggested_fault_type`（映射 fault-catalog.yaml）、`target_resources`、`hypothesis`
4. 若同时有方式 1/2 的输入，合并去重
5. 呈现合并列表给用户确认

### 输入完整性检查

```
✅/❌ 项目元数据（账号、Region、环境类型、架构模式、韧性评分）
✅/❌ AWS 资源清单（含完整 ARN）
✅/❌ 业务功能表（依赖链 + RTO/RPO，秒级）
✅/❌ 风险清单（含"可测试"和"建议注入方式"列）
✅/❌ 可测试风险详情（受影响资源 + 建议实验）
✅/❌ 监控就绪度（状态 + 告警 + 指标 + 缺口）
✅/❌ 韧性评分（9 维度完整）
✅/❌ 约束和偏好（如有）
```

缺失处理：ARN 缺失 → AWS CLI 补充扫描；可测试标记缺失 → 自评；监控就绪度缺失 → 假设 🔴 未就绪。

## 状态持久化

文件即状态——每步输出作为检查点：

```
output/
├── checkpoints/
│   ├── step1-scope.json          # 目标系统、资源清单
│   ├── step2-assessment.json     # 弱点、实验建议
│   ├── step3-experiment.json     # FIS 实验模板定义
│   ├── step4-validation.json     # Pre-flight 检查、用户确认
│   └── step5-experiment.json     # FIS 实验状态、ID、时间线
├── monitoring/
│   ├── step5-metrics.jsonl       # 监控脚本流式指标
│   ├── step5-logs.jsonl          # 原始应用日志 JSONL
│   ├── step5-log-summary.json    # 分类日志摘要
│   ├── metric-queries.json       # CloudWatch 指标查询定义
│   └── experiment_id.txt         # FIS 实验 ID
├── templates/                    # 生成的 FIS / Chaos Mesh 模板
├── step6-report.md               # 最终报告
├── step6-report.html             # HTML 报告
├── baseline-{timestamp}.json     # 稳态基线快照
└── state.json                    # 进度元数据
```

启动时检查 `output/state.json`——若存在且未完成 → 提示继续或重新开始。

### state.json v2 三层状态架构

**第一层：state.json**（机器可读，`flock` 并发安全）
```json
{
  "version": 2,
  "workflow": { "current_step": 5, "status": "in_progress" },
  "experiments": [
    { "id": "EXP-001", "status": "completed", "elapsed_seconds": 74, "result": "PASSED" }
  ],
  "background_pids": { "runner": 12345, "monitor": 12346, "log_collector": 12347 }
}
```

**第二层：dashboard.md**（`monitor.sh` 每周期通过 `update-dashboard.sh` 自动生成，IDE Markdown 预览可看）

**第三层：终端 ASCII 看板**（`watch -n 5 -c bash scripts/render-dashboard.sh`）

### 会话中断恢复

Agent 启动时检查 `state.json`：
1. **不存在** → 全新开始
2. **存在且 `status: in_progress`** → 恢复模式：
   - 检查 `background_pids` 中各进程是否存活（`kill -0 $PID`）
   - 查询 FIS/CM 实际状态
   - 存活 → 继续观测；已退出 → 从 `current_step` 恢复或重启

## 步骤 1：定义实验目标

**消费**：风险清单 (2.4) + 项目元数据 (2.1)

1. 读取风险清单，筛选 `Experimentable = ✅` 和 `⚠️ 有前置条件` 的风险
2. 按风险评分排序，推荐 Top N
3. `⚠️ 有前置条件` → 列出前置条件，询问用户
4. 按架构模式调整策略：EKS 微服务 → Pod/网络/服务间故障；Serverless → Lambda 延迟/限流；EC2 → 实例/AZ/数据库；多 Region → 跨区复制/failover
5. 与用户确认范围和优先级
6. 检测 Chaos Mesh：`kubectl get crd | grep chaos-mesh`

**输出**：`output/checkpoints/step1-scope.json`

## 步骤 2：选择目标资源

**消费**：资源清单 (2.2) + 风险详情资源表 (2.5)

1. 从 2.5 提取目标风险的资源 ARN
2. 验证 ARN 可用性（aws describe-* 命令）
3. 补充缺失的关联资源（SG、TG 等）
4. 计算爆炸半径（基于 2.3 的依赖链）
5. 标记资源角色：`注入目标` / `观测目标` / `影响目标`

**输出**：`output/checkpoints/step2-assessment.json`

## 步骤 3：定义假设和实验

**消费**：业务功能 (2.3) + 建议实验 (2.5) + 监控就绪度 (2.6)

### 3.1 稳态假设

基于 2.3 的 RTO/RPO 自动生成：
```
假设：在 {故障} 发生后，系统应在 {目标 RTO}s 内恢复，
请求成功率 >= {阈值}%，数据零丢失。
```

### 3.2 实验设计

基于 2.5 的建议实验生成完整配置。

> **必需输出**：Agent **必须**生成 `output/monitoring/metric-queries.json`（CloudWatch 查询定义），否则 Step 5 的监控将无数据。

### 3.3 监控就绪度

| 状态 | 处理 |
|------|------|
| 🟢 就绪 | 使用现有 Alarm 作为 Stop Condition |
| 🟡 部分就绪 | 创建缺失的 Alarm |
| 🔴 未就绪 | **阻断** — 必须先建立基线监控 |

### 3.4 工具选择

查阅 [references/fault-catalog.yaml](fault-catalog.yaml) 获取完整故障类型目录：
- **AZ/Region 复合故障** → FIS Scenario Library → [scenario-library_zh.md](scenario-library_zh.md)
- **AWS 基础设施层** → FIS 单 Action → [fis-actions_zh.md](fis-actions_zh.md)
- **K8s Pod/容器层** → Chaos Mesh → [chaosmesh-crds_zh.md](chaosmesh-crds_zh.md)

> ⚠️ Pod 层故障优先用 Chaos Mesh，FIS `aws:eks:pod-*` 较慢且 RBAC 复杂。
> ⚠️ FIS Scenario Library 三种创建路径：(1) Console 导出；(2) Content tab + API；(3) JSON skeleton 直接 API。详见 [scenario-library_zh.md](scenario-library_zh.md)。

### 3.5 配置生成策略

MCP 优先 → 降级为 Schema + CLI。
验证链：配置生成 → API 验证 → Dry-run → 用户确认 → 执行

### 3.6 组合实验设计（多 Action FIS 模板）

复合故障场景使用 FIS 原生多 Action 模板 + `startAfter`：

| 模式 | `startAfter` | 效果 |
|------|-------------|------|
| 并行 | _(不设置)_ | 同时启动 |
| 串行 | `["action-A"]` | 在 A 开始后启动 |
| 多依赖 | `["action-A", "action-B"]` | A 和 B 都开始后启动 |
| 定时延迟 | `aws:fis:wait` | 插入间隔 |

参数化模板见 `references/templates/`。示例：[组合 AZ 降级](../examples/05-composite-az-degradation_zh.md)

### 3.7 混合后端实验（FIS + Chaos Mesh）

编排顺序：CM 先注入 → 确认 AllInjected=True → FIS 注入 → 并行监控 → 熔断顺序：先停 FIS，再删 CM。
脚本用法见 [scripts/README.md](../scripts/README.md)

### 3.8 停止条件（必须）

每个实验必须绑定：CloudWatch Alarm + 时间上限 + 手动终止能力。

> ⚠️ Stop condition alarm **必须**设置 `--treat-missing-data notBreaching`，防止实验启动阶段因缺少数据点而误触发停止。

### FIS 成本估算

| 成本项 | 定价 | 示例 |
|--------|------|------|
| FIS action-minutes | $0.10/action-minute | 3 × 5 × $0.10 = $1.50 |
| Chaos Mesh | 免费（集群资源 ~0.5 vCPU） | $0.00 |
| CloudWatch 自定义指标 | $0.30/指标/月 | ~$1-5/月 |

**输出**：`output/checkpoints/step3-experiment.json` + `output/templates/`

## 步骤 4：确保实验准备就绪（Pre-flight）

```
环境：
□ AWS 凭证有效且权限充足
□ FIS IAM Role 已创建
□ 目标资源状态健康

监控：
□ Stop Condition Alarm 就绪
□ output/monitoring/metric-queries.json 存在

安全：
□ 爆炸半径 ≤ 上限
□ 回滚方案已验证
□ 数据备份已确认（涉及数据层时）

团队：
□ 相关方已通知
□ 值班人员就位
```

自动补救：FIS Role 缺失 → 生成创建命令；Alarm 缺失 → 生成 `put-metric-alarm`；监控 🔴 → 阻断。

**输出**：`output/checkpoints/step4-validation.json`

## 步骤 5：运行受控实验

**脚本用法**：见 [scripts/README.md](../scripts/README.md)

### 阶段 0：基线采集 (T-5min)
采集稳态基线，保存为 `output/baseline-{timestamp}.json`。

### 阶段 1：故障注入 + 观测

> ⚠️ **关键**：不要在 Agent 循环中轮询实验状态。使用 `experiment-runner.sh` 后台处理。

启动后台进程后 `wait`：

> ⚠️ **MANDATORY**：每次实验**必须**启动以下全部三个后台进程，
> 无论实验类型（FIS / Chaos Mesh）或预计时长：
> 1. `experiment-runner.sh` — 管理实验生命周期
> 2. `monitor.sh` — 采集 CloudWatch 指标 + 心跳（FIS 模式设 `EXPERIMENT_ID`，CM 模式不设）
> 3. `log-collector.sh` — 采集 Pod 日志用于事后分析
>
> 不要跳过 log-collector，即使实验很短。注入期间的 Pod 日志
> 是错误分类和 MTTR 计算的必要数据（报告 Section 4: Log Analysis）。

```bash
# FIS 实验：
nohup bash scripts/experiment-runner.sh --mode fis --template-id "$TEMPLATE_ID" \
    --region "$REGION" --state-exp-id "EXP-001" --output-dir output/ &
RUNNER_PID=$!

# Chaos Mesh 实验（pod-kill 等一次性注入用 --one-shot）：
nohup bash scripts/experiment-runner.sh --mode chaosmesh \
    --manifest output/templates/pod-kill.yaml --namespace "$NAMESPACE" \
    --one-shot --pod-label "app=petsite" --deployment "petsite-deployment" \
    --state-exp-id "EXP-001" --output-dir output/ &
RUNNER_PID=$!

# Monitor（Chaos Mesh 实验不设 EXPERIMENT_ID，用 DURATION 控制停止）：
export DURATION=300  # CM 模式必须设置，否则无限运行
nohup bash scripts/monitor.sh &
# Log collector（MANDATORY — 所有实验必须启动）：
nohup bash scripts/log-collector.sh --namespace {NS} --services "{svcs}" --mode live ... &
wait $RUNNER_PID
```

> 💡 默认 monitor 采样间隔为 15s。实验 >30 分钟时可设 `INTERVAL=30` 或 `INTERVAL=60`。

退出码：0=完成, 1=失败, 2=超时

> **Monitor 健康检查**：启动后定期检查 `output/monitoring/monitor-status.json`。
> 若 `last_collect` 时间戳超过 2× INTERVAL（~30s），monitor 可能卡住 — 报告用户。
>
> **看板**：启动后台脚本后，告知用户：
> "📊 **看板选项：**
>  1. **IDE 预览**：打开 `output/dashboard.md` 的 Markdown 预览
>  2. **终端（实时）**：在另一个终端运行：
>     ```bash
>     watch -n 5 -c bash scripts/render-dashboard.sh
>     ```
>  3. **快速查看**：`cat output/dashboard.md`
>
> 看板每个监控周期（~15s）自动更新。
> 可以安全关闭本对话 — 实验在后台继续运行。"

### 阶段 2：日志分类
5 类：timeout, connection, 5xx, oom, other

### Duration 覆盖
```bash
jq '.actions[].parameters.duration = "PT2M"' template.json > template-short.json
kubectl patch networkchaos my-exp -n ns --type merge -p '{"spec":{"duration":"2m"}}'
```

### 阶段 3：恢复 (T+duration → T+recovery)
等待自动恢复 → 记录恢复时间 → 与目标 RTO 对比。
日志检测：错误率连续 30s 归零 → 标记恢复。

### 阶段 4：稳态验证
重新采集指标 → 与基线对比 → 确认完全恢复。

### 执行模式

| 模式 | 说明 |
|------|------|
| Interactive | 每步暂停（首次/生产） |
| Semi-auto | 关键节点确认（Staging） |
| Dry-run | 走流程不注入 |
| Game Day | 跨团队演练，见 [references/gameday_zh.md](gameday_zh.md) |

**输出**：`output/checkpoints/step5-experiment.json` + 监控文件

## 步骤 6：学习与报告

### 6.0 结果验证（必须 — 首先执行）

> ⚠️ 写报告前，必须从 AWS/K8s 验证实际实验状态。

### 6.0.5 数据完整性检查（verdict 前必须执行）

在出判定结论前，检查以下数据源是否完整：

| 数据源 | 文件 | 缺失影响 |
|--------|------|---------|
| CloudWatch 指标 | `step5-metrics.jsonl` | 无法量化 SLO 合规 |
| 应用日志 | `step5-logs.jsonl` | 无法做错误分类 |
| 日志摘要 | `step5-log-summary.json` | 无 MTTR 计算 |
| 基线数据 | `baseline-*.json` | 无对比基准 |

判定映射：
- **数据完整** → PASSED ✅ 或 FAILED ❌（基于假设验证）
- **部分数据缺失但有关键指标** → OBSERVED ⚠️（标注数据限制）
- **关键数据全部缺失** → BLOCKED 🚫（无法判定）

**FIS 结果映射**：
| FIS `state.status` | 报告结果 |
|---------------------|---------|
| `completed` | 检查假设 → PASSED ✅ 或 FAILED ❌ |
| `failed` | **FAILED ❌**（FIS 本身错误） |
| `stopped` / `cancelled` | **ABORTED ⚠️** |

`completed` 还需检查：假设是否被违反、RTO 是否超出 → 任一 → FAILED ❌。

**Chaos Mesh 结果映射**：
| 场景 | 报告结果 |
|------|---------|
| `AllInjected=True` + `AllRecovered=True` | 检查假设 |
| `AllInjected=False` | **FAILED ❌** |
| `AllRecovered=False`（超时后） | **FAILED ❌** |
| CR 不存在 | **ABORTED ⚠️** |

### 6.1 分析

报告包含：
1. 结果摘要：`总计: {N} = 通过: {P} + 失败: {F} + 中止: {A}`
2. 稳态假设 vs 实际表现对比表
3. SLO/RTO 合规表
4. MTTR 阶段分析
5. 应用日志分析（错误时间线、模式、传播、恢复）
6. 韧性评分更新
7. 新发现风险回填
8. 改进建议（P0/P1/P2）
9. 清理状态

报告模板详情：[references/report-templates_zh.md](report-templates_zh.md)

**输出**：`output/step6-report.md` + `output/step6-report.html`

---

## 进阶：SSM 自动化编排实验

步骤 1-5 中的示例使用单步 FIS 操作（终止实例、故障转移集群等）。
对于更复杂的故障注入场景，FIS 可以触发 SSM 自动化文档来编排多步实验。
以下三种关键模式来自 [aws-samples/fis-template-library](https://github.com/aws-samples/fis-template-library)：

### 模式 1：动态资源注入

创建临时基础设施注入故障，然后自动清理。

**流程：**
1. FIS 触发 SSM 自动化文档
2. SSM 创建临时资源（如 EC2 实例作为负载生成器）
3. SSM 安装工具并在临时资源上执行故障注入
4. SSM 等待指定持续时间
5. SSM 清理（释放资源，终止临时实例）

**示例**：`database-connection-limit-exhaustion` — 动态创建 EC2，安装数据库客户端，
打开连接耗尽连接池，保持，然后释放并终止实例。

**适用场景**：故障需要目标环境中不存在的负载生成器或中间节点（如连接压力、流量注入）。

参见：`references/fis-templates/database-connection-exhaustion/`

### 模式 2：安全组操作

通过修改安全组规则阻断特定服务间流量。

**流程：**
1. SSM 发现目标资源及其安全组
2. SSM 记录原始安全组规则（用于回滚）
3. SSM 删除/修改入站规则以阻断特定流量
4. 保持中断指定持续时间
5. SSM 恢复原始安全组规则

**示例**：`elasticache-redis-connection-failure` — 删除安全组入站规则阻断
应用→Redis 流量，在服务级别模拟网络隔离。

**相比 FIS 原生网络操作的优势**：FIS `aws:network:disrupt-connectivity` 在子网级别操作（通过 NACL）。
安全组操作针对特定服务连接，允许更精确的故障注入（如阻断 Redis 但不影响同一子网的 DynamoDB）。

参见：`references/fis-templates/redis-connection-failure/`

### 模式 3：资源策略拒绝

通过在 IAM/资源策略层应用拒绝策略来模拟服务不可用。

**流程：**
1. SSM 通过标签发现目标资源
2. SSM 向资源的访问策略添加全拒绝声明
3. 该资源上的所有 API 操作返回 `AccessDenied`
4. 持续时间结束后，SSM 移除拒绝声明
5. 服务恢复正常运行

**示例**：`sqs-queue-impairment` — 向 SQS 队列策略添加拒绝策略。
`cloudfront-impairment` — 向 S3 源站存储桶策略应用拒绝策略。

**优势**：适用于任何支持资源策略的 AWS 服务。可在不进行网络层中断的情况下模拟服务不可用。
支持渐进式故障（递增拒绝轮次+恢复窗口）。

参见：`references/fis-templates/sqs-queue-impairment/`、`references/fis-templates/cloudfront-impairment/`

### 模式选择指南

| 模式 | 最适合 | 复杂度 | 回滚安全性 |
|------|--------|--------|-----------|
| 动态资源注入 | 负载/连接压力测试 | 高 | 高（临时资源自动清理） |
| 安全组操作 | 服务级网络隔离 | 中 | 中（必须恢复精确的原始规则） |
| 资源策略拒绝 | 服务不可用模拟 | 低 | 高（移除拒绝声明即可） |

> **注意**：三种模式都需要 FIS 和 SSM 两个 IAM 角色。`references/fis-templates/` 中的内嵌模板
> 包含所需的 IAM 策略和信任关系文件。
