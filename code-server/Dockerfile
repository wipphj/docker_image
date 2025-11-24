# 第一阶段：搬运工 (Builder) - 使用官方最新版 Go
FROM golang:latest AS builder

# 第二阶段：最终镜像 - 基于 LinuxServer
FROM linuxserver/code-server:latest

# 1. 从 builder 阶段复制完整的 Go 安装目录
COPY --from=builder /usr/local/go /usr/local/go

# 2. 配置环境变量
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/config/go
ENV PATH=$PATH:$GOPATH/bin

# 3. 将环境变量写入 profile，确保终端登录和 s6 初始化都能生效
RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh && \
    echo 'export GOPATH=/config/go' >> /etc/profile.d/go.sh && \
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile.d/go.sh && \
    chmod +x /etc/profile.d/go.sh

# 4. 验证安装并清理临时文件 (Dockerfile 到此结束即可)
RUN go version && \
    rm -rf /tmp/*
