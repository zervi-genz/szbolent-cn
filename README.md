# szbolent-cn

> **szbolent.cn 部署栈**（云主机，下称 `<DEPLOY_HOST>`）—— 自包含、自主可控。
> 按「服务的主体」命名，不按云商命名；**换云商不改仓名**。

## 定位

本仓**自包含地**声明 `<DEPLOY_HOST>` 这台机器上的全部服务，与产品仓解耦——
`git clone` + CI 部署即可复现整台机器状态，不依赖其他仓、不依赖其他服务器。

| 服务 | 说明 | 归属 |
|---|---|---|
| `wordpress` + `mysql` | 内容线（szbolent.cn 门户 / 博客） | 个人备案线 |
| `pgvector` | 实验向量库（收内网 `127.0.0.1:5433`） | 组织 / 实验 |

> 与 docs 仓《资源-主体-服务对账表》对齐；本仓**只管「这台机器的部署」**，不含产品代码。

## 部署（CI 自动化，零手动 SSH）

```
push main → GitHub Actions → SSH(Secrets) → <DEPLOY_HOST>
  → rsync compose/nginx → docker compose up -d → 健康检查
```

- 触发：`push main` 或手动 `workflow_dispatch`
- 密钥走 GitHub Secrets：`SSH_PRIVATE_KEY` / `SSH_KNOWN_HOSTS` / `MYSQL_*` / `PGVECTOR_PASSWORD`

## 首次初始化（新机器）

```bash
bash scripts/bootstrap.sh
```

## 健康检查

```bash
bash scripts/healthcheck.sh
```

## 收内网惯例

所有容器端口一律 `127.0.0.1:` 绑定（照抄既有 WP 惯例）——
即便安全组误开，公网也打不到。

## 已知跨机依赖（待解耦）

- 门户 `/v1/` 现反代到上游 API（`api.genz.ltd`），属**运行时跨服务器依赖**，见 [`CATALOG.md`](./CATALOG.md)。

## 目录

```
.
├── docker-compose.yml            # 本机全部容器
├── .env.example                  # 环境变量模板
├── nginx/szbolent.conf           # 宿主 nginx 反代
├── scripts/bootstrap.sh          # 首次初始化
├── scripts/healthcheck.sh        # 健康检查
├── .github/workflows/deploy.yml  # CI 部署
├── CATALOG.md                    # 本机服务清单
└── README.md
```
