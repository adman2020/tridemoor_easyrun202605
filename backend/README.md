# 驰陌 StrideMoor — 后端服务

## 快速启动

### 1. 启动基础设施（Docker）

```bash
# 在项目根目录执行
docker-compose up -d
```

启动后：
- MySQL 8.0: `localhost:3306`
- Redis 7: `localhost:6379`
- MinIO: `localhost:9000` (控制台: `localhost:9001`)

### 2. 初始化数据库

MySQL 容器首次启动时会自动执行 `backend/migrations/001_init.up.sql` 创建所有表。

```bash
# 验证数据库
docker exec -it stridemoor-mysql mysql -u stridemoor -p stridemoor
# 密码: stridemoor_pass_2026
# SQL> SHOW TABLES;
```

### 3. 启动后端服务

```bash
cd backend
go mod tidy
go run ./cmd/server
```

服务启动后访问：`http://localhost:8080/health`

### 4. Docker 构建

```bash
cd backend
make docker
```

## 项目结构

```
backend/
├── cmd/server/         # 主入口
├── configs/            # 配置文件
├── internal/
│   ├── model/          # GORM 数据模型
│   ├── repository/     # DAO 数据访问层
│   ├── service/        # 业务逻辑层
│   ├── handler/        # HTTP Handler
│   └── middleware/     # 中间件
├── pkg/
│   └── database/       # 数据库连接封装
├── migrations/         # SQL 迁移脚本
├── Dockerfile
├── Makefile
└── go.mod
```

## 数据库表清单

| 表名 | 说明 | 记录量预估 |
|------|------|-----------|
| `users` | 用户表 | ~10万 |
| `routes` | 路线表 | ~5万 |
| `runs` | 跑步记录 | ~100万 |
| `run_splits` | 分段数据 | ~500万 |
| `run_samples` | 秒级采样（RANGE 按月分区） | ~1亿 |
| `route_favorites` | 路线收藏 | ~50万 |
| `challenges` | 挑战记录 | ~20万 |
| `comparisons` | 对比报告 | ~20万 |
| `friendships` | 好友关系 | ~200万 |
| `route_leaderboards` | 排行榜快照 | ~500万 |
