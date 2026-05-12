.PHONY: build run docker docker-compose migrate test clean

# 构建二进制
build:
	go build -o bin/server ./cmd/server

# 本地运行（需先启动 MySQL + Redis）
run:
	go run ./cmd/server

# 启动 Docker 环境（MySQL + Redis + MinIO）
docker-compose:
	cd .. && docker-compose up -d

# 停止 Docker 环境
stop:
	cd .. && docker-compose down

# 查看 Docker 日志
logs:
	cd .. && docker-compose logs -f

# 构建 Docker 镜像
docker:
	docker build -t stridemoor-api:latest .

# 数据库迁移（使用 GORM AutoMigrate）
migrate:
	go run ./cmd/server -migrate

# 运行测试
test:
	go test -v ./...

# 清理
 clean:
	rm -rf bin/
	rm -f server

# 下载依赖
deps:
	go mod download
	go mod tidy
