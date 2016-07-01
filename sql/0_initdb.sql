-- TODO! this no longer works with vagrant
-- execute with
-- sudo -H -u postgres bash -c 'psql -f ./main.sql'

-- drop database app;
-- create database app;

-- \connect app

-- begin;
alter database app set postgrest.claims.user_id to '';
alter database app set postgrest.claims.company_id to '';
alter database app set postgrest.claims.SESSIONID to '';
create extension pgcrypto;
-- \ir ./includes/functions.sql
-- \ir ./includes/data_schema.sql
-- \ir ./includes/api_schema.sql
-- \ir ./includes/roles.sql
-- \ir ./includes/small_rls_dataset.sql
-- commit;
