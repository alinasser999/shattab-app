-- Read-only guard for the existing health-only API role in PG18 stage.
-- This file never creates or alters a role, grants/revokes privileges, reads
-- password/hash fields, or reads large-object contents.
\set ON_ERROR_STOP on
\pset pager off
\pset format unaligned
\pset tuples_only on
\pset fieldsep '|'

BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;

WITH target_role AS (
  SELECT oid, rolcanlogin, rolinherit, rolsuper, rolcreatedb, rolcreaterole,
         rolreplication, rolbypassrls, rolconnlimit, rolconfig, rolvaliduntil
  FROM pg_roles
  WHERE rolname = 'shattab_api'
), role_summary AS (
  SELECT
    count(*) AS role_count,
    COALESCE(bool_and(
      rolcanlogin
      AND NOT rolinherit
      AND NOT rolsuper
      AND NOT rolcreatedb
      AND NOT rolcreaterole
      AND NOT rolreplication
      AND NOT rolbypassrls
      AND rolconnlimit = 3
      AND rolconfig = ARRAY['search_path=pg_catalog']::text[]
      AND rolvaliduntil IS NULL
    ), false) AS role_attributes_ok
  FROM target_role
), role_memberships AS (
  SELECT count(*) AS membership_count
  FROM pg_auth_members m
  JOIN target_role r ON m.member = r.oid OR m.roleid = r.oid
), role_db_settings AS (
  SELECT count(*) AS database_specific_setting_count
  FROM pg_db_role_setting s
  JOIN target_role r ON s.setrole = r.oid
  WHERE s.setdatabase <> 0
), role_ownership AS (
  SELECT count(*) AS owned_object_count
  FROM pg_shdepend d
  JOIN target_role r ON d.refobjid = r.oid
  WHERE d.refclassid = 'pg_authid'::regclass
    AND d.deptype = 'o'
), role_sessions AS (
  SELECT count(*) AS active_session_count
  FROM pg_stat_activity
  WHERE usename = 'shattab_api'
    AND pid <> pg_backend_pid()
), database_state AS (
  SELECT d.oid, d.datname, d.datdba, d.encoding, d.datacl,
         d.datallowconn, d.datistemplate
  FROM pg_database d
  WHERE d.datname = current_database()
), cluster_database_state AS (
  SELECT d.oid, d.datname, d.datdba, d.datacl, d.datallowconn,
         d.datistemplate
  FROM pg_database d
), cluster_database_summary AS (
  SELECT
    count(*) AS cluster_database_count,
    count(*) FILTER (WHERE d.datname = 'shattab_stage') AS stage_database_count,
    count(*) FILTER (
      WHERE d.datname = 'shattab_stage' AND d.datdba = stage_admin.oid
    ) AS stage_database_owner_count,
    count(*) FILTER (WHERE r.oid IS NOT NULL AND d.datdba = r.oid)
      AS api_owned_database_count,
    count(*) FILTER (WHERE d.datname = 'template0') AS template0_count,
    count(*) FILTER (
      WHERE d.datname = 'template0'
        AND d.datistemplate
        AND NOT d.datallowconn
    ) AS template0_closed_count,
    count(*) FILTER (WHERE d.datname = 'template1') AS template1_count,
    count(*) FILTER (
      WHERE d.datname = 'template1'
        AND d.datistemplate
        AND d.datallowconn
    ) AS template1_connectable_count,
    count(*) FILTER (
      WHERE d.datname <> 'template0' AND NOT d.datallowconn
    ) AS unexpected_closed_database_count,
    count(*) FILTER (WHERE NOT d.datistemplate) AS regular_database_count,
    count(*) FILTER (
      WHERE d.datname !~ '^[A-Za-z_][A-Za-z0-9_]*$'
    ) AS unsafe_database_name_count,
    string_agg(d.datname, ',' ORDER BY d.datname) AS cluster_database_names
  FROM cluster_database_state d
  LEFT JOIN target_role r ON true
  LEFT JOIN pg_roles stage_admin ON stage_admin.rolname = 'shattab_stage_admin'
), catalog_state AS (
  SELECT
    (SELECT count(*)
     FROM pg_namespace n
     WHERE n.nspname <> 'information_schema'
       AND n.nspname !~ '^pg_') AS application_schema_count,
    (SELECT count(*)
     FROM pg_namespace n
     WHERE n.nspname = 'public') AS public_schema_count,
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
       AND n.nspname !~ '^pg_') AS extension_count,
    (SELECT count(*) FROM pg_largeobject_metadata) AS large_object_count
), public_schema_acls AS (
  SELECT
    count(*) FILTER (
      WHERE n.nspname = 'public'
        AND x.grantee = 0
        AND x.privilege_type = 'USAGE'
        AND NOT x.is_grantable
    ) AS public_schema_usage_count,
    count(*) FILTER (
      WHERE x.grantee = 0
        AND (n.nspname <> 'public'
          OR x.privilege_type <> 'USAGE'
          OR x.is_grantable)
    ) AS extra_public_schema_acl_count,
    count(*) FILTER (
      WHERE x.grantee NOT IN (0, n.nspowner)
    ) AS other_schema_acl_count,
    count(*) FILTER (
      WHERE r.oid IS NOT NULL AND x.grantee = r.oid
    ) AS api_direct_schema_acl_count
  FROM pg_namespace n
  CROSS JOIN LATERAL aclexplode(
    COALESCE(n.nspacl, acldefault('n', n.nspowner))
  ) AS x
  LEFT JOIN target_role r ON true
  WHERE n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
), database_acl_by_database AS (
  SELECT
    d.oid,
    d.datname,
    d.datistemplate,
    count(*) FILTER (
      WHERE x.grantee = 0
        AND x.privilege_type = 'CONNECT'
        AND NOT x.is_grantable
    ) AS public_connect_count,
    count(*) FILTER (
      WHERE x.grantee = 0
        AND x.privilege_type = 'TEMPORARY'
        AND NOT x.is_grantable
    ) AS public_temporary_count,
    count(*) FILTER (
      WHERE x.grantee = 0
        AND (x.privilege_type NOT IN ('CONNECT', 'TEMPORARY')
          OR x.is_grantable
          OR x.grantor <> d.datdba)
    ) AS extra_public_database_acl_count,
    count(*) FILTER (
      WHERE x.grantee NOT IN (0, d.datdba)
    ) AS other_database_acl_count,
    count(*) FILTER (
      WHERE r.oid IS NOT NULL AND x.grantee = r.oid
    ) AS api_direct_database_acl_count
  FROM cluster_database_state d
  CROSS JOIN LATERAL aclexplode(
    COALESCE(d.datacl, acldefault('d', d.datdba))
  ) AS x
  LEFT JOIN target_role r ON true
  GROUP BY d.oid, d.datname, d.datistemplate
), public_database_acls AS (
  SELECT
    COALESCE(sum(public_connect_count), 0) AS public_connect_count,
    COALESCE(sum(public_temporary_count), 0) AS public_temporary_count,
    COALESCE(sum(extra_public_database_acl_count), 0)
      AS extra_public_database_acl_count,
    COALESCE(sum(other_database_acl_count), 0) AS other_database_acl_count,
    COALESCE(sum(api_direct_database_acl_count), 0)
      AS api_direct_database_acl_count,
    count(*) FILTER (WHERE public_connect_count <> 1)
      AS nonbaseline_public_connect_database_count,
    count(*) FILTER (
      WHERE public_temporary_count <> CASE WHEN datistemplate THEN 0 ELSE 1 END
    )
      AS nonbaseline_public_temporary_database_count
  FROM database_acl_by_database
), application_object_acls AS (
  SELECT x.grantee, x.privilege_type, x.is_grantable
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
  WHERE n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
    AND c.relkind IN ('r', 'p', 'S', 'v', 'm', 'f')

  UNION ALL

  SELECT x.grantee, x.privilege_type, x.is_grantable
  FROM pg_attribute a
  JOIN pg_class c ON c.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  CROSS JOIN LATERAL aclexplode(a.attacl) AS x
  WHERE a.attnum > 0
    AND NOT a.attisdropped
    AND a.attacl IS NOT NULL
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'

  UNION ALL

  SELECT x.grantee, x.privilege_type, x.is_grantable
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(
    COALESCE(p.proacl, acldefault('f', p.proowner))
  ) AS x
  WHERE n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'

  UNION ALL

  SELECT x.grantee, x.privilege_type, x.is_grantable
  FROM pg_type t
  JOIN pg_namespace n ON n.oid = t.typnamespace
  CROSS JOIN LATERAL aclexplode(
    COALESCE(t.typacl, acldefault('T', t.typowner))
  ) AS x
  WHERE n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
    AND t.typtype <> 'p'
), object_acl_summary AS (
  SELECT
    count(*) FILTER (WHERE grantee = 0) AS public_object_acl_count,
    count(*) FILTER (WHERE r.oid IS NOT NULL AND grantee = r.oid)
      AS api_direct_object_acl_count
  FROM application_object_acls a
  LEFT JOIN target_role r ON true
), large_object_acls AS (
  SELECT
    count(*) FILTER (WHERE x.grantee = 0) AS public_large_object_acl_count,
    count(*) FILTER (WHERE r.oid IS NOT NULL AND x.grantee = r.oid)
      AS api_direct_large_object_acl_count
  FROM pg_largeobject_metadata lom
  CROSS JOIN LATERAL aclexplode(
    COALESCE(lom.lomacl, acldefault('L', lom.lomowner))
  ) AS x
  LEFT JOIN target_role r ON true
), explicit_default_acls AS (
  SELECT count(*) AS explicit_default_acl_count
  FROM pg_default_acl
), stock_function_defaults AS (
  SELECT
    count(*) FILTER (
      WHERE x.grantee = 0
        AND x.privilege_type = 'EXECUTE'
        AND NOT x.is_grantable
    ) AS public_function_execute_default_count,
    count(*) FILTER (
      WHERE x.grantee = 0
        AND (x.privilege_type <> 'EXECUTE' OR x.is_grantable)
    ) AS extra_public_function_default_count
  FROM pg_roles admin_role
  CROSS JOIN LATERAL aclexplode(acldefault('f', admin_role.oid)) AS x
  WHERE admin_role.rolname = 'shattab_stage_admin'
), effective_api_privileges AS (
  SELECT
    count(*) FILTER (
      WHERE has_database_privilege(r.oid, d.oid, 'CONNECT')
    ) AS cluster_database_connect_count,
    count(*) FILTER (
      WHERE has_database_privilege(r.oid, d.oid, 'TEMPORARY')
    ) AS cluster_database_temporary_count,
    count(*) FILTER (
      WHERE has_database_privilege(r.oid, d.oid, 'CREATE')
    ) AS cluster_database_create_count,
    COALESCE(bool_and(has_database_privilege(
      r.oid, current_database(), 'CONNECT'
    )), false) AS database_connect,
    COALESCE(bool_and(has_database_privilege(
      r.oid, current_database(), 'TEMPORARY'
    )), false) AS database_temporary,
    COALESCE(bool_or(has_database_privilege(
      r.oid, current_database(), 'CREATE'
    )), false) AS database_create,
    COALESCE(bool_and(has_schema_privilege(
      r.oid, 'public', 'USAGE'
    )), false) AS public_schema_usage,
    COALESCE(bool_or(has_schema_privilege(
      r.oid, 'public', 'CREATE'
    )), false) AS public_schema_create
  FROM target_role r
  CROSS JOIN cluster_database_state d
), target_state AS (
  SELECT
    current_database() AS database_name,
    (SELECT datallowconn FROM database_state) AS current_database_in_scope,
    (SELECT datistemplate FROM database_state) AS current_database_is_template,
    current_user AS inspector_role,
    current_setting('server_version_num') AS server_version_num,
    (SELECT encoding = pg_char_to_encoding('UTF8') FROM database_state)
      AS database_utf8,
    (SELECT role_count FROM role_summary) AS api_role_count,
    (SELECT role_attributes_ok FROM role_summary) AS role_attributes_ok,
    (SELECT membership_count FROM role_memberships) AS membership_count,
    (SELECT database_specific_setting_count FROM role_db_settings)
      AS database_specific_setting_count,
    (SELECT owned_object_count FROM role_ownership) AS owned_object_count,
    (SELECT active_session_count FROM role_sessions) AS active_session_count,
    catalog.application_schema_count,
    catalog.public_schema_count,
    catalog.relation_count,
    catalog.routine_count,
    catalog.type_count,
    catalog.extension_count,
    catalog.large_object_count,
    schema_acls.public_schema_usage_count,
    schema_acls.extra_public_schema_acl_count,
    schema_acls.other_schema_acl_count,
    schema_acls.api_direct_schema_acl_count,
    database_acls.public_connect_count,
    database_acls.public_temporary_count,
    database_acls.extra_public_database_acl_count,
    database_acls.other_database_acl_count,
    database_acls.api_direct_database_acl_count,
    database_acls.nonbaseline_public_connect_database_count,
    database_acls.nonbaseline_public_temporary_database_count,
    cluster_databases.cluster_database_count,
    cluster_databases.stage_database_count,
    cluster_databases.stage_database_owner_count,
    cluster_databases.api_owned_database_count,
    cluster_databases.template0_count,
    cluster_databases.template0_closed_count,
    cluster_databases.template1_count,
    cluster_databases.template1_connectable_count,
    cluster_databases.unexpected_closed_database_count,
    cluster_databases.regular_database_count,
    cluster_databases.unsafe_database_name_count,
    cluster_databases.cluster_database_names,
    object_acls.public_object_acl_count,
    object_acls.api_direct_object_acl_count,
    large_acls.public_large_object_acl_count,
    large_acls.api_direct_large_object_acl_count,
    defaults.explicit_default_acl_count,
    function_defaults.public_function_execute_default_count,
    function_defaults.extra_public_function_default_count,
    effective.cluster_database_connect_count,
    effective.cluster_database_temporary_count,
    effective.cluster_database_create_count,
    effective.database_connect,
    effective.database_temporary,
    effective.database_create,
    effective.public_schema_usage,
    effective.public_schema_create
  FROM catalog_state catalog
  CROSS JOIN public_schema_acls schema_acls
  CROSS JOIN public_database_acls database_acls
  CROSS JOIN cluster_database_summary cluster_databases
  CROSS JOIN object_acl_summary object_acls
  CROSS JOIN large_object_acls large_acls
  CROSS JOIN explicit_default_acls defaults
  CROSS JOIN stock_function_defaults function_defaults
  CROSS JOIN effective_api_privileges effective
)
SELECT
  database_name,
  current_database_in_scope::text AS current_database_in_scope,
  inspector_role,
  server_version_num,
  database_utf8::text AS database_utf8,
  api_role_count::text AS api_role_count,
  role_attributes_ok::text AS role_attributes_ok,
  membership_count::text AS membership_count,
  database_specific_setting_count::text AS database_specific_setting_count,
  owned_object_count::text AS owned_object_count,
  active_session_count::text AS active_session_count,
  application_schema_count::text AS application_schema_count,
  public_schema_count::text AS public_schema_count,
  relation_count::text AS relation_count,
  routine_count::text AS routine_count,
  type_count::text AS type_count,
  extension_count::text AS extension_count,
  large_object_count::text AS large_object_count,
  public_schema_usage_count::text AS public_schema_usage_count,
  extra_public_schema_acl_count::text AS extra_public_schema_acl_count,
  other_schema_acl_count::text AS other_schema_acl_count,
  api_direct_schema_acl_count::text AS api_direct_schema_acl_count,
  public_connect_count::text AS public_connect_count,
  public_temporary_count::text AS public_temporary_count,
  extra_public_database_acl_count::text AS extra_public_database_acl_count,
  other_database_acl_count::text AS other_database_acl_count,
  api_direct_database_acl_count::text AS api_direct_database_acl_count,
  nonbaseline_public_connect_database_count::text AS nonbaseline_public_connect_database_count,
  nonbaseline_public_temporary_database_count::text AS nonbaseline_public_temporary_database_count,
  cluster_database_count::text AS cluster_database_count,
  stage_database_count::text AS stage_database_count,
  stage_database_owner_count::text AS stage_database_owner_count,
  api_owned_database_count::text AS api_owned_database_count,
  template0_count::text AS template0_count,
  template0_closed_count::text AS template0_closed_count,
  template1_count::text AS template1_count,
  template1_connectable_count::text AS template1_connectable_count,
  unexpected_closed_database_count::text AS unexpected_closed_database_count,
  regular_database_count::text AS regular_database_count,
  unsafe_database_name_count::text AS unsafe_database_name_count,
  cluster_database_names,
  public_object_acl_count::text AS public_object_acl_count,
  api_direct_object_acl_count::text AS api_direct_object_acl_count,
  public_large_object_acl_count::text AS public_large_object_acl_count,
  api_direct_large_object_acl_count::text AS api_direct_large_object_acl_count,
  explicit_default_acl_count::text AS explicit_default_acl_count,
  public_function_execute_default_count::text AS public_function_execute_default_count,
  extra_public_function_default_count::text AS extra_public_function_default_count,
  cluster_database_connect_count::text AS cluster_database_connect_count,
  cluster_database_temporary_count::text AS cluster_database_temporary_count,
  cluster_database_create_count::text AS cluster_database_create_count,
  database_connect::text AS database_connect,
  database_temporary::text AS database_temporary,
  database_create::text AS database_create,
  public_schema_usage::text AS public_schema_usage,
  public_schema_create::text AS public_schema_create,
  (
    current_database_in_scope
    AND inspector_role = 'shattab_stage_admin'
    AND server_version_num = '180006'
    AND database_utf8
    AND cluster_database_count >= 1
    AND stage_database_count = 1
    AND stage_database_owner_count = 1
    AND api_owned_database_count = 0
    AND template0_count = 1
    AND template0_closed_count = 1
    AND template1_count = 1
    AND template1_connectable_count = 1
    AND unexpected_closed_database_count = 0
    AND unsafe_database_name_count = 0
    AND api_role_count = 1
    AND role_attributes_ok
    AND membership_count = 0
    AND database_specific_setting_count = 0
    AND owned_object_count = 0
    AND active_session_count = 0
    AND application_schema_count = 1
    AND public_schema_count = 1
    AND relation_count = 0
    AND routine_count = 0
    AND type_count = 0
    AND extension_count = 0
    AND large_object_count = 0
    AND public_schema_usage_count = 1
    AND extra_public_schema_acl_count = 0
    AND other_schema_acl_count = 0
    AND api_direct_schema_acl_count = 0
    AND public_connect_count = cluster_database_count
    AND public_temporary_count = regular_database_count
    AND nonbaseline_public_connect_database_count = 0
    AND nonbaseline_public_temporary_database_count = 0
    AND extra_public_database_acl_count = 0
    AND other_database_acl_count = 0
    AND api_direct_database_acl_count = 0
    AND cluster_database_connect_count = cluster_database_count
    AND cluster_database_temporary_count = regular_database_count
    AND cluster_database_create_count = 0
    AND public_object_acl_count = 0
    AND api_direct_object_acl_count = 0
    AND public_large_object_acl_count = 0
    AND api_direct_large_object_acl_count = 0
    AND explicit_default_acl_count = 0
    AND public_function_execute_default_count = 1
    AND extra_public_function_default_count = 0
    AND database_connect
    AND (
      (current_database_is_template AND NOT database_temporary)
      OR (NOT current_database_is_template AND database_temporary)
    )
    AND NOT database_create
    AND public_schema_usage
    AND NOT public_schema_create
  ) AS target_ok
