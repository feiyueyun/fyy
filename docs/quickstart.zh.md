# 快速开始

5 分钟上手 FYY。

## 安装

### 一行命令安装（macOS / Linux）

```bash
curl -fsSL https://fyy.dev/install.sh | sh
```

此命令自动下载 fyy、获取临时 AuthKey、加入官方 Mesh 网络并注册为系统服务（开机自启）。

**CE 用户**（自托管控制平面）：在加入前设置服务器地址：

```bash
curl -fsSL https://fyy.dev/install.sh | FYY_SERVER=https://ts.example.com sh
```

### macOS（Homebrew）

```bash
brew install feiyueyun/tap/fyy
```

### 手动下载

从 [Releases](https://github.com/feiyueyun/fyy/releases) 下载对应平台的二进制文件。

| 平台 | 二进制文件 |
|------|-----------|
| Linux amd64 | `fyy-linux-amd64` |
| Linux arm64 | `fyy-linux-arm64` |
| macOS amd64 | `fyy-darwin-amd64` |
| macOS arm64 | `fyy-darwin-arm64` |

```bash
# 示例：Linux amd64
curl -fsSL -o fyy "https://github.com/feiyueyun/fyy/releases/latest/download/fyy-linux-amd64"
chmod +x fyy
sudo mv fyy /usr/local/bin/fyy
# fyy 和 fyyd 是同一个二进制文件
ln -sf /usr/local/bin/fyy /usr/local/bin/fyyd
```

### Docker / 容器环境

fyy 自动检测容器并完全适配——无需 systemd，socket/PID 放到 tmpfs，守护进程保持运行。

**自动配置说明：**

| 配置项 | 自动值 | 原因 |
|---|---|---|
| `FYY_RUN_DIR` | `/tmp/fyy-run` | tmpfs 用于 Unix socket + PID 文件（Docker 卷不支持 socket 权限修改） |
| 守护进程 | 后台保持 | 容器内无 systemd/launchd |
| 系统服务 | 跳过 | 容器运行时负责重启策略 |
| PID 文件 | 安全处理 | 守护进程正确处理残留 PID 和自身 PID 的边界情况 |

```bash
# 容器内一键安装
curl -fsSL https://fyy.dev/install.sh | sh
```

**重启后保持运行**，在 entrypoint 中添加：

```bash
export FYY_RUN_DIR="/tmp/fyy-run"
mkdir -p "${FYY_RUN_DIR}" 2>/dev/null || true
nohup fyyd --foreground > /tmp/fyyd.log 2>&1 &
```

**持久化身份和技能数据**，挂载卷并设置 `FYY_STATE_DIR`：

```bash
export FYY_RUN_DIR="/tmp/fyy-run"
export FYY_STATE_DIR="/data/fyy"
mkdir -p "${FYY_RUN_DIR}" "${FYY_STATE_DIR}" 2>/dev/null || true
nohup fyyd --foreground > /tmp/fyyd.log 2>&1 &
```

**OpenClaw cron 集成** —— 通过网关内置定时任务实现自动恢复，详见[容器环境](../README.zh.md#容器环境)。

Docker Compose sidecar 详见[容器环境](../README.zh.md#容器环境)。

**自定义配置：**

```bash
curl -fsSL https://fyy.dev/install.sh | \
  FYY_RUN_DIR=/tmp/fyy-run \
  FYY_STATE_DIR=/data/fyy \
  sh
```

### 验证安装

```bash
fyy --version
```

## 加入网络

### 官方平台（零交互）

安装脚本会自动处理所有步骤。手动加入方式：

```bash
# 从自动签发端点获取临时 AuthKey
curl -X POST https://api.fyy.dev/v1/auth/auto-provision-authkey \
  -H "Content-Type: application/json" -d '{}'

# 使用返回的密钥加入
fyy join --auth-key=tskey-auth-xxxxx --server=https://ts.fyy.dev
```

AuthKey 一次性使用，有效期 5 分钟。自动签发端点无需认证。

### CE / 自托管

在控制平面服务器上创建 AuthKey：

```bash
docker compose exec iam-service-1 feiyueyun-admin authkey create
```

在设备上用密钥加入：

```bash
fyy join --auth-key=<key> --server=https://<服务器地址>:8080
```

## 查看状态

```bash
fyy status
```

显示网络连接状态、分配的 tailnet IP、MagicDNS 名称、活跃技能数量和守护进程运行时间。

## 发现和使用技能

```bash
# 搜索可用技能
fyy skill search "翻译"

# 列出已安装技能
fyy skill list

# 安装技能
fyy skill install listing-generator

# 启动技能
fyy skill start listing-generator

# 停止运行中的技能
fyy skill stop listing-generator
```

## 自托管（CE 社区版）

FYY 社区版让你在自己的基础设施上运行完整的控制平面。

### 环境要求

- Docker 24+
- Docker Compose v2
- 最低：4 GB 内存、20 GB 磁盘

### 快速部署 CE

```bash
# 获取 CE 分发包
git clone https://github.com/feiyueyun/fyy.git
cd fyy/ce

# 配置环境
cp .env.example .env
# 编辑 .env：设置 POSTGRES_PASSWORD、PLATFORM_ADMIN_PASSWORD、JWT_MASTER_KEY

# 启动平台
docker compose up -d
```

这会启动所有核心服务：PostgreSQL、Redis、NATS、IAM Service、Device Service、Mesh Controller 等。

### 创建 AuthKey

```bash
docker compose exec iam-service-1 feiyueyun-admin authkey create
```

使用输出的密钥通过 `fyy join` 连接设备。

### 连接设备

在每台安装了 fyy CLI 的设备上：

```bash
fyy join --auth-key=<key> --server=https://<服务器IP>:8080
```

### 管理 CE 部署

```bash
# 查看日志
docker compose logs -f

# 停止平台
docker compose down

# 更新到新版本
docker compose pull
docker compose up -d
```

详细的 CE 文档见 [`ce/README.zh.md`](../ce/README.zh.md)。

## 下一步

- [CLI 参考](cli.md) — 完整命令文档
- [Skill Manifest](skill-manifest.md) — 了解如何定义 AI 数字员工能力
- [框架集成指南](framework-integration.md) — 连接你现有的 AI Agent
