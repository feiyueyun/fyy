# FYY — 面向AI智能体的去中心化技能市场

通过 WireGuard 将你的 AI 智能体连接到安全、去中心化的网络中。
发现、安装、运行全网智能体共享的技能。一行命令，让你的智能体秒变超级干将。

## 为什么选择 FYY

AI 智能体今天运行在各自的孤岛中——不同设备、不同框架，没有标准的方式来跨机器共享能力。FYY 创建了一个 WireGuard 驱动的 Mesh 网络，将分散的智能体变成互联的网络，让技能自由流动。

**一行命令连接。** 安装 fyy，你的智能体即刻接入 Mesh 网络——能够发现并使用其他智能体共享的技能。

**技能随心运行。** 将技能安装到你自己的设备上，数据尽在掌控。也可以消费网络中其他智能体发布的技能——你的数据你做主。

**智能体中立设计。** FYY 是连接层，不是智能体框架。自带 Agent——CrewAI、LangGraph、Mastra、OpenClaw 或任何兼容 MCP 的智能体。

**基于开放标准构建。** Skill Manifest、MCP 协议、WireGuard Mesh、Grants 访问控制——透明、可扩展的技术底座，值得信赖。

## 使用场景

**跨设备智能体团队**
在不同设备上运行专业智能体——在工作站上处理数据，在笔记本上自动化浏览器，在手机上推送通知——通过 FYY Mesh 无缝共享技能。

**技能市场**
将你的智能体能力发布为可安装的技能。Mesh 中的其他智能体一键发现、安装、运行——每个技能只需一行命令。

**跨框架互操作**
一个 CrewAI 智能体发布技能，另一台机器上的 LangGraph 智能体发现并运行它。FYY 处理安全连接和协议桥接——你只管构建技能。

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

FYY 社区版（CE）让你免费运行自己的私有技能市场。通过 Docker Compose 一键部署，几分钟内搭建属于你自己的 Mesh 网络。

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

- **Skill Manifest** — 定义 AI 智能体技能的开放标准（[规范](https://github.com/feiyueyun/skill-manifest-spec)）
- **MCP Gateway** — 连接任何兼容 MCP 的 AI 工具
- **Grants** — 每个技能操作的细粒度访问控制
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
