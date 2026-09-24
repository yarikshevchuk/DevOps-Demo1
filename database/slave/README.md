# PostgreSQL Standby

PostgreSQL Standby configuration for the Demo 1 environment.

## Architecture

```text
Application VMs
       |
       v
PostgreSQL Master
192.168.50.20:5432
       |
       | WAL Streaming Replication
       v
PostgreSQL Standby
192.168.50.21:5432
```

The Master is the primary PostgreSQL server used by the application.

The Standby maintains a physical copy of the Master by continuously receiving and replaying WAL records.

## Network

- Hostname: `db-slave`
- IP: `192.168.50.21/24`
- Gateway: `192.168.50.2`
- Network: `VMnet2`
- Subnet: `192.168.50.0/24`

The VM uses a static IP address.

## PostgreSQL

- PostgreSQL version: `16`
- Port: `5432`
- Master: `192.168.50.20`
- Standby: `192.168.50.21`
- Replication role: `replicator`
- Replication slot: `slave1_slot`

## Master Requirements

Before configuring the Standby, the Master must be configured for Streaming Replication.

The following parameters are configured on the Master:

```text
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
```

The Master must contain a PostgreSQL role with the `REPLICATION` privilege:

```sql
CREATE ROLE replicator
WITH REPLICATION LOGIN PASSWORD 'your_password';
```

The replication password must not be stored in Git.

The following rule must be present in the Master's `pg_hba.conf`:

```text
host    replication    replicator    192.168.50.21/32    scram-sha-256
```

This allows only the Standby VM at `192.168.50.21` to connect using the `replicator` role.

## Replication Slot

The physical replication slot is created on the Master:

```sql
SELECT pg_create_physical_replication_slot('slave1_slot');
```

It can be checked with:

```sql
SELECT slot_name, slot_type, active
FROM pg_replication_slots;
```

When the Standby is connected, `slave1_slot` should be active.

The replication slot prevents the Master from removing WAL that is still required by the Standby.

## Automated Standby Setup

The `setup-slave.sh` script prepares the Standby and creates its initial copy from the Master.

Make the script executable:

```bash
chmod +x setup-slave.sh
```

Run it with the replication password:

```bash
sudo REPLICATION_PASSWORD='your_password' ./setup-slave.sh
```

The replication password is passed through an environment variable and must not be committed to Git.

The script:

1. Installs PostgreSQL 16.
2. Checks that the Master is reachable on port `5432`.
3. Stops the local PostgreSQL service.
4. Preserves the initial local data directory as `main.old`.
5. Creates a new empty PostgreSQL data directory.
6. Uses `pg_basebackup` to create a physical copy of the Master.
7. Configures the server as a Standby.
8. Configures the `slave1_slot` replication slot.
9. Starts PostgreSQL.
10. Checks the recovery and WAL receiver status.

## pg_basebackup

The initial copy of the Master is created using:

```bash
pg_basebackup \
  -h 192.168.50.20 \
  -p 5432 \
  -U replicator \
  -D /var/lib/postgresql/16/main \
  -Fp \
  -Xs \
  -P \
  -R
```

Important options:

```text
-h    Master address
-p    PostgreSQL port
-U    replication role
-D    destination data directory
-Fp   plain backup format
-Xs   stream WAL during the backup
-P    display progress
-R    create Standby configuration
```

The `-R` option creates the configuration required for the server to start as a Standby, including `standby.signal` and the Primary connection information.

## Verification on Standby

Check the PostgreSQL cluster:

```bash
pg_lsclusters
```

Expected state:

```text
16  main  5432  online
```

Check whether PostgreSQL is running as a Standby:

```bash
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```

Expected result:

```text
t
```

Check the WAL receiver:

```sql
SELECT status, sender_host, sender_port, slot_name
FROM pg_stat_wal_receiver;
```

The receiver should be connected to `192.168.50.20` and use `slave1_slot`.

## Verification on Master

On the Master, check connected Standby servers:

```sql
SELECT client_addr, usename, state, sync_state
FROM pg_stat_replication;
```

Expected values include:

```text
client_addr    192.168.50.21
usename        replicator
state          streaming
sync_state     async
```

Check the replication slot:

```sql
SELECT slot_name, slot_type, active
FROM pg_replication_slots;
```

Expected state:

```text
slave1_slot | physical | true
```

## Replication Test

Create test data on the Master:

```sql
CREATE TABLE replication_test (
    id SERIAL PRIMARY KEY,
    message TEXT
);

INSERT INTO replication_test (message)
VALUES ('Replication works');
```

Then connect to `appdb` on the Standby:

```bash
sudo -u postgres psql -d appdb
```

Check the replicated data:

```sql
SELECT * FROM replication_test;
```

Expected result:

```text
1 | Replication works
```

The table must be created only on the Master. It appears on the Standby automatically through Streaming Replication.

## Important

Streaming Replication is not a backup.

Changes made on the Master, including accidental changes or deletions, can also be replicated to the Standby.

Separate PostgreSQL backups are configured as another part of the database infrastructure.
