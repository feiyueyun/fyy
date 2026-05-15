# FYY — 你的 AI 数字员工团队

为一人公司组建 AI 数字员工团队。
他们处理 Listing 上架、客户服务、财务报表、合规检查——交付真实成果，不只是聊天。

## 为什么选择 FYY

独自经营意味着要同时扮演所有角色。
FYY 给你一支 AI 数字员工团队，协作完成复杂任务并交付成果——一份可直接上架的多语言 Listing、一份可发送的合规报告、一条可发出的客户回复。

**按结果付费，不按 Token。** 你的 AI 员工像真人一样按交付物付费。

**你的知识归你所有。** 技能运行在你的设备上。数据不出域，知识产权受保护。

**Agent 中立。** 自带 Agent 框架——CrewAI、LangGraph、Mastra、OpenClaw 或任何兼容 MCP 的 Agent。

## 使用场景

**跨境电商（一人卖家）**
产品调研 → 多语言 Listing → 合规检查 → 客户服务 → 定价策略

**专业服务团队**
数据处理 → 报告生成 → 商业分析 → 发票交付

## 安装

### macOS / Linux（一行命令）

```bash
curl -fsSL https://fyy.dev/install.sh | sh
```

此命令会自动下载 fyy、获取临时 AuthKey、加入官方 Mesh 网络并注册为系统服务。

**Docker / 容器环境：** fyy 自动检测容器并完全适配——无需 systemd，socket/PID 重定向到 tmpfs，守护进程保持运行。详见[容器环境](#容器环境)。

### macOS（Homebrew）

```bash
brew install feiyueyun/tap/fyy
```

### Windows

从 [Releases](https://github.com/feiyueyun/fyy/releases) 下载最新版本。

## 快速开始

```bash
# 加入官方 Mesh 网络（自动签发 AuthKey）
curl -fsSL https://fyy.dev/install.sh | sh

# 或使用预先获取的 AuthKey 加入指定网络
fyy join --auth-key=tskey-auth-xxxxx --server=https://ts.example.com

# 查看状态
fyy status

# 搜索可用技能
fyy skill search "翻译"

# 安装并启动技能
fyy skill install listing-generator
fyy skill start listing-generator
```

## 自托管（CE 社区版）

FYY 社区版（CE）让你免费运行自己的控制平面。通过 Docker Compose 一键部署，几分钟内搭建属于你自己的 Mesh 网络。

完整的 CE 分发包和部署说明见 [`ce/`](ce/) 目录。

快速部署：

```bash
git clone https://github.com/feiyueyun/fyy.git
cd fyy/ce
cp .env.example .env
# 编辑 .env，设置你的密码和密钥
docker compose up -d
```

创建 AuthKey 并连接设备：

```bash
# 创建用于设备接入的 AuthKey
docker compose exec iam-service-1 feiyueyun-admin authkey create

# 在设备上加入网络
fyy join --auth-key=<key> --server=https://<your-server>:8080
```

**CE 文档：** [`ce/README.zh.md`](ce/README.zh.md)

## 基于开放标准构建

FYY 基于一小组开放、可组合的基础模块：

- **Skill Manifest** — 定义 AI 数字员工能力的开放标准（[规范](https://github.com/feiyueyun/skill-manifest-spec)）
- **MCP Gateway** — 连接任何兼容 MCP 的 AI 工具
- **Grants** — 每个 AI 操作的细粒度访问控制
- **WireGuard Mesh** — 加密点对点组网，数据安全有保障

兼容 [Anthropic Agent Skills](https://github.com/anthropics/agent-skills)（74 万+技能）和 [OpenClaw](https://github.com/openclaw) 生态。

## 文档

- [产品概述](docs/product-overview.md)
- [快速开始](docs/quickstart.zh.md)
- [CLI 参考](docs/cli.md)
- [Skill Manifest 标准](docs/skill-manifest.md)
- [框架集成指南](docs/framework-integration.md)

English docs：[README.md](README.md)

## 社区

- [官方网站](https://fyy.dev)
- [Discord](https://discord.gg/feiyueyun)
- [Twitter/X](https://twitter.com/fyy_dev)

## 卸载

```bash
# 移除 fyy 二进制、运行时文件和系统服务
curl -fsSL https://fyy.dev/uninstall.sh | sh

# 同时清除所有状态数据（身份、技能缓存、配置）
curl -fsSL https://fyy.dev/uninstall.sh | sh -s -- --purge
```

详见 [`uninstall.sh`](uninstall.sh)。

## 许可证

FYY CLI 和控制平面 CE 版免费使用。预编译二进制文件基于 [FYY 软件许可证](LICENSE) 分发。
