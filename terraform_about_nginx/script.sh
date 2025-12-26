#!/bin/bash
set -e

# 變數設定（從 Terraform 傳入）
S3_BUCKET="${s3_bucket_name}"
AWS_REGION="${aws_region}"

# 更新系統
dnf update -y

# 安裝必要套件
dnf install -y nginx logrotate aws-cli

# ============================================
# 設定 Nginx JSON 日誌格式
# ============================================
cat > /etc/nginx/conf.d/log-format.conf << 'EOF'
log_format json_combined escape=json '{'
    '"timestamp":"$time_iso8601",'
    '"client_ip":"$remote_addr",'
    '"method":"$request_method",'
    '"uri":"$request_uri",'
    '"protocol":"$server_protocol",'
    '"status":$status,'
    '"body_bytes_sent":$body_bytes_sent,'
    '"http_referer":"$http_referer",'
    '"http_user_agent":"$http_user_agent",'
    '"request_time":$request_time,'
    '"hostname":"$hostname"'
'}';

access_log /var/log/nginx/access.log json_combined;
error_log /var/log/nginx/error.log warn;
EOF

# ============================================
# 設定 Logrotate（每小時輪替）
# ============================================
cat > /etc/logrotate.d/nginx << 'LOGROTATE_EOF'
/var/log/nginx/*.log {
    hourly
    rotate 24
    missingok
    notifempty
    compress
    dateext
    dateformat -%Y%m%d-%H
    sharedscripts
    postrotate
        # 重新載入 Nginx
        systemctl reload nginx > /dev/null 2>&1 || true
        # 上傳舊日誌到 S3
        /usr/local/bin/upload-to-s3.sh > /var/log/s3-upload.log 2>&1 || true
    endscript
}
LOGROTATE_EOF

# ============================================
# 建立 S3 上傳腳本
# ============================================
cat > /usr/local/bin/upload-to-s3.sh << 'UPLOAD_EOF'
#!/bin/bash
set -e

S3_BUCKET="__S3_BUCKET__"
AWS_REGION="__AWS_REGION__"
HOSTNAME=$(hostname)
LOG_DIR="/var/log/nginx"

echo "[$(date)] Starting log upload..."

# 找出已壓縮的日誌檔案（排除最近 5 分鐘的，避免還在壓縮中）
COMPRESSED_LOGS=$(find $LOG_DIR -name "*.log-*.gz" -type f -mmin +5 2>/dev/null || true)

if [ -z "$COMPRESSED_LOGS" ]; then
    echo "[$(date)] No compressed logs to upload"
    exit 0
fi

# 上傳每個日誌檔案
for LOG_FILE in $COMPRESSED_LOGS; do
    FILENAME=$(basename "$LOG_FILE")
    
    # 從檔名提取時間: access.log-20251224-10.gz
    if [[ $FILENAME =~ \.log-([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})\.gz ]]; then
        YEAR="$${BASH_REMATCH[1]}"
        MONTH="$${BASH_REMATCH[2]}"
        DAY="$${BASH_REMATCH[3]}"
        HOUR="$${BASH_REMATCH[4]}"
        
        # S3 路徑（按 partition 結構）
        S3_PATH="s3://$S3_BUCKET/nginx/$YEAR/$MONTH/$DAY/$HOUR/$HOSTNAME-$FILENAME"
        
        echo "[$(date)] Uploading: $LOG_FILE -> $S3_PATH"
        
        # 上傳到 S3
        if aws s3 cp "$LOG_FILE" "$S3_PATH" --region "$AWS_REGION" 2>&1; then
            # 驗證上傳（檢查檔案是否存在）
            if aws s3 ls "$S3_PATH" --region "$AWS_REGION" > /dev/null 2>&1; then
                echo "[$(date)] ✅ Upload successful, deleting local file: $FILENAME"
                rm -f "$LOG_FILE"
            else
                echo "[$(date)] ❌ Verification failed, keeping local file: $FILENAME"
            fi
        else
            echo "[$(date)] ❌ Upload failed: $FILENAME"
        fi
    else
        echo "[$(date)] ⚠️ Skipping unexpected format: $FILENAME"
    fi
done

echo "[$(date)] Log upload completed"
UPLOAD_EOF

# 替換變數
sed -i "s|__S3_BUCKET__|$S3_BUCKET|g" /usr/local/bin/upload-to-s3.sh
sed -i "s|__AWS_REGION__|$AWS_REGION|g" /usr/local/bin/upload-to-s3.sh

# 設定執行權限
chmod +x /usr/local/bin/upload-to-s3.sh

# ============================================
# 設定 systemd timer（每小時執行 logrotate）
# ============================================
cat > /etc/systemd/system/logrotate-hourly.service << 'SERVICE_EOF'
[Unit]
Description=Hourly Nginx Log Rotation
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/logrotate /etc/logrotate.d/nginx
StandardOutput=journal
StandardError=journal
SERVICE_EOF

cat > /etc/systemd/system/logrotate-hourly.timer << 'TIMER_EOF'
[Unit]
Description=Hourly Nginx Log Rotation Timer

[Timer]
OnCalendar=hourly
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target
TIMER_EOF

# 啟動 timer
systemctl daemon-reload
systemctl enable logrotate-hourly.timer
systemctl start logrotate-hourly.timer

# ============================================
# 啟動 Nginx
# ============================================
systemctl start nginx
systemctl enable nginx

# ============================================
# 產生測試日誌
# ============================================
for i in {1..10}; do
    curl -s http://localhost/ > /dev/null 2>&1 || true
done

echo "Setup completed at $(date)" > /var/log/user-data-completed.log