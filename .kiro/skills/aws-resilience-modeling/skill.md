---
name: aws-resilience-modeling
description: >-
  Conduct comprehensive AWS system architecture resilience analysis and risk identification.
  Use when the user wants to perform architecture analysis, identify failure modes,
  map system components and dependencies, assess risk priorities, or create disaster
  recovery plans. Also use for failure mode analysis, component dependency mapping,
  risk scoring, and mitigation strategy design — even if they don't explicitly say
  "resilience". Automatically invoked for AWS韧性分析, 架构分析, 系统风险评估,
  AWS韧性评估, 可靠性评估, 灾难恢复规划, 故障模式分析, 组件依赖分析, 风险识别.
allowed-tools: Bash(aws *), Bash(gh *), Read, Write, Grep, Glob
model: sonnet
---

# Working Directory

**IMPORTANT**: This skill's working directory is `aws-resilience-modeling/`.
All file paths in the instruction files (references/, scripts/, assets/) are relative to `aws-resilience-modeling/`.

Before executing any commands or file operations, `cd` into `aws-resilience-modeling/`:
```bash
cd aws-resilience-modeling
```

When using Read/Write/Glob tools, always prefix paths with `aws-resilience-modeling/` — for example:
- `aws-resilience-modeling/references/resilience-framework.md` (not `references/resilience-framework.md`)
- `aws-resilience-modeling/scripts/generate-html-report.py` (not `scripts/generate-html-report.py`)
- `aws-resilience-modeling/assets/example-report-template.md` (not `assets/example-report-template.md`)

# Language Router

Detect the language from the user's message:

- **English** → Read and follow the instructions in `aws-resilience-modeling/SKILL_EN.md`
- **中文** → 读取并遵循 `aws-resilience-modeling/SKILL_ZH.md` 中的指令
