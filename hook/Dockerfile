FROM oven/bun:alpine AS bun-source

FROM almir/webhook:latest

USER root

# 1. 拷贝时直接指定权限，彻底杜绝后续 RUN chmod 产生的层复制
COPY --chmod=755 --from=bun-source /usr/local/bin/bun /usr/local/bin/bun

# 2. 将安装、时区配置、清理、目录创建与赋权全部合并进单个 Layer
RUN apk add --no-cache \
        bash \
        curl \
        jq \
        ca-certificates \
        libstdc++ \
        tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata \
    && mkdir -p /app/node_modules \
    && chown -R webhook:webhook /app

WORKDIR /app

USER webhook
