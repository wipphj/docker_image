#!/bin/bash

# ==============================================================================
# 2. 基础变量与日志函数
# ==============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

FIRMWARE_FILE="/usr/share/foo2zjs/firmware/sihp1020.dl"
LOCK_FILE="/tmp/hp1020_fw_loaded"
PRINTER_NAME="HP_LaserJet_1020_11"

# 心跳设置：3600秒 = 1小时
HEARTBEAT_INTERVAL=3600
LAST_HEARTBEAT=$(date +%s)

# 状态标记：用于控制 Ghostscript 配置只执行一次
GS_CONFIGURED="false"

# ==============================================================================
# 3. 启动准备
# ==============================================================================

# [关键修复] 启动前强制清理锁文件
# 防止容器重启后，因为残留的锁文件导致脚本以为固件已加载，从而产生“隔夜失效”的问题
if [ -f "$LOCK_FILE" ]; then
    rm "$LOCK_FILE"
    log "Init: Cleaned up stale lock file from previous run."
fi

# 后台启动 CUPS 守护进程
/usr/sbin/cupsd -f &
log "Docker CUPS started."
log "Waiting for HP 1020 printer..."

# ==============================================================================
# 4. 主监控循环 (核心逻辑)
# ==============================================================================
while true; do

    # ------------------------------------------------------------------
    # A. 心跳监控逻辑 (每小时打印一次状态，证明容器活着)
    # ------------------------------------------------------------------
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_HEARTBEAT))

    if [ "$TIME_DIFF" -ge "$HEARTBEAT_INTERVAL" ]; then
        if [ -f "$LOCK_FILE" ]; then
            STATUS="Online (Firmware Loaded)"
        else
            STATUS="Waiting for Device"
        fi
        log "❤️ [Heartbeat] System running. Printer Status: $STATUS. (Next check in 1h)"
        LAST_HEARTBEAT=$CURRENT_TIME
    fi

    # ------------------------------------------------------------------
    # B. 打印机配置优化逻辑 (Ghostscript 渲染器)
    # ------------------------------------------------------------------
    # 先检查打印机队列是否存在 (CUPS 是否已识别)
    if lpstat -p "$PRINTER_NAME" > /dev/null 2>&1; then
        
        # 只有当状态标记为 false 时，才执行配置 (防止日志刷屏)
        # 只有队列存在，且固件已加载（说明物理设备在线）时，才应用配置
        if [ "$GS_CONFIGURED" = "false" ] && [ -f "$LOCK_FILE" ]; then
            log "Printer online and $PRINTER_NAME detected. Applying performance settings..."
            
            # 执行配置命令
            if lpadmin -p "$PRINTER_NAME" -o pdftops-renderer-default=gs 2>/dev/null; then
                log "SUCCESS: Configuration applied (pdftops-renderer-default=gs)."
                GS_CONFIGURED="true" # 标记为已完成
            else
                log "WARNING: Failed to apply settings. Will retry next loop."
            fi
        fi
    else
        # 进阶优化：如果打印机突然消失了（被误删），重置标记
        # 这样下次打印机出现时，脚本会再次尝试配置
        if [ "$GS_CONFIGURED" = "true" ]; then
            log "Printer $PRINTER_NAME disappeared. Resetting config flag."
            GS_CONFIGURED="false"
        fi
    fi

    # ------------------------------------------------------------------
    # C. 固件加载逻辑 (热插拔支持 + 错误检查)
    # ------------------------------------------------------------------
    # 检测 HP 1020 物理 USB 设备 (03f0:2b17)
    if lsusb | grep -q "03f0:2b17"; then
        
        # 只有在没有锁文件时才尝试加载
        if [ ! -f "$LOCK_FILE" ]; then
            log "HP 1020 physical device detected. Preparing to load firmware..."
            
            # 等待 2 秒，确保 /dev/usb/lp* 设备节点已由内核生成
            sleep 2
            
            success=false
            
            # 遍历所有可能的 lp 设备，防止设备名从 lp0 变成 lp1
            for dev in /dev/usb/lp*; do
                if [ -e "$dev" ]; then
                    # === 关键修复：检查 cat 命令返回值 ===
                    # 只有写入成功，才认为固件加载完毕
                    if cat "$FIRMWARE_FILE" > "$dev" 2>/dev/null; then
                        log "SUCCESS: Firmware sent to $dev"
                        success=true
                        break # 成功一个就退出循环
                    else
                        log "WARNING: Failed to write to $dev (Device busy or stale handle?)"
                    fi
                fi
            done
            
            # 只有真的成功写入了，才创建锁文件
            if [ "$success" = true ]; then
                touch "$LOCK_FILE"
                log "Firmware loading sequence COMPLETED. Lock file created."
            else
                log "ERROR: Could not load firmware to any device. Will retry next loop..."
                # 注意：不创建锁文件，下次循环继续尝试
            fi
        fi
        
    else
        # USB 断开逻辑：如果 lsusb 找不到设备，但锁文件还在，说明设备刚断开
        if [ -f "$LOCK_FILE" ]; then
            log "HP 1020 disconnected/powered off. Removing lock file."
            rm "$LOCK_FILE"
            # 同时也重置配置标记，以防万一
            GS_CONFIGURED="false"
        fi
    fi
    
    # 循环间隔 5 秒
    sleep 5
done
