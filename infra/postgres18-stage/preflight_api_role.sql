-- Read-only guard for the dedicated health-only API login.
-- Run only against the isolated PG18 stage with its administrator over the local socket.
-- The PostgreSQL 18 stock PUBLIC defaults (public-schema USAGE and database
-- CONNECT/TEMPORARY) are reported and allowed; all other PUBLIC grants fail.
-- This reports catalog metadata only; it never reads a password or user data.
-- Large-object checks read pg_largeobject_metadata only, never pg_largeobject data.
\set ON_ERROR_STOP on
\pset pager off
\pset format unaligned
\pset tuples_only on
\pset fieldsep '|'

WITH non_system_objects AS (
  SELECT
    (SELECT count(*)
     FROM pg_namespace n
     WHERE n.nspname <> 'information_schema'
       AND n.nspname !~ '^pg_') AS schema_count,
    (SELECT count(*)
     FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname <> 'information_schema'
       AND n.nspname !~ '^pg_'
       AND c.relkind IN ('r', 'p', 'S', 'v', 'm', 'f')) AS relation_count,
    (SELECT count(*)
     FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname <> 'information_schema'
       AND n.nspname !~ '^pg_') AS routine_count,
    (SELECT count(*)
     FROM pg_type t
     JOIN pg_namespace n ON n.oid = t.typnamespace
     WHERE n.nspname <> 'information_schema'
       AND n.nspname !~ '^pg_'
       AND t.typtype <> 'p') AS type_count,
    (SELECT count(*)
     FROM pg_extension e
     JOIN pg_namespace n ON n.oid = e.extnamespace
     WHERE n.nspname <> 'information_schema'
       AND n.nspname !~ '^pg_') AS extension_count
), public_schema_privileges AS (
  SELECT
    count(*) FILTER (
      WHERE n.nspname = 'public'
        AND x.privilege_type = 'USAGE'
        AND NOT x.is_grantable
    ) AS public_schema_usage_count,
    count(*) FILTER (
      WHERE n.nspname <> 'public'
         OR x.privilege_type <> 'USAGE'
         OR x.is_grantable
    ) AS extra_public_schema_privilege_count
  FROM pg_namespace n
  CROSS JOIN LATERAL aclexplode(
    COALESCE(n.nspacl, acldefault('n', n.nspowner))
  ) AS x
  WHERE x.grantee = 0
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
), public_object_privileges AS (
  SELECT count(*) AS privilege_count
  FROM (
    SELECT x.privilege_type
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    CROSS JOIN LATERAL aclexplode(
      COALESCE(
        c.relacl,
        acldefault(
          (CASE WHEN c.relkind = 'S' THEN 's' ELSE 'r' END)::"char",
          c.relowner
        )
      )
    ) AS x
    WHERE x.grantee = 0
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_'
      AND c.relkind IN ('r', 'p', 'S', 'v', 'm', 'f')

    UNION ALL

    SELECT x.privilege_type
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    CROSS JOIN LATERAL aclexplode(
      COALESCE(p.proacl, acldefault('f', p.proowner))
    ) AS x
    WHERE x.grantee = 0
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_'

    UNION ALL

    SELECT x.privilege_type
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    CROSS JOIN LATERAL aclexplode(
      COALESCE(t.typacl, acldefault('T', t.typowner))
    ) AS x
    WHERE x.grantee = 0
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_'
      AND t.typtype <> 'p'
  ) AS grants_to_public
), public_database_privileges AS (
  SELECT
    count(*) FILTER (
      WHERE x.privilege_type = 'CONNECT' AND NOT x.is_grantable
    ) AS public_connect_count,
    count(*) FILTER (
      WHERE x.privilege_type = 'TEMPORARY' AND NOT x.is_grantable
    ) AS public_temporary_count,
    count(*) FILTER (
      WHERE x.privilege_type NOT IN ('CONNECT', 'TEMPORARY')
         OR x.is_grantable
    ) AS extra_public_db_privilege_count
  FROM pg_database d
  CROSS JOIN LATERAL aclexplode(
    COALESCE(d.datacl, acldefault('d', d.datdba))
  ) AS x
  WHERE d.datname = current_database()
    AND x.grantee = 0
), large_object_privileges AS (
  SELECT
    (SELECT count(*) FROM pg_largeobject_metadata) AS large_object_count,
    (SELECT count(*)
     FROM pg_largeobject_metadata lom
     CROSS JOIN LATERAL aclexplode(
       COALESCE(lom.lomacl, acldefault('L', lom.lomowner))
     ) AS x
     WHERE x.grantee = 0) AS public_large_object_privilege_count
), explicit_default_acls AS (
  SELECT count(*) AS explicit_default_acl_count
  FROM pg_default_acl
), stock_future_function_defaults AS (
  SELECT count(*) AS public_function_execute_default_count
  FROM pg_roles r
  CROSS JOIN LATERAL aclexplode(acldefault('f', r.oid)) AS x
  WHERE r.rolname = 'shattab_stage_admin'
    AND x.grantee = 0
    AND x.privilege_type = 'EXECUTE'
    AND NOT x.is_grantable
)
SELECT
  current_database() AS database_name,
  current_user AS login_name,
  current_setting('server_version_num') AS server_version_num,
  objects.schema_count::text AS schema_count,
  objects.relation_count::text AS relation_count,
  objects.routine_count::text AS routine_count,
  objects.type_count::text AS type_count,
  objects.extension_count::text AS extension_count,
  (SELECT count(*) FROM pg_roles WHERE rolname = 'shattab_api')::text AS api_role_count,
  schema_grants.public_schema_usage_count::text AS public_schema_usage_count,
  schema_grants.extra_public_schema_privilege_count::text AS extra_public_schema_privilege_count,
  object_grants.privilege_count::text AS public_object_privilege_count,
  database_grants.public_connect_count::text AS public_connect_count,
  database_grants.public_temporary_count::text AS public_temporary_count,
  database_grants.extra_public_db_privilege_count::text AS extra_public_db_privilege_count,
  large_objects.large_object_count::text AS large_object_count,
  large_objects.public_large_object_privilege_count::text AS public_large_object_privilege_count,
  defaults.explicit_default_acl_count::text AS explicit_default_acl_count,
  future_defaults.public_function_execute_default_count::text AS public_function_execute_default_count,
  (
    current_database() = 'shattab_stage'
    AND current_user = 'shattab_stage_admin'
    AND current_setting('server_version_num') = '180006'
    AND objects.schema_count = 1
    AND objects.relation_count = 0
    AND objects.routine_count = 0
    AND objects.type_count = 0
    AND objects.extension_count = 0
    AND NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'shattab_api')
    AND schema_grants.public_schema_usage_count = 1
    AND schema_grants.extra_public_schema_privilege_count = 0
    AND object_grants.privilege_count = 0
    AND database_grants.public_connect_count = 1
    AND database_grants.public_temporary_count = 1
    AND database_grants.extra_public_db_privilege_count = 0
    AND large_objects.large_object_count = 0
    AND large_objects.public_large_object_privilege_count = 0
    AND defaults.explicit_default_acl_count = 0
    AND future_defaults.public_function_execute_default_count = 1
  ) AS preflight_ok
