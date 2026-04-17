#!/bin/bash
# ================================================
# Script: disk_monitor.sh
# Description: Monitors disk usage
# If disk usage is greater tahn 80% then gives alert
# ================================================

THRESHOLD=80
LOG_FILE="/home/$USER/server-monitoring-automation/scripts/disk_report.log"
ALERT_FILE="/home/$USER/server-monitoring-automation/scripts/disk_alerts.log"

echo "Disk Check: $(date)" >> "$LOG_FILE"

# Check each partition
df -h | grep -vE '^Filesystem|tmpfs|cdrom' | while read line; do
    USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    PARTITION=$(echo "$line" | awk '{print $6}')
    
    echo "  $PARTITION: ${USAGE}% used" >> "$LOG_FILE"
    
    # If alert threshold is crossed
    if [ "$USAGE" -ge "$THRESHOLD" ]; then
        ALERT_MSG="[ALERT] $(date) - $PARTITION is ${USAGE}% full! Action needed!"
        echo "$ALERT_MSG" >> "$ALERT_FILE"
        echo "$ALERT_MSG"  # Show on console
    fi
done

# Print summary
echo ""
echo "=== Disk Usage Summary ==="
df -h | grep -vE '^Filesystem|tmpfs|cdrom'
echo "=========================="
echo "Full report: $LOG_FILE"
