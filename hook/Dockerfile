FROM oven/bun:alpine AS bun-source

FROM almir/webhook:latest

# 1. 复制 Bun 运行时二进制
COPY --from=bun-source /usr/local/bin/bun /usr/local/bin/bun

# 2. 安装核心工具，配置时区后清理 tzdata 数据库，避免携带冗余文件
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates \
    tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

WORKDIR /app
