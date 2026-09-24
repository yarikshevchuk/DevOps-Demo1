# PostgreSQL Automated Backups

Automated logical backups of the PostgreSQL cluster are created on the Standby server.

## Architecture

```text
PostgreSQL Master
192.168.50.20
        |
        | Streaming Replication
        v
PostgreSQL Standby
192.168.50.21
        |
        | Cron
        v
postgresql-backup.sh
        |
        | pg_dumpall
        v
/var/backups/postgresql/
```

Backups are created on the Standby server to avoid running the dump process on the primary PostgreSQL server.

## Backup Script

The backup script is stored in:

```text
/usr/local/bin/postgresql-backup.sh
```

The repository version is:

```text
database/backup/postgresql-backup.sh
```

The script uses `pg_dumpall` to create a logical backup of the PostgreSQL cluster.

Backup files are stored in:

```text
/var/backups/postgresql/
```

Each backup has a timestamp in its filename:

```text
backup_YYYY-MM-DD_HH-MM-SS.sql
```

Example:

```text
backup_2026-09-25_02-00-01.sql
```

## Manual Backup

The backup can be created manually:

```bash
sudo /usr/local/bin/postgresql-backup.sh
```

Check created backups:

```bash
sudo ls -lh /var/backups/postgresql/
```

## Cron Schedule

Backups are scheduled using Cron.

The production schedule is:

```cron
0 2 * * * /usr/local/bin/postgresql-backup.sh >> /var/log/postgresql-backup.log 2>&1
```

This means that the backup runs every day at `02:00`.

Cron fields:

```text
0 2 * * *
| | | | |
| | | | +-- day of week
| | | +---- month
| | +------ day of month
| +-------- hour
+---------- minute
```

## Installing the Cron Job

Make the installation script executable:

```bash
chmod +x install-backup-cron.sh
```

Run it as root:

```bash
sudo ./install-backup-cron.sh
```

Check the installed schedule:

```bash
sudo crontab -l
```

Expected result:

```cron
0 2 * * * /usr/local/bin/postgresql-backup.sh >> /var/log/postgresql-backup.log 2>&1
```

## Cron Service

Check that Cron is running:

```bash
sudo systemctl status cron
```

If necessary, enable and start it:

```bash
sudo systemctl enable --now cron
```

## Logs

The output of automatic backup jobs is written to:

```text
/var/log/postgresql-backup.log
```

Check the log:

```bash
sudo cat /var/log/postgresql-backup.log
```

Cron activity can also be checked with:

```bash
sudo journalctl -u cron
```

## Testing

For testing only, the Cron schedule can temporarily be changed to:

```cron
* * * * * /usr/local/bin/postgresql-backup.sh >> /var/log/postgresql-backup.log 2>&1
```

This runs the backup every minute.

After testing, restore the production schedule:

```cron
0 2 * * * /usr/local/bin/postgresql-backup.sh >> /var/log/postgresql-backup.log 2>&1
```

Do not leave the every-minute schedule enabled because it will continuously create new backup files.

## Verification

Check backup files:

```bash
sudo ls -lh /var/backups/postgresql/
```

Check that the dump contains the application database:

```bash
sudo grep -in "appdb" /var/backups/postgresql/backup_*.sql | head
```

Check a replicated table:

```bash
sudo grep -in "replication_test" /var/backups/postgresql/backup_*.sql | head
```

## Important

Streaming Replication and backups serve different purposes.

The Standby continuously receives changes from the Master. Accidental changes or deletions can therefore also be replicated.

The `pg_dumpall` backups provide separate logical copies of the PostgreSQL cluster that can be used for recovery.
