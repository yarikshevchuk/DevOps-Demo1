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

The PostgreSQL Master accepts connections from the internal `192.168.50.0/24` network.

The application VMs connect to the Master using:

```text
Host: 192.168.50.20
Port: 5432
Database: appdb
Username: appuser
Password: provided separately
```

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

## Client Access

The following rule is added to `pg_hba.conf`:

```text
host    appdb    appuser    192.168.50.0/24    scram-sha-256
```

This allows `appuser` to connect to `appdb` from the internal VMnet2 network using password authentication.

## Firewall

Port `5432` is available only from the internal network:

```bash
sudo ufw allow from 192.168.50.0/24 to any port 5432 proto tcp
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

Run it with the application database password:

```bash
sudo APP_DB_PASSWORD='your_password' ./setup-master.sh
```

The database password is passed through an environment variable and must not be committed to Git.

The script:

1. Installs PostgreSQL.
2. Creates backups of the original PostgreSQL configuration files.
3. Configures PostgreSQL to accept network connections.
4. Configures parameters required for Streaming Replication.
5. Adds the application access rule to `pg_hba.conf`.
6. Creates the `appuser` PostgreSQL role.
7. Creates the `appdb` database.
8. Configures the firewall.
9. Restarts PostgreSQL.
10. Performs basic verification.

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
sudo ufw status
```

Port `5432` should be allowed from `192.168.50.0/24`.

Test the application database connection:

```bash
psql -h 192.168.50.20 -p 5432 -U appuser -d appdb
```

After connecting, the database and user can be verified with:

```sql
SELECT current_database(), current_user;
```

Expected result:

```text
current_database | current_user
-----------------+-------------
appdb            | appuser
```

