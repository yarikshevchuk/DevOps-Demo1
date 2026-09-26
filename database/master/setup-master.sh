#!/bin/bash

set -e

# -----------------------------
# PostgreSQL Master configuration
# -----------------------------

DB_NAME="appdb"
DB_USER="appuser"
DB_PORT="5432"
POSTGRES_VERSION="16"

REPLICATION_USER="replicator"
SLAVE_IP="192.168.50.21/32"

NETWORK="192.168.50.0/24"

PG_CONF="/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf"

# Password must be passed through environment variable
if [ -z "$APP_DB_PASSWORD" ] || [ -z "$REPLICATION_PASSWORD" ]; then
    echo "ERROR: APP_DB_PASSWORD or REPLICATION_PASSWORD is not set."
    echo "Run:"
    echo "sudo APP_DB_PASSWORD='app_password' REPLICATION_PASSWORD='replication_password' ./setup-master.sh"
    exit 1
fi

echo "=== Installing PostgreSQL ==="

apt update
apt install -y postgresql postgresql-contrib

echo "=== Creating configuration backups ==="

cp "$PG_CONF" "${PG_CONF}.bak"
cp "$PG_HBA" "${PG_HBA}.bak"

echo "=== Configuring PostgreSQL Master ==="

sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"

sed -i "s/^#wal_level.*/wal_level = replica/" "$PG_CONF"
sed -i "s/^#max_wal_senders.*/max_wal_senders = 5/" "$PG_CONF"
sed -i "s/^#max_replication_slots.*/max_replication_slots = 5/" "$PG_CONF"

echo "=== Configuring client access ==="

HBA_RULE="host    ${DB_NAME}    ${DB_USER}    ${NETWORK}    scram-sha-256"

if ! grep -Fq "$HBA_RULE" "$PG_HBA"; then
    echo "$HBA_RULE" >> "$PG_HBA"
fi

REPLICATION_HBA_RULE="host    replication    ${REPLICATION_USER}    ${SLAVE_IP}    scram-sha-256"

if ! grep -Fq "$REPLICATION_HBA_RULE" "$PG_HBA"; then
    echo "$REPLICATION_HBA_RULE" >> "$PG_HBA"
fi

echo "=== Creating application role ==="

sudo -u postgres psql \
    --set=db_password="$APP_DB_PASSWORD" <<'SQL'
SELECT format(
    'CREATE ROLE appuser LOGIN PASSWORD %L',
    :'db_password'
)
WHERE NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = 'appuser'
)\gexec
SQL

echo "=== Creating replication role ==="

sudo -u postgres psql \
    --set=replication_password="$REPLICATION_PASSWORD" <<'SQL'
SELECT format(
    'CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD %L',
    :'replication_password'
)
WHERE NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = 'replicator'
)\gexec
SQL

echo "=== Creating application database ==="

if ! sudo -u postgres psql -tAc \
    "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1;
then
    sudo -u postgres createdb \
        --owner="$DB_USER" \
        "$DB_NAME"
fi

echo "=== Configuring firewall ==="

ufw allow 22/tcp
ufw allow from "$NETWORK" to any port "$DB_PORT" proto tcp

echo "=== Restarting PostgreSQL ==="

systemctl restart postgresql

echo "=== Verification ==="

pg_lsclusters
ss -lntp | grep ":${DB_PORT}"

echo
echo "PostgreSQL Master setup completed."
echo "Database: ${DB_NAME}"
echo "User: ${DB_USER}"
echo "Port: ${DB_PORT}"

echo "=== Creating replication slot ==="

if ! sudo -u postgres psql -tAc \
    "SELECT 1 FROM pg_replication_slots WHERE slot_name='slave1_slot'" | grep -q 1;
then
    sudo -u postgres psql -c \
        "SELECT pg_create_physical_replication_slot('slave1_slot');"
fi