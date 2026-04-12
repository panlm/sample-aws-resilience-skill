---
name: rma-assessment-assistant
description: >-
  Intelligent RMA (Reliability, Maintainability, Availability) Resilience Maturity Assessment
  Assistant. Conducts interactive maturity questionnaire based on AWS Well-Architected
  Framework to evaluate application resilience maturity level, automatically generating
  assessment reports and improvement roadmaps. Supports compact version (36 core questions)
  and full version (80 questions). Use this skill when users want to run an RMA maturity
  survey, answer assessment questions, benchmark maturity levels, evaluate resilience
  readiness, or check maturity scores — even if they just say "check how resilient my app is"
  or "韧性评估" or "成熟度评估" or "成熟度问卷".
allowed-tools: Read, Write, Grep, Glob, AskUserQuestion
model: sonnet
---

# Working Directory

**IMPORTANT**: This skill's working directory is `aws-rma-assessment/`.
All file paths in the instruction files are relative to `aws-rma-assessment/`.

Before executing any commands or file operations, `cd` into `aws-rma-assessment/`:
```bash
cd aws-rma-assessment
```

When using Read/Write/Glob tools, always prefix paths with `aws-rma-assessment/`.

# Language Router

Detect the language from the user's message:

- **English** → Read and follow the instructions in `aws-rma-assessment/SKILL_EN.md`
- **中文** → 读取并遵循 `aws-rma-assessment/SKILL_ZH.md` 中的指令
