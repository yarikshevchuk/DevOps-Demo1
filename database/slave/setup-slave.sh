#!/bin/bash

set -e

# ---------------------------------
# PostgreSQL Standby configuration
# ---------------------------------

POSTGRES_VERSION="16"

MASTER_IP="192.168.50.20"
MASTER_PORT="5432"

REPLICATION_USER="replicator"
REPLICATION_SLOT="slave1_slot"

PG_DATA="/var/lib/postgresql/${POSTGRES_VERSION}/main"
OLD_PG_DATA="/var/lib/postgresql/${POSTGRES_VERSION}/main.old"

# Replication password must not be stored in Git
if [ -z "$REPLICATION_PASSWORD" ]; then
    echo "ERROR: REPLICATION_PASSWORD is not set."
    echo "Run:"
    echo "sudo REPLICATION_PASSWORD='your_password' ./setup-slave.sh"
    exit 1
fi

echo "=== Installing PostgreSQL ==="

apt update
apt install -y postgresql postgresql-contrib

echo "=== Checking connection to Master ==="

pg_isready -h "$MASTER_IP" -p "$MASTER_PORT"

echo "=== Stopping PostgreSQL ==="

systemctl stop postgresql

echo "=== Preparing PostgreSQL data directory ==="

# Keep the original cluster as a temporary backup
if [ -d "$PG_DATA" ] && [ ! -d "$OLD_PG_DATA" ]; then
    mv "$PG_DATA" "$OLD_PG_DATA"
else
    rm -rf "$PG_DATA"
fi

mkdir -p "$PG_DATA"

chown postgres:postgres "$PG_DATA"
chmod 700 "$PG_DATA"

echo "=== Creating base backup from Master ==="

sudo -u postgres env PGPASSWORD="$REPLICATION_PASSWORD" \
    pg_basebackup \
    -h "$MASTER_IP" \
    -p "$MASTER_PORT" \
    -U "$REPLICATION_USER" \
    -D "$PG_DATA" \
    -Fp \
    -Xs \
    -P \
    -R

echo "=== Configuring replication slot ==="

echo "primary_slot_name = '${REPLICATION_SLOT}'" \
    >> "${PG_DATA}/postgresql.auto.conf"

chown postgres:postgres "${PG_DATA}/postgresql.auto.conf"

echo "=== Starting PostgreSQL Standby ==="

systemctl start postgresql

echo "=== Verification ==="

pg_lsclusters

echo
echo "Recovery status:"

sudo -u postgres psql -tAc \
    "SELECT pg_is_in_recovery();"

echo
echo "WAL receiver status:"

sudo -u postgres psql -x -c \
    "SELECT status, sender_host, sender_port, slot_name
     FROM pg_stat_wal_receiver;"

echo
echo "PostgreSQL Standby setup completed."
echo "Master: ${MASTER_IP}:${MASTER_PORT}"
echo "Standby IP: 192.168.50.21"
echo "Replication user: ${REPLICATION_USER}"
echo "Replication slot: ${REPLICATION_SLOT}"