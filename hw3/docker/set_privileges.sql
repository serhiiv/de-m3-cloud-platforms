-- Get all non-system schemas
DO $$
DECLARE
    schema_name text;
BEGIN
  FOR schema_name IN
    SELECT nspname FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%' AND nspname <> 'information_schema'
  LOOP
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO migrant;', schema_name);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO migrant;', schema_name);
    EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO migrant;', schema_name);
  END LOOP;
END
$$;

-- Grant pglogical access
CREATE EXTENSION IF NOT EXISTS pglogical;
GRANT USAGE ON SCHEMA pglogical TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA pglogical TO migrant;
