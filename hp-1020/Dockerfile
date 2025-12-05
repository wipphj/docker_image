# 使用 Debian 11 (Bullseye)
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装基础包
# Debian 11 的软件源是正常的，直接装
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cups \
    printer-driver-foo2zjs \
    ghostscript \
    usbutils \
    avahi-utils \
    poppler-utils \
    # 预防性安装字体，防止因缺字体导致的白页
    fonts-urw-base35 \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. 固件 (必须)
RUN mkdir -p /usr/share/foo2zjs/firmware/
COPY sihp1020.dl /usr/share/foo2zjs/firmware/

# 3. 注入配置
COPY cupsd.conf /etc/cups/cupsd.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 631
CMD ["/start.sh"]
