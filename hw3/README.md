# Testing replication of PostgreSQL from a Docker container to the Google Cloud SQL using pglogical.

## PostgreSQL in Docker

### Deploy PostgreSQL in Docker


```bash
docker system df
# 176.241.137.159

export POSTGRES_PASSWORD="MS6m_0Eb9pK"
docker compose up -d
docker ps
```
### Check parameters for replication. [link](https://cloud.google.com/database-migration/docs/postgres/configure-source-database?_gl=1*1wdtsoa*_ga*ODQxODUzNzk0LjE3MjUzNTQ0ODQ.*_ga_WH2QY8WWF5*MTc0NDEzMzU5Ni4zNjYuMS4xNzQ0MTM0MDQ1LjYwLjAuMA..#on-premise-self-managed-postgresql)

```sql
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "
SELECT name, setting, unit, source, boot_val, reset_val
FROM pg_settings
WHERE name IN (
  'shared_preload_libraries',
  'wal_level',
  'wal_sender_timeout',
  'max_replication_slots',
  'max_wal_senders',
  'max_worker_processes'
);"
```

Results like this

| name | setting | unit | source | boot_val | reset_val |
| ---- | ---- | ---- | ---- | ---- | ---- |
| max_replication_slots | 10 | | command line | 10 | 10 |
| max_wal_senders | 10 | | command line | 10 | 10 |
| max_worker_processes | 8 | | command line | 8 | 8 |
| shared_preload_libraries | pg_stat_statements | | command line | | pg_stat_statements |
| wal_level | replica | | command line | replica | replica |
| wal_sender_timeout | 60000 | ms | command line | 60000 | 60000 |

### Load database [Periodic table data](https://github.com/neondatabase-labs/postgres-sample-dbs/tree/main?tab=readme-ov-file#periodic-table-data)

```bash
wget https://raw.githubusercontent.com/neondatabase/postgres-sample-dbs/main/periodic_table.sql

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE periodic_table;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -f periodic_table.sql

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -c 'select pt."AtomicNumber", pt."Element", pt."Symbol"  from periodic_table pt where pt."AtomicMass" < 10;'

rm periodic_table.sql
```

### Create user for migration

```bash
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE ROLE migration_user WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migration_user WITH LOGIN;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migration_user WITH REPLICATION;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE migration_user WITH OWNER migration_user;"
```

###  Setting privileges on databases

```bash
DBS=("migration_user" "postgres" "periodic_table")
for DB in "${DBS[@]}"; do
  psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/$DB" -f set_privileges.sql
done
```











## PostgreSQL in Google Cloud SQL

### Get started

Migration job name: Docker to Cloud SQL
Migration job ID: docker-to-cloud-sql
Source database engine: PostgreSQL
Destination database engine: Cloud SQL for PostgreSQL
Destination region: europe-north1 (Finland)
Migration job type : Continuous

### Define your source

Connection profile name: Docker PostgreSQL Connection
Connection profile ID: docker-postgresql-connection
Region: europe-north1 (Finland)
Hostname or IP address: 176.241.137.159
Port: 5432
Username: postgres
Encryption type (SSL/TLS): None





Delete project

```bash
stop_cloud_docker.sh
```

### Links

- [Store Docker container images in Artifact Registry](Deploy the Docker container to Google Cloud Run.

### Presets

Install docker and gcloud


```bash
# set
export GCP_PROJECT=<project_id>
export GCP_REGION=<region_name>
```
Start project

```bash
start_cloud_docker.sh
```

Delete project

```bash
stop_cloud_docker.sh
```

### Links

- [](Deploy the Docker container to Google Cloud Run.

### Presets

Install docker and gcloud


```bash
# set
export GCP_PROJECT=<project_id>
export GCP_REGION=<region_name>
```
Start project

```bash
start_cloud_docker.sh
```

Delete project

```bash
stop_cloud_docker.sh
```

### Links

- [Migrate a database to Cloud SQL for PostgreSQL by using Database Migration Service](https://cloud.google.com/database-migration/docs/postgres/quickstart)
- [Database Migration Service Connection Profile Postgres](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/database_migration_service_connection_profile#example-usage---database-migration-service-connection-profile-postgres)
- [Goole Cloud SQL](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database)