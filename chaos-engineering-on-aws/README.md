[**中文**](README_zh.md) | English

# Chaos Engineering on AWS

An AI-powered Agent Skill for running controlled chaos engineering experiments on AWS, covering the full lifecycle: scope definition → resource validation → experiment design → safety checks → controlled execution → analysis & reporting.

## Overview

This skill enables you to systematically validate system resilience through controlled fault injection using **AWS FIS** and optional **Chaos Mesh**, guided by assessment reports from the `aws-resilience-modeling` skill.

## Prerequisites

- Completed assessment report from `aws-resilience-modeling` skill (recommended)
- AWS credentials with FIS permissions
- MCP servers configured (see below)

## MCP Server Setup

### Required

| Server | Package | Purpose |
|--------|---------|---------|
| aws-api-mcp-server | `awslabs.aws-api-mcp-server` | FIS experiment create/run/stop, resource validation |
| cloudwatch-mcp-server | `awslabs.cloudwatch-mcp-server` | Metrics, alarms, stop conditions |

### Optional

| Server | Package | When |
|--------|---------|------|
| eks-mcp-server | `awslabs.eks-mcp-server` | EKS-based architectures |
| chaosmesh-mcp | [RadiumGu/Chaosmesh-MCP](https://github.com/RadiumGu/Chaosmesh-MCP) | Cluster has Chaos Mesh installed |

### Configuration Example

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

> No MCP? The skill falls back to AWS CLI (`aws fis`, `aws cloudwatch`, `kubectl`).

Full setup guide: [MCP_SETUP_GUIDE.md](MCP_SETUP_GUIDE.md)

## Six-Step Workflow

| Step | Name | Output |
|------|------|--------|
| 1 | Define Experiment Scope | `output/step1-scope.json` |
| 2 | Select Target Resources | `output/step2-assessment.json` |
| 3 | Design Hypothesis & Experiment | `output/step3-experiment.json` |
| 4 | Pre-flight Validation | `output/step4-validation.json` |
| 5 | Run Controlled Experiment | `output/step5-experiment.json` + `step5-metrics.jsonl` |
| 6 | Analysis & Report | `output/step6-report.md` + `step6-report.html` |

## Fault Injection Tools

```
AWS Managed Services / Infrastructure  →  AWS FIS
  ├── Node level:    eks:terminate-nodegroup-instances
  ├── Instance:      ec2:terminate/stop/reboot
  ├── Database:      rds:failover, rds:reboot
  ├── Network:       network:disrupt-connectivity
  └── Serverless:    lambda:invocation-add-delay/error

K8s Pod / Container Layer  →  Chaos Mesh (preferred)
  ├── Pod lifecycle: PodChaos (kill/failure)
  ├── Network:       NetworkChaos (delay/loss/partition)
  ├── HTTP:          HTTPChaos (abort/delay)
  └── Resources:     StressChaos (cpu/memory)
```

## Safety Principles

- **Mandatory stop conditions**: Every FIS experiment must bind a CloudWatch Alarm
- **Minimum blast radius**: Never exceed defined constraints
- **Progressive escalation**: Staging → Production, single fault → cascading
- **Reversible**: All experiments require a rollback plan
- **Human confirmation**: Production experiments require double confirmation
- **Monitoring-first**: 🔴 Unready monitoring blocks experiment start

## Execution Modes

| Mode | Description |
|------|-------------|
| Interactive | Pause for confirmation at each step (first run / production) |
| Semi-auto | Confirm at critical checkpoints (staging) |
| Dry-run | Walk through the flow without injecting faults |
| Game Day | Cross-team drill, see [references/gameday.md](references/gameday.md) |

## Example Scenarios

- [EC2 Instance Termination — ASG Recovery](examples/01-ec2-terminate.md)
- [RDS Aurora Failover — Database HA](examples/02-rds-failover.md)
- [EKS Pod Kill — Microservice Self-healing](examples/03-eks-pod-kill.md) (Chaos Mesh)
- [AZ Network Isolation — Multi-AZ Fault Tolerance](examples/04-az-network-disrupt.md)

## Directory Structure

```
chaos-engineering-on-aws/
├── SKILL.md                    # Agent skill definition
├── README.md                   # This file (English)
├── README_zh.md                # Chinese version
├── MCP_SETUP_GUIDE.md          # MCP server setup
├── doc/                        # Additional documentation
├── examples/                   # Experiment scenario examples
├── references/                 # FIS actions, Chaos Mesh CRDs, templates
├── scripts/                    # Monitoring scripts
└── e2e-tests/                  # End-to-end tests
```
