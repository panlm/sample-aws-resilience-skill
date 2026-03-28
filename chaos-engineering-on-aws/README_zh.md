中文 | [English](README.md)

# AWS 混沌工程

AI 驱动的混沌工程 Agent Skill，在 AWS 上运行受控混沌实验，覆盖完整生命周期：目标定义 → 资源验证 → 实验设计 → 安全检查 → 受控执行 → 分析报告。

## 概述

本 Skill 基于 `aws-resilience-modeling` Skill 的评估报告，通过 **AWS FIS** 和可选的 **Chaos Mesh** 进行受控故障注入，系统性验证系统韧性。

## 前置条件

- `aws-resilience-modeling` Skill 生成的评估报告（推荐）
- 具备 FIS 权限的 AWS 凭证
- 已配置 MCP Server（见下方）

## MCP Server 配置

### 必需

| Server | 包名 | 用途 |
|--------|------|------|
| aws-api-mcp-server | `awslabs.aws-api-mcp-server` | FIS 实验创建/执行/停止、资源验证 |
| cloudwatch-mcp-server | `awslabs.cloudwatch-mcp-server` | 指标读取、告警、停止条件 |

### 可选

| Server | 包名 | 适用场景 |
|--------|------|---------|
| eks-mcp-server | `awslabs.eks-mcp-server` | EKS 架构 |
| chaosmesh-mcp | [RadiumGu/Chaosmesh-MCP](https://github.com/RadiumGu/Chaosmesh-MCP) | 集群已安装 Chaos Mesh |

### 配置示例

```json
{
  "mcpServers": {
    "awslabs.aws-api-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.aws-api-mcp-server@latest"],
      "env": { "AWS_REGION": "ap-northeast-1", "FASTMCP_LOG_LEVEL": "ERROR" }
    },
    "awslabs.cloudwatch-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.cloudwatch-mcp-server@latest"],
      "env": { "AWS_REGION": "ap-northeast-1", "FASTMCP_LOG_LEVEL": "ERROR" }
    }
  }
}
```

> 无 MCP 时自动降级为 AWS CLI（`aws fis`、`aws cloudwatch`、`kubectl`）直接调用。

完整配置指南：[MCP_SETUP_GUIDE.md](MCP_SETUP_GUIDE.md)

## 六步流程

| 步骤 | 名称 | 输出文件 |
|------|------|---------|
| 1 | 定义实验目标 | `output/step1-scope.json` |
| 2 | 选择目标资源 | `output/step2-assessment.json` |
| 3 | 定义假设和实验 | `output/step3-experiment.json` |
| 4 | 实验准备就绪检查 | `output/step4-validation.json` |
| 5 | 运行受控实验 | `output/step5-experiment.json` + `step5-metrics.jsonl` |
| 6 | 学习与报告 | `output/step6-report.md` + `step6-report.html` |

## 故障注入工具选择

```
AWS 托管服务 / 基础设施层  →  AWS FIS
  ├── 节点级：   eks:terminate-nodegroup-instances
  ├── 实例级：   ec2:terminate/stop/reboot
  ├── 数据库级： rds:failover, rds:reboot
  ├── 网络级：   network:disrupt-connectivity
  └── Serverless：lambda:invocation-add-delay/error

K8s Pod / 容器层  →  Chaos Mesh（推荐）
  ├── Pod 生命周期：PodChaos (kill/failure)
  ├── 网络：       NetworkChaos (delay/loss/partition)
  ├── HTTP 层：    HTTPChaos (abort/delay)
  └── 资源压力：   StressChaos (cpu/memory)
```

## 安全原则

- **强制停止条件**：每个 FIS 实验必须绑定 CloudWatch Alarm
- **最小爆炸半径**：不超过预设约束限制
- **渐进式**：Staging → Production，单故障 → 级联
- **可逆**：所有实验必须有回滚方案
- **人工确认**：生产实验必须双重确认
- **监控前置**：🔴 监控未就绪时阻断实验启动

## 执行模式

| 模式 | 说明 |
|------|------|
| Interactive | 每步暂停确认（首次运行/生产环境） |
| Semi-auto | 关键节点确认（Staging 推荐） |
| Dry-run | 只走流程不注入故障 |
| Game Day | 跨团队演练，详见 [references/gameday.md](references/gameday.md) |

## 参考场景示例

- [EC2 实例终止 — ASG 恢复验证](examples/01-ec2-terminate.md)
- [RDS Aurora 故障转移 — 数据库 HA 验证](examples/02-rds-failover.md)
- [EKS Pod Kill — 微服务自愈验证](examples/03-eks-pod-kill.md)（Chaos Mesh）
- [AZ 网络隔离 — 多 AZ 容错验证](examples/04-az-network-disrupt.md)

## 目录结构

```
chaos-engineering-on-aws/
├── SKILL.md                    # Agent Skill 定义
├── README.md                   # 英文版
├── README_zh.md                # 本文件（中文版）
├── MCP_SETUP_GUIDE.md          # MCP Server 配置指南
├── doc/                        # 补充文档
├── examples/                   # 实验场景示例
├── references/                 # FIS actions、Chaos Mesh CRD、模板
├── scripts/                    # 监控脚本
└── e2e-tests/                  # 端到端测试
```
