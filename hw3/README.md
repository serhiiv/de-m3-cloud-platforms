# Testing replication of PostgreSQL from a Docker container to the Google Cloud SQL using pglogical.

# Source

## Start PostgreSQL in Docker with the bash script

```bash
script -c 'bash -v start_docker.sh'
```

or

## PostgreSQL in Docker step by step

#### Deploy PostgreSQL in Docker


```bash
export POSTGRES_PASSWORD="it[y.MS6m0Eb9pK"
cat Dockerfile 
cat docker-compose.yml
docker compose up -d
docker ps
```
#### Check parameters for replication. [link](https://cloud.google.com/database-migration/docs/postgres/configure-source-database?_gl=1*1wdtsoa*_ga*ODQxODUzNzk0LjE3MjUzNTQ0ODQ.*_ga_WH2QY8WWF5*MTc0NDEzMzU5Ni4zNjYuMS4xNzQ0MTM0MDQ1LjYwLjAuMA..#on-premise-self-managed-postgresql)

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

#### Load database [Periodic table](https://github.com/neondatabase-labs/postgres-sample-dbs/tree/main?tab=readme-ov-file#periodic-table-data)

```bash
wget -q https://raw.githubusercontent.com/neondatabase/postgres-sample-dbs/main/periodic_table.sql

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE periodic_table;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -f periodic_table.sql

rm periodic_table.sql
```

#### Create user for migration

```bash
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE ROLE migrant WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migrant WITH LOGIN;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migrant WITH REPLICATION;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE migrant WITH OWNER migrant;"


DBS=("migrant" "postgres" "periodic_table")
for DB in "${DBS[@]}"; do
  psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/$DB" -f set_privileges.sql
done
```

####  Check database load

```bash
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -c 'select pt."AtomicNumber", pt."Element", pt."Symbol"  from periodic_table pt where pt."AtomicMass" < 10;'
```

# Destination

## Apply with Terraform

```bash
less main.tf

terraform init
terraform apply
terraform state list
```

### Demote destination

```bash
export GCP_REGION="europe-north1"

gcloud database-migration migration-jobs \
	demote-destination pg-to-cloudsql \
	--region=${GCP_REGION}

while true; 
do gcloud database-migration migration-jobs list --region=${GCP_REGION}; sleep 5; echo;
done	
```

### Start replication

```bash
gcloud database-migration migration-jobs start pg-to-cloudsql \
	--region=${GCP_REGION}

while true; 
do gcloud database-migration migration-jobs list --region=${GCP_REGION}; sleep 5; echo;
done
```

### Stop replication

```bash
gcloud database-migration migration-jobs stop pg-to-cloudsql \
	--region=${GCP_REGION}

while true; 
do gcloud database-migration migration-jobs list --region=${GCP_REGION}; sleep 5; echo;
done
```

### Release

```bash
gcloud database-migration migration-jobs \
	promote pg-to-cloudsql \
	--region=${GCP_REGION}

while true; 
do gcloud database-migration migration-jobs list --region=${GCP_REGION}; sleep 5; echo;
done
```

### Finish

```bash
terraform destroy
terraform state list
```

# Links

- [Migrate a database to Cloud SQL for PostgreSQL by using Database Migration Service](https://cloud.google.com/database-migration/docs/postgres/quickstart)
- [Database Migration Service Connection Profile Postgres](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/database_migration_service_connection_profile#example-usage---database-migration-service-connection-profile-postgres)
- [Goole Cloud SQL](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database)