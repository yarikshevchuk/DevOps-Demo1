# PostgreSQL Master

PostgreSQL Master configuration for the Demo 1 environment.

## Network

- Hostname: `db-master`
- IP: `192.168.50.20/24`
- Gateway: `192.168.50.2`
- Network: `VMnet2`
- Subnet: `192.168.50.0/24`

The VM uses a static IP address. VMware VMnet2 is configured as a NAT network with DHCP disabled.

## PostgreSQL

- PostgreSQL version: `16`
- Port: `5432`
- Database: `appdb`
- Application role: `appuser`
- Replication role: `replicator`
- Replication slot: `slave1_slot`

The PostgreSQL Master accepts application connections from the internal
`192.168.50.0/24` network and replication connections from the Slave VM.

The application VMs connect to the Master using:

```text
Host: 192.168.50.20
Port: 5432
Database: appdb
Username: appuser
Password: provided separately
```

The Slave connects to the Master using the separate `replicator` role.

Passwords and other secrets must not be stored in Git.

## Master Configuration

The following PostgreSQL parameters are configured in `postgresql.conf`:

```text
listen_addresses = '*'
port = 5432
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
```

`listen_addresses = '*'` allows PostgreSQL to listen for connections on the VM network interfaces.

The replication parameters prepare the Master for PostgreSQL Streaming Replication with the Slave VM.

## Client and Replication Access

The following application access rule is added to `pg_hba.conf`:

```text
host    appdb    appuser    192.168.50.0/24    scram-sha-256
```

This allows `appuser` to connect to `appdb` from the internal VMnet2 network.

The following replication rule is also added:

```text
host    replication    replicator    192.168.50.21/32    scram-sha-256
```

This allows only the Slave VM (`192.168.50.21`) to connect to the Master
using the `replicator` role for Streaming Replication.

## Replication Role

The Master contains a separate PostgreSQL role for replication:

```text
replicator
```

The role has `LOGIN` and `REPLICATION` privileges and is used only by the
Slave VM to establish the replication connection.

The replication password is provided through the `REPLICATION_PASSWORD`
environment variable and is not stored in the repository.

## Replication Slot

The setup script creates the physical replication slot:

```text
slave1_slot
```

The Slave uses this slot when receiving WAL records from the Master.

## Firewall

Port `5432` is available from the internal network:

```bash
sudo wufw allow from 192.168.50.0/24 to any port 5432 proto tcp
```

SSH access is allowed on port `22`:

```bash
sudo ufw allow 22/tcp
```

## Automated Setup

The `setup-master.sh` script installs and configures PostgreSQL Master.

Make the script executable:

```bash
chmod +x setup-master.sh
```

Run it with separate passwords for the application and replication roles:

```bash
sudo APP_DB_PASSWORD='app_password' \
REPLICATION_PASSWORD='replication_password' \
./setup-master.sh
```

Both passwords are passed through environment variables and must not be
committed to Git.

The script:

1. Installs PostgreSQL.
2. Creates backups of the original PostgreSQL configuration files.
3. Configures PostgreSQL to accept network connections.
4. Configures parameters required for Streaming Replication.
5. Adds the application access rule to `pg_hba.conf`.
6. Adds the Slave replication access rule to `pg_hba.conf`.
7. Creates the `appuser` PostgreSQL role.
8. Creates the `replicator` PostgreSQL role.
9. Creates the `appdb` database.
10. Creates the `slave1_slot` physical replication slot.
11. Configures the firewall.
12. Restarts PostgreSQL.
13. Performs basic verification.

## Verification

Check that the PostgreSQL cluster is online:

```bash
pg_lsclusters
```

Expected state:

```text
16  main  5432  online
```

Check that PostgreSQL is listening on port `5432`:

```bash
sudo ss -lntp | grep 5432
```

Expected result should include:

```text
0.0.0.0:5432
[::]:5432
```

Check the firewall:

```bash
sudo ufw show added
```
or
```bash
sudo ufw status
```

Port `5432` should be allowed from `192.168.50.0/24`.

Test the application database connection:

```bash
psql -h 192.168.50.20 -p 5432 -U appuser -d appdb
```

After connecting:

```sql
SELECT current_database(), current_user;
```

Expected result:

```text
current_database | current_user
-----------------+-------------
appdb            | appuser
```

Verify the replication role:

```bash
sudo -u postgres psql -c "\du replicator"
```

Verify the replication slot:

```bash
sudo -u postgres psql -c \
"SELECT slot_name, slot_type, active FROM pg_replication_slots;"
```

After the Slave is configured and connected, `slave1_slot` should be active.
