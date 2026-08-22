FROM oven/bun:alpine AS bun-source

FROM almir/webhook:latest

# 1. 临时提权为 root 执行系统包安装
USER root

# 2. 拷贝 Bun 二进制并赋予所有用户可执行权限
COPY --from=bun-source /usr/local/bin/bun /usr/local/bin/bun
RUN chmod +x /usr/local/bin/bun

# 3. 安装依赖工具与时区配置
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates \
    libstdc++ \
    tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

# 4. 创建工作区并把权限移交给 webhook 用户
RUN mkdir -p /app && chown -R webhook:webhook /app

WORKDIR /app

# 5. 切回 almir/webhook 的默认用户
USER webhook
