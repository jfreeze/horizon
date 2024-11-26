```conf
#
# Horizon.Ops - Sample Config for a Postgres Backup Server
#
# Install postgres for convenience if we need to restore from backup
# or stand up the backup as the replacement server
#

pkg:postgresql17-server
pkg:postgresql17-contrib

# Initialize ZFS for the PostgreSQL Backup server
postgres.zfs-init

```
