---
name: chaos-engineering-on-aws
description: Run chaos engineering experiments on AWS using FIS (+ optional Chaos Mesh) with automated monitoring and rollback. Use when the user wants to validate system resilience through controlled fault injection, run chaos experiments on AWS infrastructure, test failure recovery, or execute Game Day exercises. Triggers on 混沌工程, chaos engineering, fault injection, FIS experiment, 韧性验证, resilience testing, Game Day.
allowed-tools: Bash(aws *), Bash(kubectl *), Bash(bash *), Bash(cat *), Bash(jq *), Bash(nohup *), Read, Write, Grep, Glob, awslabs.aws-api-mcp-server, awslabs.cloudwatch-mcp-server, awslabs.eks-mcp-server, chaosmesh-mcp
model: sonnet
---

# Working Directory

**IMPORTANT**: This skill's working directory is `chaos-engineering-on-aws/`.
All file paths in the instruction files (output/, scripts/, references/, examples/) are relative to `chaos-engineering-on-aws/`.

Before executing any commands or file operations, `cd` into `chaos-engineering-on-aws/`:
```bash
cd chaos-engineering-on-aws
```

When using Read/Write/Glob tools, always prefix paths with `chaos-engineering-on-aws/` — for example:
- `chaos-engineering-on-aws/output/state.json` (not `output/state.json`)
- `chaos-engineering-on-aws/scripts/monitor.sh` (not `scripts/monitor.sh`)
- `chaos-engineering-on-aws/references/fault-catalog.yaml` (not `references/fault-catalog.yaml`)

# Language Router

Detect the language from the user's message:

- **English** → Read and follow the instructions in `chaos-engineering-on-aws/SKILL_EN.md`
- **中文** → 读取并遵循 `chaos-engineering-on-aws/SKILL_ZH.md` 中的指令
