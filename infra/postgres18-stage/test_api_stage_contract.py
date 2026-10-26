"""Offline checks for the staged health-only API boundary.

Compose validation runs only against a temporary directory populated with
non-secret placeholders. The test never opens the ignored secrets directory,
starts a container, contacts a database, or writes to a cloud host.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent.parent
STAGE = ROOT / "infra" / "postgres18-stage"
API = ROOT / "api"
COMPOSE = STAGE / "compose.yaml"
DOCKERFILE = API / "Dockerfile"
PACKAGE = API / "package.json"
LOCKFILE = API / "package-lock.json"
PREFLIGHT = STAGE / "preflight_api_role.sql"
ROLE_SQL = STAGE / "create_api_role.sql"
STAGE_README = STAGE / "README.md"
SECRET_HELPER = STAGE / "create_api_secret.py"
API_README = API / "README.md"
ROLE_TEST = STAGE / "test_api_role_postgres18.py"
CI_WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"

NODE_IMAGE = (
    "node:24.22.1-bookworm-slim@sha256:"
    "55fb5f5a527ea2c5c4a95f963e48ef90aa38c7b346054fdc8ee9957a2b55d205"
)


def compose_model() -> dict[str, object] | None:
    if os.environ.get("SHATTAB_STAGE_OFFLINE_ONLY") == "1":
        return None
    docker = shutil.which("docker")
    if docker is None:
        return None

    with tempfile.TemporaryDirectory(prefix="shattab-api-compose-contract-") as raw:
        directory = Path(raw)
        shutil.copy2(COMPOSE, directory / "compose.yaml")
        (directory / "api-source").mkdir()
        secrets = directory / "secrets"
        secrets.mkdir()
        # Harmless placeholders: deliberately unrelated to any actual credential.
        (secrets / "postgres_password").write_text("offline-placeholder\n", encoding="ascii")
        (secrets / "api_password").write_text("offline-placeholder\n", encoding="ascii")
        env_file = directory / "empty.env"
        env_file.write_text("", encoding="ascii")

        result = subprocess.run(
            [
                docker,
                "compose",
                "--env-file",
                str(env_file),
                "-f",
                str(directory / "compose.yaml"),
                "-p",
                "shattab-stage-contract-test",
                "config",
                "--format",
                "json",
            ],
            cwd=directory,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
            timeout=30,
        )
        if result.returncode != 0:
            raise AssertionError(
                "Temporary Docker Compose config validation failed: "
                f"{result.stderr.strip()}"
            )
        return json.loads(result.stdout)


class ApiStageContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.model = compose_model()

    def test_all_dockerfile_stages_pin_the_reviewed_node_digest(self) -> None:
        dockerfile = DOCKERFILE.read_text(encoding="utf-8")
        from_lines = [line for line in dockerfile.splitlines() if line.startswith("FROM ")]
        self.assertEqual(len(from_lines), 3)
        self.assertTrue(all(NODE_IMAGE in line for line in from_lines))
        self.assertRegex(dockerfile, r"(?m)^USER node$")

    def test_package_engine_metadata_matches_the_pinned_runtime_floor(self) -> None:
        package = json.loads(PACKAGE.read_text(encoding="utf-8"))
        lock = json.loads(LOCKFILE.read_text(encoding="utf-8"))
        self.assertEqual(package["engines"]["node"], ">=24.22.1 <25")
        self.assertEqual(lock["packages"][""]["engines"]["node"], ">=24.22.1 <25")

    def test_compose_model_keeps_api_private_and_admin_secret_separate(self) -> None:
        if self.model is None:
            self.skipTest("Docker CLI is unavailable; source contract assertions still run.")
        services = self.model["services"]
        db = services["db"]
        api = services["api"]
        networks = self.model["networks"]
        volumes = self.model["volumes"]
        secrets = self.model["secrets"]

        self.assertEqual(db["image"], "postgres:18.6-bookworm@sha256:bbf83594798e144bff365a9c191c5d779f181fb3135902064ab8ff11918020fc")
        self.assertEqual(set(db["networks"]), {"db_internal"})
        self.assertEqual(set(api["networks"]), {"db_internal"})
        self.assertEqual(
            [(volume["source"], volume["target"]) for volume in db["volumes"]],
            [("pgdata", "/var/lib/postgresql")],
        )
        self.assertNotIn("ports", db)
        self.assertNotIn("ports", api)
        self.assertEqual(Path(api["build"]["context"]).name, "api-source")
        self.assertEqual(networks["db_internal"]["name"], "shattab-pg18-stage_db_internal")
        self.assertTrue(networks["db_internal"]["internal"])
        self.assertEqual(volumes["pgdata"]["name"], "shattab-pg18-stage_pgdata")
        self.assertEqual(Path(secrets["postgres_password"]["file"]).name, "postgres_password")
        self.assertEqual(Path(secrets["api_password"]["file"]).name, "api_password")
        self.assertEqual({entry["source"] for entry in db["secrets"]}, {"postgres_password"})
        self.assertEqual({entry["source"] for entry in api["secrets"]}, {"api_password"})

    def test_api_runtime_has_bounded_private_health_only_settings(self) -> None:
        if self.model is None:
            self.skipTest("Docker CLI is unavailable; source contract assertions still run.")
        api = self.model["services"]["api"]
        environment = api["environment"]
        self.assertEqual(environment["DATABASE_HOST"], "db")
        self.assertEqual(environment["DATABASE_NAME"], "shattab_stage")
        self.assertEqual(environment["DATABASE_USER"], "shattab_api")
        self.assertEqual(environment["DATABASE_PASSWORD_FILE"], "/run/secrets/api_password")
        self.assertEqual(environment["DATABASE_POOL_MAX"], "2")
        self.assertNotIn("DATABASE_PASSWORD", environment)
        self.assertNotIn("DATABASE_URL", environment)
        self.assertEqual(api["depends_on"]["db"]["condition"], "service_healthy")
        self.assertTrue(api["read_only"])
        self.assertEqual(api["restart"], "no")
        self.assertEqual(api["mem_limit"], "536870912")
        self.assertEqual(api["cpus"], 0.5)
        self.assertEqual(api["pids_limit"], 64)
        self.assertIn("no-new-privileges:true", api["security_opt"])
        self.assertIn("ALL", api["cap_drop"])
        self.assertIn("/health/ready", " ".join(api["healthcheck"]["test"]))

    def test_preflight_is_read_only_and_checks_stage_public_privileges(self) -> None:
        sql = re.sub(r"(?m)^\s*--.*$", "", PREFLIGHT.read_text(encoding="utf-8"))
        sql_without_psql_meta = "\n".join(
            line for line in sql.splitlines() if not line.lstrip().startswith("\\")
        )
        forbidden = re.compile(
            r"\b(CREATE|ALTER|DROP|GRANT|REVOKE|INSERT|UPDATE|DELETE|TRUNCATE|COPY|CALL)\b",
            re.IGNORECASE,
        )
        self.assertIsNone(forbidden.search(sql_without_psql_meta))
        for expected in (
            "shattab_stage",
            "shattab_stage_admin",
            "180006",
            "/var/lib/postgresql/18/docker",
            "aclexplode",
            "x.grantee = 0",
            "shattab_api",
            "public_schema_usage_count",
            "extra_public_schema_privilege_count",
            "public_connect_count",
            "public_temporary_count",
            "extra_public_db_privilege_count",
            "pg_largeobject_metadata",
            "acldefault('L', lom.lomowner)",
            "large_object_count",
            "public_large_object_privilege_count",
            "lom.lomacl",
            "explicit_default_acl_count",
            "public_function_execute_default_count",
            r"\quit 1",
        ):
            self.assertIn(expected, sql)
        self.assertIn("NOT x.is_grantable", sql)
        self.assertIn("x.privilege_type = 'USAGE'", sql)
        self.assertIn("x.privilege_type = 'TEMPORARY'", sql)
        self.assertRegex(
            sql,
            r"acldefault\(\s*\(CASE WHEN c\.relkind = 'S' THEN 's' ELSE 'r' END\)::\"char\",\s*c\.relowner\s*\)",
        )

    def test_role_creation_is_guarded_and_does_not_embed_a_password(self) -> None:
        sql = ROLE_SQL.read_text(encoding="utf-8")
        for expected in (
            "BEGIN;",
            "current_database() = 'shattab_stage'",
            "current_user = 'shattab_stage_admin'",
            "current_setting('server_version_num') = '180006'",
            "current_setting('data_directory') = '/var/lib/postgresql/18/docker'",
            "aclexplode",
            "x.grantee = 0",
            "public_schema_usage_count = 1",
            "public_connect_count = 1",
            "public_temporary_count = 1",
            "pg_largeobject_metadata",
            "acldefault('L', lom.lomowner)",
            "large_object_count = 0",
            "public_large_object_privilege_count = 0",
            "lom.lomacl",
            "explicit_default_acl_count = 0",
            "public_function_execute_default_count = 1",
            "extra_privilege_count = 0",
            "CREATE ROLE shattab_api",
            "NOSUPERUSER",
            "NOCREATEDB",
            "NOCREATEROLE",
            "NOREPLICATION",
            "NOBYPASSRLS",
            "NOINHERIT",
            "CONNECTION LIMIT 3",
            "ALTER ROLE shattab_api SET search_path = pg_catalog",
            "ROLLBACK;",
        ):
            self.assertIn(expected, sql)
        self.assertIn(r"\password prompt", sql)
        self.assertNotRegex(sql, r"(?i)\bPASSWORD\s+['\"]")
        self.assertRegex(
            sql,
            r"acldefault\(\s*\(CASE WHEN c\.relkind = 'S' THEN 's' ELSE 'r' END\)::\"char\",\s*c\.relowner\s*\)",
        )

    def test_documented_secret_flow_is_hidden_absent_only_and_non_destructive(self) -> None:
        readme = STAGE_README.read_text(encoding="utf-8")
        secret_helper = SECRET_HELPER.read_text(encoding="utf-8")
        self.assertIn("/home/ubuntu/shattab-pg18-stage/api-source/", readme)
        self.assertIn("create_api_secret.py", readme)
        self.assertIn("--node-uid", readme)
        self.assertIn("--node-gid", readme)
        self.assertIn("root:<process-gid>", readme)
        self.assertIn("وضع `0440`", readme)
        self.assertIn("O_EXCL", secret_helper)
        self.assertIn("getpass.getpass", secret_helper)
        self.assertIn("os.link(temporary_path, target, follow_symlinks=False)", secret_helper)
        self.assertIn("parent_stat.st_uid != 0", secret_helper)
        self.assertIn("before.st_gid != os.getgid()", secret_helper)
        self.assertIn("temporary file may remain", secret_helper)
        self.assertIn("cleanup_failed", secret_helper)
        self.assertIn("test ! -e", readme)
        self.assertIn("ما تفترضش إن الأرقام `1000:1000`", readme)
        self.assertIn("sudo chown root:root /home/ubuntu/shattab-pg18-stage/secrets", readme)
        self.assertIn("بعد تطابق الهوية، شغّل API فقط", readme)
        self.assertIn("node:24.22.1-bookworm-slim@sha256:", readme)
        self.assertIn("صورة API المكتملة", readme)
        password_preparation = readme.index("لازم تكون بترميز `UTF-8`")
        role_password_prompt = readme.index(r"\password shattab_api")
        self.assertLess(password_preparation, role_password_prompt)
        for expected in (
            "32 إلى 4096 بايت",
            "`NUL`",
            "`LF`",
            "`CR`",
            "`argv`",
            "`env`",
        ):
            self.assertIn(expected, readme)
        ownership_change = readme.index(
            "sudo chown root:root /home/ubuntu/shattab-pg18-stage/secrets"
        )
        directory_verified = readme.index("المتوقع بالضبط `700 0:0`", ownership_change)
        absent_guard = readme.index(
            "sudo test ! -e /home/ubuntu/shattab-pg18-stage/secrets/api_password",
            directory_verified,
        )
        secret_helper_command = readme.index("sudo python3 create_api_secret.py", absent_guard)
        self.assertLess(ownership_change, directory_verified)
        self.assertLess(directory_verified, absent_guard)
        self.assertLess(absent_guard, secret_helper_command)
        self.assertIn("مش هيعمل overwrite", readme)
        for expected in (
            "s.uid!==0",
            "uid===0",
            "process.geteuid()",
            "euid===0",
            "s.gid!==gid",
            "m!==0o440",
            "fs.constants.O_RDONLY",
            "fs.readSync",
            "fs.constants.O_WRONLY",
            "EACCES",
        ):
            self.assertIn(expected, readme)
        self.assertIn("rw=false", readme)
        self.assertIn("ما تستخدمش `down -v`", readme)

    def test_offline_tests_never_target_the_ignored_secret_directory(self) -> None:
        secret_tests = (STAGE / "test_api_secret.py").read_text(encoding="utf-8")
        stage_tests = Path(__file__).read_text(encoding="utf-8")
        helper = SECRET_HELPER.read_text(encoding="utf-8")
        tty_guard = helper.index("if not _has_controlling_tty():")
        target_assignment = helper.index(
            'target = Path(__file__).resolve().parent / "secrets" / "api_password"'
        )
        self.assertLess(tty_guard, target_assignment)
        self.assertIn("tempfile.TemporaryDirectory", secret_tests)
        self.assertIn("with tempfile.TemporaryDirectory", stage_tests)
        self.assertNotIn('STAGE / "secrets"', secret_tests)
        self.assertIn("test_unlink_failure_reports_possible_temp_file", secret_tests)
        self.assertIn("test_large_object_and_public_read_acl_fail_both_guards", (STAGE / "test_api_role_postgres18.py").read_text(encoding="utf-8"))

    def test_postgres_behavior_suite_owns_its_pinned_private_container(self) -> None:
        role_test = ROLE_TEST.read_text(encoding="utf-8")
        workflow = CI_WORKFLOW.read_text(encoding="utf-8")
        for expected in (
            "GITHUB_ACTIONS",
            '"GITHUB_JOB"',
            "api-stage-contracts",
            '"GITHUB_WORKFLOW_REF"',
            ".github/workflows/ci.yml",
            "EXPECTED_IMAGE_REF",
            "EXPECTED_IMAGE_DIGEST",
            "HARNESS_OWNER_LABEL",
            "HARNESS_TOKEN_LABEL",
            '"create"',
            '"start"',
            "--pull=always",
            '"--network"',
            '"none"',
            "test_wrong_job_or_workflow_context_refuses_before_any_docker_command",
            "test_non_18_6_server_binary_refuses_before_container_or_exec",
            "test_wrong_container_image_digest_running_state_or_health_refuses_before_exec",
            "test_invalid_prestart_identity_or_config_refuses_before_start_exec_or_sql",
            "test_non_created_prestart_state_never_starts_and_only_removes_verified_id",
            "test_successful_create_with_wrong_owner_token_or_name_stays_untouched",
            "test_create_timeout_late_appearance_is_verified_then_removed",
            "test_create_timeout_late_unowned_appearance_is_left_untouched",
            "test_create_timeout_still_ambiguous_reports_manual_inspection_without_removal",
            "test_start_timeout_removes_only_the_prevalidated_container_id",
            "test_start_timeout_with_changed_owner_token_leaves_container_untouched",
            "test_unexpected_public_database_privilege_fails_both_guards",
        ):
            self.assertIn(expected, role_test)
        self.assertIn("api-stage-contracts:", workflow)
        self.assertIn("test_api_role_postgres18.py", workflow)
        self.assertNotIn("POSTGRES_CONTAINER_ID", role_test)
        self.assertNotIn("POSTGRES_CONTAINER_ID", workflow)
        self.assertNotIn("job.services.postgres.id", workflow)

    def test_api_readme_labels_smoke_compose_stale_and_stage_local_only(self) -> None:
        readme = API_README.read_text(encoding="utf-8")
        self.assertIn("The old smoke Compose file remains stale.", readme)
        self.assertIn("local/planned staging configuration", readme)
        self.assertIn("has not been copied to Oracle, built, or run there", readme)
        self.assertNotIn("The Compose and Dockerfile files are intentionally unchanged", readme)


if __name__ == "__main__":
    unittest.main()
