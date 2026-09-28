#!/bin/bash

set -e

BACKUP_DIR="/var/backups/postgresql"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

echo "PostgreSQL backup started"

# Create backup directory if it does not exist
mkdir -p "$BACKUP_DIR"
chown postgres:postgres "$BACKUP_DIR"

# Create logical backup of the PostgreSQL cluster
sudo -u postgres pg_dumpall > "$BACKUP_FILE"

# Set correct ownership
chown postgres:postgres "$BACKUP_FILE"

echo "Backup created:"
echo "$BACKUP_FILE"

echo "Backup size:"
du -h "$BACKUP_FILE"

echo "PostgreSQL backup completed"