#!/bin/bash
# ========================================================
# Script: log_cleanup.sh
# Description: Clears the old log files
# Author: Khalil Ahmad
# ========================================================


LOG_DIR="/var/log"
ARCHIVE_DIR="/home/$USER/log_archives"
DAYS_OLD=7
LOG_FILE="/home/$USER/server-monitoring-automation/scripts/cleanup_report.log"

# Create Archive dir if not exists
mkdir -p "$ARCHIVE_DIR"

# Log entry with timestamp
echo "====================================" >> "$LOG_FILE"
echo "Log cleanup started: $(date)" >> "$LOG_FILE"
echo "====================================" >> "$LOG_FILE"

# Find .log files 7 days old and compress them
echo "Compressing logs older than $DAYS_OLD days..." >> "$LOG_FILE"
find "$LOG_DIR" -name "*.log" -mtime +$DAYS_OLD -exec gzip {} \; 2>/dev/null
echo "Compression done." >> "$LOG_FILE"

# Move compressed file to archive
find "$LOG_DIR" -name "*.log.gz" -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null
echo "Archived to: $ARCHIVE_DIR" >> "$LOG_FILE"

# Delete archives older than 30 days
find "$ARCHIVE_DIR" -mtime +30 -delete 2>/dev/null
echo "Old archives deleted." >> "$LOG_FILE"

echo "Cleanup Completed: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "Log cleanup complete. Check $LOG_FILE for details."

