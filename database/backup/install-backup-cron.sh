#!/bin/bash

set -e

BACKUP_SCRIPT="/usr/local/bin/postgresql-backup.sh"
CRON_SCHEDULE="0 2 * * *"
LOG_FILE="/var/log/postgresql-backup.log"

echo "=== Installing PostgreSQL backup Cron job ==="

# Check that the backup script exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "ERROR: Backup script not found: $BACKUP_SCRIPT"
    exit 1
fi

# Make sure the backup script is executable
chmod +x "$BACKUP_SCRIPT"

CRON_JOB="$CRON_SCHEDULE $BACKUP_SCRIPT >> $LOG_FILE 2>&1"

# Add the job only if it does not already exist
(
    crontab -l 2>/dev/null | grep -Fv "$BACKUP_SCRIPT" || true
    echo "$CRON_JOB"
) | crontab -

echo "Cron job installed successfully."
echo
echo "Schedule:"
echo "$CRON_JOB"
echo
echo "Current root crontab:"
crontab -l