FROM target_state
\gset

\echo Existing API-role inspection: database= :database_name , inspector= :inspector_role , PostgreSQL= :server_version_num , UTF8= :database_utf8
\echo All PG18 database inventory: count= :cluster_database_count , regular= :regular_database_count , stage_matches= :stage_database_count , stage_owner_matches= :stage_database_owner_count , names= :cluster_database_names , template0= :template0_count , template0_closed= :template0_closed_count , template1= :template1_count , template1_connectable= :template1_connectable_count , unexpected_closed= :unexpected_closed_database_count , unsafe_names= :unsafe_database_name_count , API_owned= :api_owned_database_count
\echo Role guard: matches= :api_role_count , attributes_match= :role_attributes_ok , memberships= :membership_count , database_specific_settings= :database_specific_setting_count , owned_objects= :owned_object_count , active_sessions= :active_session_count
\echo Application catalog: schemas= :application_schema_count , public_schema= :public_schema_count , relations= :relation_count , routines= :routine_count , types= :type_count , extensions= :extension_count , large_objects= :large_object_count
\echo PUBLIC baseline: schema USAGE= :public_schema_usage_count , database CONNECT= :public_connect_count , database TEMPORARY= :public_temporary_count , DBs with non-baseline CONNECT= :nonbaseline_public_connect_database_count , DBs with non-baseline TEMP= :nonbaseline_public_temporary_database_count
\echo Rejected ACLs: extra_PUBLIC_schema= :extra_public_schema_acl_count , other_schema= :other_schema_acl_count , API_direct_schema= :api_direct_schema_acl_count , extra_PUBLIC_database= :extra_public_database_acl_count , other_database= :other_database_acl_count , API_direct_database= :api_direct_database_acl_count
\echo Object ACLs: PUBLIC= :public_object_acl_count , API_direct= :api_direct_object_acl_count , PUBLIC_large_object= :public_large_object_acl_count , API_direct_large_object= :api_direct_large_object_acl_count
\echo Defaults and effective privileges: explicit_default_ACLs= :explicit_default_acl_count , PUBLIC_future_function_EXECUTE= :public_function_execute_default_count , extra_PUBLIC_future_function_defaults= :extra_public_function_default_count , cluster_CONNECT= :cluster_database_connect_count , cluster_TEMP= :cluster_database_temporary_count , cluster_CREATE= :cluster_database_create_count , database_CONNECT= :database_connect , database_TEMP= :database_temporary , database_CREATE= :database_create , public_schema_USAGE= :public_schema_usage , public_schema_CREATE= :public_schema_create

\if :target_ok
  COMMIT;
  \echo PASS: the existing health-only API role and every PostgreSQL 18 database match the reviewed ACL baseline; template1 was included and template0 is closed; no permission or role setting was changed.
\else
  ROLLBACK;
  \echo FAIL: existing-role or cluster-wide database state differs from the reviewed baseline; stop before changing its password, creating a secret, or starting API.
  \quit 1
\endif