FROM non_system_objects objects
CROSS JOIN public_schema_privileges schema_grants
CROSS JOIN public_object_privileges object_grants
CROSS JOIN public_database_privileges database_grants
CROSS JOIN large_object_privileges large_objects
CROSS JOIN explicit_default_acls defaults
CROSS JOIN stock_future_function_defaults future_defaults
\gset

\echo Stage preflight: database= :database_name , login= :login_name , PostgreSQL= :server_version_num
\echo Catalog counts: schemas= :schema_count , relations= :relation_count , routines= :routine_count , types= :type_count , extensions= :extension_count , API role matches= :api_role_count
\echo Allowed stock PUBLIC defaults: public schema USAGE= :public_schema_usage_count , database CONNECT= :public_connect_count , database TEMPORARY= :public_temporary_count
\echo Rejected PUBLIC grants: extra schema= :extra_public_schema_privilege_count , application objects= :public_object_privilege_count , extra database= :extra_public_db_privilege_count
\echo Large objects: total= :large_object_count , PUBLIC ACL entries= :public_large_object_privilege_count
\echo Additional guards: explicit default ACLs= :explicit_default_acl_count , stock future function EXECUTE defaults= :public_function_execute_default_count

\if :preflight_ok
  \echo PASS: stock PostgreSQL 18 defaults and the empty health-only target match; no application privileges are granted.
  \echo NOTE: PostgreSQL grants EXECUTE to PUBLIC on newly created functions by default; do not add application routines or other objects without a separate ACL review and a fresh preflight.
\else
  \echo FAIL: stage identity, empty-catalog, large-object, role-absence, or PUBLIC/default ACL checks failed; do not create the API role or secret.
  DO $$
  BEGIN
    RAISE EXCEPTION 'stage preflight guard rejected target';
  END
  $$;
\endif
