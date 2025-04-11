export POSTGRES_PASSWORD="it[y.MS6m0Eb9pK"

docker compose up -d --force-recreate

sleep 5

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


wget https://raw.githubusercontent.com/neondatabase/postgres-sample-dbs/main/periodic_table.sql
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE periodic_table;"
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -f periodic_table.sql
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -c 'select pt."AtomicNumber", pt."Element", pt."Symbol"  from periodic_table pt where pt."AtomicMass" < 10;'
rm periodic_table.sql


psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE ROLE migration_user WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';"
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migration_user WITH LOGIN;"
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migration_user WITH REPLICATION;"
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE migration_user WITH OWNER migration_user;"


DBS=("migration_user" "postgres" "periodic_table")

for DB in "${DBS[@]}"; do
  psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/$DB" -f set_privileges.sql
done


# gcloud beta resource-config bulk-export --project=de-module-3 --resource-format=terraform >> gcp_resources.tf