# AWS MCP 服务器设置指南

## 快速安装

### 1. 安装 MCP 服务器

```bash
# 安装核心 AWS MCP 服务器
npm install -g mcp-aws-manager
npm install -g @imazhar101/mcp-aws-server
npm install -g @aashari/mcp-server-aws-sso
```

### 2. 配置 Claude Desktop

创建或编辑配置文件：`~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "aws-manager": {
      "command": "node",
      "args": [
        "/opt/homebrew/lib/node_modules/mcp-aws-manager/bin/mcp-aws-manager-mcp.js"
      ],
      "env": {
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      }
    },
    "aws-core": {
      "command": "mcp-aws",
      "env": {
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      }
    },
    "aws-sso": {
      "command": "mcp-aws-sso",
      "env": {
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1",
        "TRANSPORT_MODE": "stdio"
      }
    }
  }
}
```

### 3. 配置 AWS 凭证

确保您的 AWS 凭证已配置：

```bash
# 方式 1：使用 AWS CLI 配置
aws configure

# 方式 2：手动编辑 ~/.aws/credentials
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

[default]
region = us-east-1
```

### 4. 重启 Claude Desktop

```bash
# 完全退出 Claude Desktop
killall "Claude" 2>/dev/null

# 重新启动 Claude Desktop 应用
```

---

## MCP 服务器功能

### aws-manager (mcp-aws-manager)
- ✅ EC2 实例清单和管理
- ✅ Lambda 函数操作
- ✅ SSM 命令执行
- ✅ 运行时快照

**适用场景：** EC2/Lambda 的韧性分析

---

### aws-core (@imazhar101/mcp-aws-server)
- ✅ DynamoDB 表管理
- ✅ Lambda 函数管理
- ✅ API Gateway 管理
- ✅ API Gateway V2 管理

**适用场景：** 无服务器架构的韧性分析

---

### aws-sso (@aashari/mcp-server-aws-sso)
- ✅ AWS SSO 设备认证
- ✅ 多账户/多角色管理
- ✅ 安全执行 AWS CLI 命令
- ✅ EC2 和 SSM 客户端

**适用场景：** 多账户环境、需要执行自定义 AWS CLI 命令

---

## 故障排查

### 问题 1：MCP 服务器未连接

**检查步骤：**
```bash
# 1. 验证 npm 包已安装
npm list -g mcp-aws-manager @imazhar101/mcp-aws-server @aashari/mcp-server-aws-sso

# 2. 验证配置文件格式正确
cat ~/.config/claude/claude_desktop_config.json | jq .

# 3. 检查 Claude Desktop 日志
# macOS: ~/Library/Logs/Claude/
```

### 问题 2：AWS 认证失败

**检查步骤：**
```bash
# 验证 AWS 凭证
aws sts get-caller-identity

# 检查配置的 profile 和 region
aws configure list
```

### 问题 3：权限不足

**最小 IAM 权限策略（只读访问）：**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "rds:Describe*",
        "s3:List*",
        "lambda:List*",
        "lambda:Get*",
        "dynamodb:List*",
        "dynamodb:Describe*",
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "logs:Describe*",
        "eks:List*",
        "eks:Describe*",
        "elbv2:Describe*",
        "apigateway:GET"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 高级配置

### 多 AWS 账户配置

```json
{
  "mcpServers": {
    "aws-production": {
      "command": "mcp-aws-sso",
      "env": {
        "AWS_PROFILE": "production",
        "AWS_REGION": "us-east-1",
        "TRANSPORT_MODE": "stdio"
      }
    },
    "aws-staging": {
      "command": "mcp-aws-sso",
      "env": {
        "AWS_PROFILE": "staging",
        "AWS_REGION": "us-west-2",
        "TRANSPORT_MODE": "stdio"
      }
    }
  }
}
```

### 使用 AWS SSO

```bash
# 配置 AWS SSO
aws configure sso

# 在配置文件中使用 SSO profile
{
  "mcpServers": {
    "aws-sso": {
      "command": "mcp-aws-sso",
      "env": {
        "AWS_PROFILE": "my-sso-profile",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

---

## 参考资源

- [mcp-aws-manager GitHub](https://github.com/soybin/mcp-aws-manager)
- [@imazhar101/mcp-aws-server NPM](https://www.npmjs.com/package/@imazhar101/mcp-aws-server)
- [@aashari/mcp-server-aws-sso GitHub](https://github.com/aashari/mcp-server-aws-sso)
- [Model Context Protocol 文档](https://modelcontextprotocol.io/)
- [AWS CLI 配置文档](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

---

**更新日期：** 2026-03-03
