# FYY 社区版 (CE)

通过 Docker Compose 免费部署你自己的 FYY 私有技能市场。
CE 分发包包含运行私有 Agent Skill Mesh 所需的所有核心服务。

## 架构

CE 控制平面包含以下服务：

| 服务 | 角色 | 端口 |
|------|------|------|
| PostgreSQL 16 | 主数据库 | 5432 (内部) |
| Redis 7 | 缓存、限流、分布式锁 | 6379 (内部) |
| NATS JetStream | 事件总线 | 4222 (内部) |
| IAM Service | 认证、Agent 身份、JWT | 50051 (gRPC) |
| Device Service | 设备注册、IP 分配 | 50052 (gRPC) |
| Mesh Controller | WireGuard 组网、NetworkMap | 8080 (HTTP) |
| Open API Service | REST + WebSocket 网关 | 8090 (HTTP) |
| Policy Service | Grants 策略管理 | 50060 (gRPC) |
| Policy Compiler | Grants → PacketFilter | 50061 (gRPC) |
| Skill Service Center | 技能注册中心 | 50080 (gRPC) |
| Tag Service | 标签管理 | 50090 (gRPC) |
| Follow Service | 关注/好友 | 50100 (gRPC) |
| DERP Relay | NAT 穿透中继 | 8443 (HTTPS), 3478 (STUN) |

## 环境要求

- Docker 24+
- Docker Compose v2
- 最低配置：4 GB 内存、20 GB 磁盘、2 核 CPU
- 推荐配置：8 GB 内存、50 GB 磁盘、4 核 CPU

## 快速开始

### 1. 获取 CE 分发包

```bash
git clone https://github.com/feiyueyun/fyy.git
cd fyy/ce
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，设置强密码：

```bash
# 必填：设置强密码
POSTGRES_PASSWORD=<你的强密码>
PLATFORM_ADMIN_PASSWORD=<你的强密码>
JWT_MASTER_KEY=<使用 openssl rand -hex 32 生成>
MINIO_SECRET_KEY=<你的强密码>
```

生成 JWT 主密钥：

```bash
openssl rand -hex 32
```

### 3. 启动平台

```bash
docker compose up -d
```

等待 30-60 秒让所有服务初始化完成。检查状态：

```bash
docker compose ps
```

所有服务应显示 `Up` 或 `running`。

### 4. 访问控制平面

控制平面暴露以下端点：

| 端点 | 端口 | 用途 |
|------|------|------|
| Mesh Controller | 8080 | 设备注册 (ts2021) |
| Open API Service | 8090 | REST API + WebSocket |

### 5. 创建 AuthKey

```bash
docker compose exec iam-service-1 feiyueyun-admin authkey create
```

输出格式为 `tskey-auth-<base64>`，用于设备接入。

### 6. 连接设备

在安装了 fyy CLI 的任何机器上：

```bash
fyy join --auth-key=<key> --server=http://<服务器IP>:8080
```

如果你的服务器有公网域名和 TLS，使用 `https://`：

```bash
fyy join --auth-key=<key> --server=https://ts.your-domain.com
```

### 7. 验证

```bash
# 服务器上：查看已注册设备
docker compose exec iam-service-1 feiyueyun-admin device list

# 设备上：查看连接状态
fyy status
```

## 配置

### 启用自动签发 AuthKey

自动签发默认启用（`.env` 中 `AUTHKEY_AUTO_ENABLED=true`）。
设备可通过以下方式自动获取临时 AuthKey：

```bash
curl -X POST http://<服务器IP>:8090/v1/auth/auto-provision-authkey \
  -H "Content-Type: application/json" -d '{}'
```

关闭：在 `.env` 中设置 `AUTHKEY_AUTO_ENABLED=false` 并重启。

### TLS / HTTPS

生产环境建议在控制平面前面加反向代理（nginx、Caddy）配置有效的 TLS 证书。

### 数据持久化

所有数据存储在 Docker 卷中。定期备份：

```bash
# 备份 PostgreSQL
docker compose exec postgres pg_dump -U feiyueyun feiyueyun > backup.sql

# 备份卷
docker run --rm -v fyy_postgres_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/postgres_backup.tar.gz -C /data .
```

## 日常管理

```bash
# 查看特定服务日志
docker compose logs -f iam-service-1

# 查看所有日志
docker compose logs -f

# 重启服务
docker compose restart iam-service-1

# 停止平台
docker compose down

# 停止并清除所有数据（警告：不可逆）
docker compose down -v
```

## 升级

```bash
# 拉取最新镜像
docker compose pull

# 使用新镜像重启
docker compose up -d
```

## 故障排查

**服务启动失败**：查看日志 — `docker compose logs`。大多数问题是缺少环境变量或端口冲突。

**数据库迁移失败**：iam-service 在启动时执行迁移。查看日志 — `docker compose logs iam-service-1`。

**设备无法连接**：检查防火墙是否允许端口 8080（和 DERP 8443）的入站流量。确认 `.env` 中 `FYY_CONTROL_PLANE_HOST` 匹配服务器的公网地址。

**自动签发触发限流**：默认每 IP 每分钟 10 次请求。通过 `AUTHKEY_AUTO_RATE_LIMIT` 环境变量调整。

## 支持

- [GitHub Issues](https://github.com/feiyueyun/fyy/issues)
- [Discord](https://discord.gg/feiyueyun)
- [文档](../docs/)
