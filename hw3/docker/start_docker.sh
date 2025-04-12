export POSTGRES_PASSWORD="it[y.MS6m0Eb9pK"


#####
cat Dockerfile 


#####
cat docker-compose.yml
sleep 2


##### run docker
docker compose up -d --force-recreate
docker ps
sleep 5


# check pglogical settings
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
sleep 2


# load database
wget -q https://raw.githubusercontent.com/neondatabase/postgres-sample-dbs/main/periodic_table.sql

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE periodic_table;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -f periodic_table.sql

rm periodic_table.sql
sleep 2


# create user for migration
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE ROLE migrant WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migrant WITH LOGIN;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "ALTER ROLE migrant WITH REPLICATION;"

psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/postgres" -c "CREATE DATABASE migrant WITH OWNER migrant;"
sleep 2


DBS=("migrant" "postgres" "periodic_table")
for DB in "${DBS[@]}"; do
  psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/$DB" -f set_privileges.sql
done
sleep 2


# check database load
psql -d "postgres://postgres:${POSTGRES_PASSWORD}@localhost/periodic_table" -c 'select pt."AtomicNumber", pt."Element", pt."Symbol"  from periodic_table pt where pt."AtomicMass" < 10;'
