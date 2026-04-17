#!/bin/bash
# ================================================
# Script: backup.sh
# Description: Daily backup important files
# ================================================

BACKUP_DIR="/home/$USER/backups"
SOURCE_DIRS=("/home/$USER/scripts" "/etc/crontab")
DATE=$(date +%Y-%m-%d_%H-%M)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"
LOG_FILE="/home/$USER/scripts/backup_report.log"
RETENTION_DAYS=7

# Make backup dir
mkdir -p "$BACKUP_DIR"

echo "========================================" >> "$LOG_FILE"
echo "Backup Started: $(date)" >> "$LOG_FILE"

# Tar archive 
tar -czf "$BACKUP_FILE" "${SOURCE_DIRS[@]}" 2>/dev/null

# Check if backup is success or not
if [ $? -eq 0 ]; then
    SIZE=$(du -sh "$BACKUP_FILE" | awk '{print $1}')
    echo "✓ Backup created: $BACKUP_FILE ($SIZE)" >> "$LOG_FILE"
    echo "✓ Backup successful: $BACKUP_FILE ($SIZE)"
else
    echo "✗ BACKUP FAILED at $(date)" >> "$LOG_FILE"
    echo "✗ Backup failed! Check $LOG_FILE"
fi

# Delete backups older than 7 days
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "Old backups cleaned (older than $RETENTION_DAYS days)" >> "$LOG_FILE"
echo "Backup Completed: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
