# ============================================================
# StrideMoor API - Go Backend Dockerfile
# ============================================================
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app
ENV GOPROXY=https://goproxy.cn,direct
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/stridemoor-api ./cmd/server/main.go

# Runtime stage
FROM alpine:3.19

RUN apk --no-cache -X http://mirrors.aliyun.com/alpine/v3.19/main -X http://mirrors.aliyun.com/alpine/v3.19/community add ca-certificates tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

WORKDIR /app
COPY --from=builder /app/stridemoor-api .
COPY --from=builder /app/configs ./configs

# Default environment overrides (can be overridden at runtime)
ENV GIN_MODE=release
ENV DB_DSN="root:G-;fnxjV4Ck(@tcp(mysql:3306)/stridemoor?charset=utf8mb4&parseTime=True&loc=Asia%2FShanghai"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./stridemoor-api"]
