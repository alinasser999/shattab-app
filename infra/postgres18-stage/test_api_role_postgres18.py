"""Disposable PostgreSQL 18 behavior checks with a self-owned CI container.

The integration suite refuses to run outside this repository's ``CI`` workflow
and the ``api-stage-contracts`` job. It never trusts an environment-selected
container ID: it creates a uniquely named PostgreSQL container from the exact
digest below, on Docker's ``none`` network, with no published ports or host bind
mounts. Runtime identity, image digest, and isolation are checked before
``docker start``. After health passes, a read-only query as the container's
``postgres`` superuser verifies the running PGDATA and server version before the
target is marked ready for fixture SQL. No mutating SQL runs until these checks
pass. If create times out, recovery inspects only the generated name and never
claims absence from a bounded retry. If start times out, recovery inspects and
removes only the previously validated full container ID.
"""

from __future__ import annotations

import copy
import json
import os
import re
import subprocess
import time
import unittest
import uuid
from pathlib import Path
from typing import Callable, Mapping


STAGE = Path(__file__).resolve().parent
PREFLIGHT = STAGE / "preflight_api_role.sql"
ROLE_SQL = STAGE / "create_api_role.sql"

EXPECTED_IMAGE_DIGEST = "sha256:bbf83594798e144bff365a9c191c5d779f181fb3135902064ab8ff11918020fc"
EXPECTED_IMAGE_REF = f"postgres:18.6-bookworm@{EXPECTED_IMAGE_DIGEST}"
EXPECTED_POSTGRES_VERSION = "18.6"
EXPECTED_DATA_DIRECTORY = "/var/lib/postgresql/18/docker"
EXPECTED_RUNTIME_IDENTITY = f"postgres|postgres|{EXPECTED_DATA_DIRECTORY}|180006"
RUNTIME_IDENTITY_QUERY = (
    "SELECT current_user, current_database(), current_setting('data_directory'), "
    "current_setting('server_version_num');"
)
EXPECTED_JOB = "api-stage-contracts"
EXPECTED_WORKFLOW = "CI"
EXPECTED_WORKFLOW_FILE = ".github/workflows/ci.yml"
HARNESS_OWNER_LABEL = "io.shattab.stage-harness.owner"
HARNESS_OWNER_VALUE = "postgres18-role-contract"
HARNESS_TOKEN_LABEL = "io.shattab.stage-harness.token"
CONTAINER_ID_PATTERN = re.compile(r"^[0-9a-f]{64}$")
IMAGE_ID_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")


class HarnessError(RuntimeError):
    """Sanitized refusal before any unverified database mutation."""


def require_expected_ci_context(environ: Mapping[str, str]) -> None:
    """Require the exact checked-in workflow and job before using Docker."""
    if environ.get("GITHUB_ACTIONS") != "true":
        raise HarnessError("the PostgreSQL behavior suite is restricted to GitHub Actions")
    if environ.get("RUNNER_OS") != "Linux":
        raise HarnessError("the PostgreSQL behavior suite requires the Linux CI runner")
    if environ.get("GITHUB_WORKFLOW") != EXPECTED_WORKFLOW:
        raise HarnessError("the PostgreSQL behavior suite requires the CI workflow")
    if environ.get("GITHUB_JOB") != EXPECTED_JOB:
        raise HarnessError("the PostgreSQL behavior suite requires the api-stage-contracts job")

    repository = environ.get("GITHUB_REPOSITORY", "")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise HarnessError("the GitHub repository context is missing or malformed")

    workflow_ref = environ.get("GITHUB_WORKFLOW_REF", "")
    expected_prefix = f"{repository}/{EXPECTED_WORKFLOW_FILE}@"
    if not workflow_ref.startswith(expected_prefix) or not workflow_ref[len(expected_prefix) :]:
        raise HarnessError("the PostgreSQL behavior suite requires this repository's checked-in CI workflow")

    for key in ("GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT"):
        if not environ.get(key, "").isdigit():
            raise HarnessError("the GitHub Actions run identity is missing or malformed")


class DisposablePostgres:
    """Start and own one isolated PostgreSQL container for the behavior suite."""

    def __init__(
        self,
        *,
        runner: Callable[..., subprocess.CompletedProcess[str]] | None = None,
        environ: Mapping[str, str] | None = None,
        sleeper: Callable[[float], None] | None = None,
        monotonic: Callable[[], float] | None = None,
    ) -> None:
        self.runner = runner or subprocess.run
        self.environ = dict(os.environ if environ is None else environ)
        self.sleeper = sleeper or time.sleep
        self.monotonic = monotonic or time.monotonic
        self.name: str | None = None
        self.harness_token: str | None = None
        self.container_id: str | None = None
        self.validated = False

    def _docker(
        self,
        arguments: list[str],
        *,
        input_text: str | None = None,
        timeout: int = 30,
    ) -> subprocess.CompletedProcess[str]:
        kwargs: dict[str, object] = {
            "stdout": subprocess.PIPE,
            "stderr": subprocess.PIPE,
            "text": True,
            "check": False,
            "timeout": timeout,
        }
        if input_text is None:
            kwargs["stdin"] = subprocess.DEVNULL
        else:
            kwargs["input"] = input_text
        try:
            return self.runner(["docker", *arguments], **kwargs)
        except (OSError, subprocess.TimeoutExpired):
            raise HarnessError("a Docker preflight command did not complete") from None

    def _probe_server_binary(self) -> None:
        # This read-only command checks the executable in the immutable image
        # before the database container is started or any docker exec is used.
        result = self._docker(
            [
                "run",
                "--rm",
                "--pull=always",
                "--network",
                "none",
                "--entrypoint",
                "postgres",
                EXPECTED_IMAGE_REF,
                "--version",
            ],
            timeout=180,
        )
        if result.returncode != 0 or not re.search(
            rf"(?m)^postgres \(PostgreSQL\) {re.escape(EXPECTED_POSTGRES_VERSION)}(?:\s|$)",
            result.stdout.strip(),
        ):
            raise HarnessError("the pinned image did not report PostgreSQL 18.6")

    def _inspect(self) -> dict[str, object]:
        assert self.container_id is not None
        result = self._docker(["container", "inspect", self.container_id])
        if result.returncode != 0:
            raise HarnessError("the test-owned container could not be inspected")
        try:
            payload = json.loads(result.stdout)
        except (TypeError, json.JSONDecodeError):
            raise HarnessError("the test-owned container inspection was malformed") from None
        if not isinstance(payload, list) or len(payload) != 1 or not isinstance(payload[0], dict):
            raise HarnessError("the test-owned container inspection was ambiguous")
        return payload[0]

    def _inspect_recovery_id(self) -> dict[str, object] | None:
        """Inspect the ID validated before start; return None only if it is gone."""
        if self.container_id is None:
            raise HarnessError("no validated container ID is available for start recovery")
        result = self._docker(["container", "inspect", self.container_id])
        if result.returncode != 0:
            detail = f"{result.stdout}\n{result.stderr}"
            confirmed_absence = (
                self.container_id in detail
                and re.search(r"(?i)no such (?:object|container)|not found", detail) is not None
            )
            if confirmed_absence:
                return None
            raise HarnessError("the prevalidated container ID could not be safely inspected")
        try:
            payload = json.loads(result.stdout)
        except (TypeError, json.JSONDecodeError):
            raise HarnessError("the prevalidated container inspection was malformed") from None
        if not isinstance(payload, list) or len(payload) != 1 or not isinstance(payload[0], dict):
            raise HarnessError("the prevalidated container inspection was ambiguous")
        return payload[0]

    def _inspect_generated_name(self) -> dict[str, object] | None:
        """Inspect only this attempt's generated name; return None only on confirmed absence."""
        if self.name is None:
            raise HarnessError("no generated container name is available for safe inspection")
        result = self._docker(["container", "inspect", self.name])
        if result.returncode != 0:
            detail = f"{result.stdout}\n{result.stderr}"
            confirmed_absence = (
                self.name in detail
                and re.search(r"(?i)no such (?:object|container)|not found", detail) is not None
            )
            if confirmed_absence:
                return None
            raise HarnessError("the generated container name could not be safely inspected")
        try:
            payload = json.loads(result.stdout)
        except (TypeError, json.JSONDecodeError):
            raise HarnessError("the generated-name inspection was malformed") from None
        if not isinstance(payload, list) or len(payload) != 1 or not isinstance(payload[0], dict):
            raise HarnessError("the generated-name inspection was ambiguous")
        return payload[0]

    def _verify_image_digest(self, image_id: str) -> None:
        result = self._docker(
            ["image", "inspect", "--format", "{{.Id}}", EXPECTED_IMAGE_REF]
        )
        if result.returncode != 0:
            raise HarnessError("the pinned PostgreSQL image reference could not be inspected")
        if result.stdout.strip() != image_id:
            raise HarnessError("the resolved PostgreSQL image ID does not match the pinned digest reference")

    def _verify_container_identity(
        self,
        container: dict[str, object],
        *,
        expected_id: str | None = None,
    ) -> str:
        assert self.name is not None
        assert self.harness_token is not None
        config = container.get("Config")
        state = container.get("State")
        host = container.get("HostConfig")
        networking = container.get("NetworkSettings")
        if not all(isinstance(value, dict) for value in (config, state, host, networking)):
            raise HarnessError("the test-owned container inspection omitted required identity fields")

        container_id = container.get("Id")
        if not isinstance(container_id, str) or not CONTAINER_ID_PATTERN.fullmatch(container_id):
            raise HarnessError("the generated container ID is malformed")
        if expected_id is not None and container_id != expected_id:
            raise HarnessError("the generated name no longer resolves to the test-owned container ID")
        if container.get("Name") != f"/{self.name}":
            raise HarnessError("the inspected container name does not match the generated unique name")
        if config.get("Image") != EXPECTED_IMAGE_REF:
            raise HarnessError("the test-owned container image reference does not match the pinned PostgreSQL image")
        labels = config.get("Labels")
        if not isinstance(labels, dict):
            raise HarnessError("the test-owned container has no harness ownership labels")
        if (
            labels.get(HARNESS_OWNER_LABEL) != HARNESS_OWNER_VALUE
            or labels.get(HARNESS_TOKEN_LABEL) != self.harness_token
        ):
            raise HarnessError("the inspected container does not carry this harness attempt's ownership token")
        image_id = container.get("Image")
        if not isinstance(image_id, str) or not IMAGE_ID_PATTERN.fullmatch(image_id):
            raise HarnessError("the resolved PostgreSQL image identity is malformed")
        if host.get("NetworkMode") != "none":
            raise HarnessError("the test-owned PostgreSQL container is not isolated from networks")
        if host.get("PortBindings") not in (None, {}):
            raise HarnessError("the test-owned PostgreSQL container has host port bindings")
        ports = networking.get("Ports") or {}
        if not isinstance(ports, dict) or any(value for value in ports.values()):
            raise HarnessError("the test-owned PostgreSQL container exposes a host port")
        networks = networking.get("Networks") or {}
        if not isinstance(networks, dict) or not set(networks).issubset({"none"}):
            raise HarnessError("the test-owned PostgreSQL container joined an unexpected network")
        mounts = container.get("Mounts") or []
        if not isinstance(mounts, list) or any(
            not isinstance(mount, dict) or mount.get("Type") == "bind" for mount in mounts
        ):
            raise HarnessError("the test-owned PostgreSQL container has an unexpected host bind mount")

        self._verify_image_digest(image_id)
        return container_id

    def _wait_until_healthy(self) -> None:
        deadline = self.monotonic() + 120
        while True:
            container = self._inspect()
            self._verify_container_identity(container, expected_id=self.container_id)
            state = container["State"]
            assert isinstance(state, dict)
            if state.get("Running") is not True or state.get("Status") != "running":
                raise HarnessError("the test-owned PostgreSQL container is not running")
            health = state.get("Health")
            if not isinstance(health, dict):
                raise HarnessError("the test-owned PostgreSQL container has no health status")
            status = health.get("Status")
            if status == "healthy":
                return
            if status != "starting":
                raise HarnessError("the test-owned PostgreSQL container is not healthy")
            if self.monotonic() >= deadline:
                raise HarnessError("the test-owned PostgreSQL container did not become healthy in time")
            self.sleeper(1)

    def _verify_runtime_data_directory(self) -> None:
        """Read PGDATA as the container superuser after health, before fixture SQL."""
        assert self.container_id is not None
        result = self._docker(
            [
                "exec",
                self.container_id,
                "psql",
                "-X",
                "-A",
                "-t",
                "-F",
                "|",
                "-v",
                "ON_ERROR_STOP=1",
                "-U",
                "postgres",
                "-d",
                "postgres",
                "-c",
                RUNTIME_IDENTITY_QUERY,
            ],
            timeout=30,
        )
        if result.returncode != 0 or result.stdout.strip() != EXPECTED_RUNTIME_IDENTITY:
            raise HarnessError(
                "the running PostgreSQL data directory or version does not match the disposable target"
            )

    def start(self) -> "DisposablePostgres":
        # Context is checked before any Docker command; the container ID cannot
        # come from an environment variable or be reused from a local stage.
        require_expected_ci_context(self.environ)
        self._probe_server_binary()

        self.name = f"shattab-pg18-contract-{uuid.uuid4().hex}"
        self.harness_token = uuid.uuid4().hex
        create_arguments = [
            "create",
            "--rm",
            "--pull=always",
            "--name",
            self.name,
            "--label",
            f"{HARNESS_OWNER_LABEL}={HARNESS_OWNER_VALUE}",
            "--label",
            f"{HARNESS_TOKEN_LABEL}={self.harness_token}",
            "--network",
            "none",
            "--cpus",
            "1",
            "--memory",
            "1g",
            "--pids-limit",
            "128",
            "--tmpfs",
            "/var/lib/postgresql:rw,noexec,nosuid,nodev,size=768m",
            "--env",
            "POSTGRES_USER=postgres",
            "--env",
            "POSTGRES_DB=postgres",
            "--env",
            "POSTGRES_HOST_AUTH_METHOD=trust",
            "--env",
            "PGDATA=/var/lib/postgresql/18/docker",
            "--health-cmd",
            "pg_isready -U postgres -d postgres",
            "--health-interval",
            "2s",
            "--health-timeout",
            "3s",
            "--health-retries",
            "30",
            EXPECTED_IMAGE_REF,
        ]
        try:
            result = self._docker(create_arguments, timeout=180)
        except HarnessError:
            self._raise_after_ambiguous_create()
        if result.returncode != 0:
            self._raise_after_ambiguous_create()

        container_id = result.stdout.strip()
        if not CONTAINER_ID_PATTERN.fullmatch(container_id):
            self._raise_after_ambiguous_create()
        self.container_id = container_id

        try:
            created = self._inspect()
            self._verify_container_identity(created, expected_id=self.container_id)
            created_state = created.get("State")
            if (
                not isinstance(created_state, dict)
                or created_state.get("Running") is not False
                or created_state.get("Status") != "created"
            ):
                raise HarnessError("the newly created PostgreSQL container is not in the created state")
        except HarnessError:
            self._raise_after_cleanup("the created PostgreSQL container failed its identity or isolation checks")

        try:
            # Docker starts containers detached by default; `docker start` has
            # no `--detach` option. Start only the ID verified above.
            started = self._docker(["start", self.container_id], timeout=180)
        except HarnessError:
            self._raise_after_start_failure()
        if started.returncode != 0:
            self._raise_after_start_failure()

        try:
            self._wait_until_healthy()
            self._verify_runtime_data_directory()
        except HarnessError:
            self._raise_after_cleanup(
                "the test-owned PostgreSQL container failed identity, health, or runtime PGDATA checks"
            )
        self.validated = True
        return self

    def _raise_after_cleanup(self, message: str) -> None:
        try:
            self.cleanup()
        except HarnessError:
            raise HarnessError(
                "preflight failed; the generated disposable container may remain and needs manual inspection"
            ) from None
        raise HarnessError(message)

    def _remove_verified_container(
        self,
        container: dict[str, object],
        *,
        expected_id: str | None = None,
    ) -> None:
        try:
            container_id = self._verify_container_identity(container, expected_id=expected_id)
        except HarnessError:
            raise HarnessError(
                "the generated-name container failed ownership or isolation checks; it was left untouched for manual inspection"
            ) from None
        result = self._docker(["rm", "--force", container_id], timeout=30)
        if result.returncode != 0:
            raise HarnessError(
                "the verified disposable PostgreSQL container may remain; inspect only its generated name"
            )
        self.validated = False
        self.container_id = None
        self.harness_token = None
        self.name = None

    def _recover_ambiguous_create(self) -> bool:
        """Find a late-created object by name; otherwise preserve the ambiguity for manual review."""
        # A short exact-name retry window avoids reporting absence while the
        # daemon is still completing an accepted create request. Absence after
        # the bounded window is still ambiguous, so it is never reported clean.
        for attempt in range(5):
            container = self._inspect_generated_name()
            if container is not None:
                self._remove_verified_container(container)
                return True
            if attempt < 4:
                self.sleeper(0.25)
        raise HarnessError("the container create result remains ambiguous after repeated generated-name inspections")

    def _raise_after_ambiguous_create(self) -> None:
        try:
            removed = self._recover_ambiguous_create()
        except HarnessError:
            raise HarnessError(
                "container creation failed ambiguously; no unverified object was removed; inspect only the generated name manually"
            ) from None
        if removed:
            raise HarnessError(
                "container creation failed after creating the verified harness object; only that object was removed"
            )
        raise AssertionError("ambiguous-create recovery must either remove or raise for manual inspection")

    def _recover_failed_start(self) -> bool:
        container = self._inspect_recovery_id()
        if container is None:
            self.validated = False
            self.container_id = None
            self.harness_token = None
            self.name = None
            return False
        self._remove_verified_container(container, expected_id=self.container_id)
        return True

    def _raise_after_start_failure(self) -> None:
        try:
            removed = self._recover_failed_start()
        except HarnessError:
            raise HarnessError(
                "container start failed ambiguously; the previously validated ID could not be reverified, and no unverified object was removed; inspect that ID manually"
            ) from None
        if removed:
            raise HarnessError(
                "container start failed after the validated object was created; only that verified container ID was removed"
            )
        raise HarnessError(
            "container start failed; the previously validated container ID no longer exists"
        )

    def cleanup(self) -> None:
        if self.name is None:
            return
        container = self._inspect_generated_name()
        if container is None:
            self.validated = False
            self.container_id = None
            self.harness_token = None
            self.name = None
            return
        self._remove_verified_container(container, expected_id=self.container_id)

    def psql(
        self,
        database: str,
        *,
        user: str,
        sql: str | None = None,
        file: Path | None = None,
    ) -> subprocess.CompletedProcess[str]:
        if not self.validated or self.container_id is None or not CONTAINER_ID_PATTERN.fullmatch(self.container_id):
            raise HarnessError("PostgreSQL SQL is blocked until the disposable target passes preflight")
        if (sql is None) == (file is None):
            raise ValueError("supply exactly one of SQL text or a SQL file")
        input_text = sql if sql is not None else file.read_text(encoding="utf-8")
        return self._docker(
            [
                "exec",
                "-i",
                self.container_id,
                "psql",
                "-X",
                "-A",
                "-t",
                "-v",
                "ON_ERROR_STOP=1",
                "-U",
                user,
                "-d",
                database,
                "-f",
                "-",
            ],
            input_text=input_text,
            timeout=30,
        )


def assert_ok(test: unittest.TestCase, result: subprocess.CompletedProcess[str]) -> str:
    test.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    return result.stdout + result.stderr


def assert_guard_failure(test: unittest.TestCase, result: subprocess.CompletedProcess[str]) -> str:
    output = result.stdout + result.stderr
    test.assertNotEqual(result.returncode, 0, output)
    test.assertIn("FAIL:", output, output)
    return output


def expected_ci_environment() -> dict[str, str]:
    return {
        "GITHUB_ACTIONS": "true",
        "RUNNER_OS": "Linux",
        "GITHUB_WORKFLOW": "CI",
        "GITHUB_JOB": "api-stage-contracts",
        "GITHUB_REPOSITORY": "example/shattab",
        "GITHUB_WORKFLOW_REF": "example/shattab/.github/workflows/ci.yml@refs/heads/main",
        "GITHUB_RUN_ID": "12345",
        "GITHUB_RUN_ATTEMPT": "1",
    }


class FakeDockerRunner:
    """A strict Docker CLI double; it never starts a real process/container."""

    container_id = "a" * 64
    image_id = "sha256:" + "b" * 64

    def __init__(
        self,
        *,
        version_output: str = "postgres (PostgreSQL) 18.6 (Debian test)\n",
        image_ref: str = EXPECTED_IMAGE_REF,
        resolved_image_id: str | None = None,
        running: bool = True,
        health: str = "healthy",
        created_status: str = "created",
        created_running: bool = False,
        inspected_id: str | None = None,
        run_id: str | None = None,
        create_timeout: str | None = None,
        late_appearance_after_inspections: int | None = None,
        start_timeout: str | None = None,
        recovery_container_present: bool = True,
        label_owner_override: str | None = None,
        label_token_override: str | None = None,
        label_token_override_after_start: str | None = None,
        inspected_name_override: str | None = None,
        network_mode: str = "none",
        port_bindings: object = None,
        network_ports: object | None = None,
        mounts: list[dict[str, object]] | None = None,
        runtime_identity_output: str = EXPECTED_RUNTIME_IDENTITY + "\n",
    ) -> None:
        self.version_output = version_output
        self.image_ref = image_ref
        self.resolved_image_id = resolved_image_id or self.image_id
        self.running = running
        self.health = health
        self.created_status = created_status
        self.created_running = created_running
        self.inspected_id = inspected_id or self.container_id
        self.run_id = run_id or self.container_id
        self.create_timeout = create_timeout
        self.late_appearance_after_inspections = late_appearance_after_inspections
        self.start_timeout = start_timeout
        self.recovery_container_present = recovery_container_present
        self.label_owner_override = label_owner_override
        self.label_token_override = label_token_override
        self.label_token_override_after_start = label_token_override_after_start
        self.inspected_name_override = inspected_name_override
        self.network_mode = network_mode
        self.port_bindings = port_bindings
        self.network_ports = network_ports
        self.mounts = mounts
        self.runtime_identity_output = runtime_identity_output
        self.commands: list[list[str]] = []
        self.generated_name: str | None = None
        self.harness_token: str | None = None
        self.name_inspections = 0
        self.started = False
        self.remove_targets: list[str] = []

    def __call__(self, command: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
        self.commands.append(command)
        arguments = command[1:]
        if arguments[:1] == ["run"] and "--entrypoint" in arguments:
            return subprocess.CompletedProcess(command, 0, self.version_output, "")
        if arguments[:1] == ["create"]:
            name_index = arguments.index("--name") + 1
            self.generated_name = arguments[name_index]
            labels = [
                arguments[index + 1]
                for index, argument in enumerate(arguments[:-1])
                if argument == "--label"
            ]
            label_values = dict(label.split("=", 1) for label in labels)
            self.harness_token = label_values[HARNESS_TOKEN_LABEL]
            if self.label_token_override is not None:
                self.harness_token = self.label_token_override
            if self.create_timeout is not None:
                self.recovery_container_present = False
                if self.create_timeout == "after_create":
                    self.recovery_container_present = True
                raise subprocess.TimeoutExpired(command, timeout=180)
            self.recovery_container_present = True
            return subprocess.CompletedProcess(command, 0, self.run_id + "\n", "")
        if arguments[:1] == ["start"]:
            if self.start_timeout is not None:
                if self.start_timeout == "after_start":
                    self.started = True
                    if self.label_token_override_after_start is not None:
                        self.harness_token = self.label_token_override_after_start
                raise subprocess.TimeoutExpired(command, timeout=180)
            self.started = True
            return subprocess.CompletedProcess(command, 0, self.run_id + "\n", "")
        if arguments[:2] == ["container", "inspect"]:
            inspected_target = arguments[2]
            if inspected_target == self.generated_name:
                self.name_inspections += 1
                if (
                    not self.recovery_container_present
                    and self.late_appearance_after_inspections is not None
                    and self.name_inspections > self.late_appearance_after_inspections
                ):
                    self.recovery_container_present = True
            if not self.recovery_container_present:
                return subprocess.CompletedProcess(
                    command,
                    1,
                    "",
                    f"Error: No such object: {inspected_target}\n",
                )
            result = {
                "Id": self.inspected_id,
                "Name": (
                    self.inspected_name_override
                    if self.inspected_name_override is not None
                    else f"/{self.generated_name}"
                ),
                "Config": {
                    "Image": self.image_ref,
                    "Labels": {
                        HARNESS_OWNER_LABEL: (
                            self.label_owner_override
                            if self.label_owner_override is not None
                            else HARNESS_OWNER_VALUE
                        ),
                        HARNESS_TOKEN_LABEL: self.harness_token,
                    },
                },
                "Image": self.image_id,
                "State": {
                    "Running": (
                        self.started and self.running
                        if self.started
                        else self.created_running
                    ),
                    "Status": (
                        self.created_status
                        if not self.started
                        else "running" if self.running else "exited"
                    ),
                    "Health": {"Status": self.health if self.started else "starting"},
                },
                "HostConfig": {
                    "NetworkMode": self.network_mode,
                    "PortBindings": self.port_bindings,
                },
                "NetworkSettings": {
                    "Ports": (
                        self.network_ports
                        if self.network_ports is not None
                        else {"5432/tcp": None}
                    ),
                    "Networks": {self.network_mode: {}},
                },
                "Mounts": (
                    self.mounts
                    if self.mounts is not None
                    else [{"Type": "tmpfs", "Destination": "/var/lib/postgresql"}]
                ),
            }
            return subprocess.CompletedProcess(command, 0, json.dumps([result]), "")
        if arguments[:2] == ["image", "inspect"]:
            return subprocess.CompletedProcess(command, 0, self.resolved_image_id + "\n", "")
        if arguments[:2] == ["rm", "--force"]:
            target = arguments[2]
            self.remove_targets.append(target)
            self.recovery_container_present = False
            return subprocess.CompletedProcess(command, 0, target, "")
        if arguments[:1] == ["exec"]:
            return subprocess.CompletedProcess(command, 0, self.runtime_identity_output, "")
        raise AssertionError(f"unexpected mocked Docker command: {command!r}")


class DockerTargetSafetyTests(unittest.TestCase):
    def _target(self, fake: FakeDockerRunner, environ: Mapping[str, str] | None = None) -> DisposablePostgres:
        return DisposablePostgres(
            runner=fake,
            environ=expected_ci_environment() if environ is None else environ,
            sleeper=lambda _seconds: None,
            monotonic=lambda: 0.0,
        )

    @staticmethod
    def _assert_no_exec(test: unittest.TestCase, fake: FakeDockerRunner) -> None:
        test.assertFalse(any(command[1:2] == ["exec"] for command in fake.commands), fake.commands)

    def test_default_non_ci_context_refuses_before_any_docker_command(self) -> None:
        fake = FakeDockerRunner()
        target = self._target(fake, {})
        with self.assertRaises(HarnessError):
            target.start()
        self.assertEqual(fake.commands, [])

    def test_wrong_job_or_workflow_context_refuses_before_any_docker_command(self) -> None:
        for key, value in (
            ("GITHUB_JOB", "another-job"),
            ("GITHUB_WORKFLOW", "another-workflow"),
            ("GITHUB_WORKFLOW_REF", "example/shattab/.github/workflows/other.yml@refs/heads/main"),
        ):
            with self.subTest(key=key):
                environment = expected_ci_environment()
                environment[key] = value
                fake = FakeDockerRunner()
                with self.assertRaises(HarnessError):
                    self._target(fake, environment).start()
                self.assertEqual(fake.commands, [])

    def test_non_18_6_server_binary_refuses_before_container_or_exec(self) -> None:
        fake = FakeDockerRunner(version_output="postgres (PostgreSQL) 17.11\n")
        with self.assertRaises(HarnessError):
            self._target(fake).start()
        self.assertEqual(len(fake.commands), 1)
        version_command = fake.commands[0]
        self.assertIn("--network", version_command)
        self.assertIn("none", version_command)
        self.assertIn(EXPECTED_IMAGE_REF, version_command)
        self._assert_no_exec(self, fake)

    def test_invalid_docker_create_id_refuses_before_start_or_exec(self) -> None:
        fake = FakeDockerRunner(run_id="abc;docker rm -f unrelated")
        with self.assertRaises(HarnessError):
            self._target(fake).start()
        self.assertTrue(any(command[1:2] == ["create"] for command in fake.commands))
        self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))
        self.assertEqual(fake.remove_targets, [fake.container_id])
        self._assert_no_exec(self, fake)

    def test_wrong_container_image_digest_running_state_or_health_refuses_before_exec(self) -> None:
        cases = (
            ({"image_ref": "postgres:18.6-bookworm@sha256:" + "f" * 64}, False),
            ({"resolved_image_id": "sha256:" + "f" * 64}, False),
            ({"running": False}, True),
            ({"health": "unhealthy"}, True),
            ({"inspected_id": "c" * 64}, False),
        )
        for options, safe_to_remove in cases:
            with self.subTest(options=options):
                fake = FakeDockerRunner(**options)
                with self.assertRaises(HarnessError):
                    self._target(fake).start()
                self._assert_no_exec(self, fake)
                self.assertEqual(
                    fake.remove_targets,
                    [fake.container_id] if safe_to_remove else [],
                )
                if not safe_to_remove:
                    self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))

    def test_invalid_prestart_identity_or_config_refuses_before_start_exec_or_sql(self) -> None:
        cases = (
            {"image_ref": "postgres:18.6-bookworm@sha256:" + "f" * 64},
            {"resolved_image_id": "sha256:" + "f" * 64},
            {"inspected_id": "c" * 64},
            {"inspected_id": "not-a-container-id"},
            {"network_mode": "bridge"},
            {"port_bindings": {"5432/tcp": [{"HostPort": "5432"}]}},
            {"network_ports": {"5432/tcp": [{"HostPort": "5432"}]}},
            {"mounts": [{"Type": "bind", "Source": "C:/unrelated", "Destination": "/data"}]},
        )
        for options in cases:
            with self.subTest(options=options):
                fake = FakeDockerRunner(**options)
                target = self._target(fake)
                with self.assertRaises(HarnessError):
                    target.start()

                self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))
                self._assert_no_exec(self, fake)
                self.assertFalse(target.validated)
                with self.assertRaisesRegex(HarnessError, "blocked until the disposable target passes preflight"):
                    target.psql("postgres", user="postgres", sql="SELECT 1")
                self.assertEqual(fake.remove_targets, [])

    def test_non_created_prestart_state_never_starts_and_only_removes_verified_id(self) -> None:
        for options in (
            {"created_status": "exited"},
            {"created_status": "running", "created_running": True},
        ):
            with self.subTest(options=options):
                fake = FakeDockerRunner(**options)
                target = self._target(fake)
                with self.assertRaises(HarnessError):
                    target.start()

                self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))
                self._assert_no_exec(self, fake)
                with self.assertRaisesRegex(HarnessError, "blocked until the disposable target passes preflight"):
                    target.psql("postgres", user="postgres", sql="SELECT 1")
                self.assertEqual(fake.remove_targets, [fake.container_id])

    def test_successful_create_with_wrong_owner_token_or_name_stays_untouched(self) -> None:
        cases = (
            {"label_owner_override": "not-this-harness"},
            {"label_token_override": "not-this-attempt"},
            {"inspected_name_override": "/another-generated-container"},
        )
        for options in cases:
            with self.subTest(options=options):
                fake = FakeDockerRunner(**options)
                target = self._target(fake)
                with self.assertRaises(HarnessError):
                    target.start()

                self.assertTrue(any(command[1:2] == ["create"] for command in fake.commands))
                self.assertEqual(target.container_id, fake.container_id)
                self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))
                self._assert_no_exec(self, fake)
                self.assertFalse(target.validated)
                self.assertEqual(fake.remove_targets, [])
                self.assertTrue(fake.recovery_container_present)
                with self.assertRaisesRegex(HarnessError, "blocked until the disposable target passes preflight"):
                    target.psql("postgres", user="postgres", sql="SELECT 1")

    def test_create_timeout_late_appearance_is_verified_then_removed(self) -> None:
        fake = FakeDockerRunner(
            create_timeout="late_appearance",
            late_appearance_after_inspections=1,
        )
        with self.assertRaisesRegex(HarnessError, "only that object was removed"):
            self._target(fake).start()

        inspect_by_name = [
            command
            for command in fake.commands
            if command[1:3] == ["container", "inspect"]
            and command[3] == fake.generated_name
        ]
        self.assertEqual(len(inspect_by_name), 2)
        self.assertTrue(all(command[3] == fake.generated_name for command in inspect_by_name))
        self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))
        self.assertEqual(fake.remove_targets, [fake.container_id])
        self._assert_no_exec(self, fake)

    def test_create_timeout_late_unowned_appearance_is_left_untouched(self) -> None:
        fake = FakeDockerRunner(
            create_timeout="late_appearance",
            late_appearance_after_inspections=1,
            label_token_override="not-this-attempt",
        )
        target = self._target(fake)
        with self.assertRaisesRegex(HarnessError, "no unverified object was removed"):
            target.start()

        self.assertEqual(fake.name_inspections, 2)
        self.assertEqual(fake.remove_targets, [])
        self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))
        self._assert_no_exec(self, fake)
        with self.assertRaisesRegex(HarnessError, "blocked until the disposable target passes preflight"):
            target.psql("postgres", user="postgres", sql="SELECT 1")

    def test_create_timeout_still_ambiguous_reports_manual_inspection_without_removal(self) -> None:
        fake = FakeDockerRunner(
            create_timeout="before_create",
            recovery_container_present=False,
        )
        with self.assertRaisesRegex(HarnessError, "inspect only the generated name manually") as raised:
            self._target(fake).start()

        self.assertNotIn("no container exists", str(raised.exception).lower())
        self.assertEqual(fake.name_inspections, 5)
        self.assertEqual(fake.remove_targets, [])
        self.assertFalse(any(command[1:2] == ["start"] for command in fake.commands))
        self._assert_no_exec(self, fake)

    def test_start_timeout_removes_only_the_prevalidated_container_id(self) -> None:
        for timeout_stage in ("before_start", "after_start"):
            with self.subTest(timeout_stage=timeout_stage):
                fake = FakeDockerRunner(start_timeout=timeout_stage)
                with self.assertRaisesRegex(HarnessError, "only that verified container ID was removed"):
                    self._target(fake).start()

                self.assertTrue(any(command[1:2] == ["create"] for command in fake.commands))
                self.assertTrue(any(command[1:2] == ["start"] for command in fake.commands))
                self.assertTrue(
                    any(
                        command[1:3] == ["container", "inspect"]
                        and command[3] == fake.container_id
                        for command in fake.commands
                    )
                )
                self.assertEqual(fake.remove_targets, [fake.container_id])
                self._assert_no_exec(self, fake)

    def test_start_timeout_with_changed_owner_token_leaves_container_untouched(self) -> None:
        fake = FakeDockerRunner(
            start_timeout="after_start",
            label_token_override_after_start="not-this-attempt",
        )
        with self.assertRaisesRegex(HarnessError, "no unverified object was removed"):
            self._target(fake).start()

        self.assertEqual(fake.remove_targets, [])
        self._assert_no_exec(self, fake)

    def test_wrong_runtime_data_directory_blocks_fixture_sql_and_removes_only_owned_target(self) -> None:
        fake = FakeDockerRunner(
            runtime_identity_output="postgres|postgres|/var/lib/postgresql/data|180006\n"
        )
        target = self._target(fake)
        with self.assertRaisesRegex(HarnessError, "runtime PGDATA checks"):
            target.start()

        exec_commands = [command for command in fake.commands if command[1:2] == ["exec"]]
        self.assertEqual(len(exec_commands), 1)
        command = exec_commands[0]
        self.assertEqual(command[2], fake.container_id)
        self.assertEqual(command[command.index("-U") + 1], "postgres")
        self.assertEqual(command[command.index("-d") + 1], "postgres")
        self.assertEqual(command[command.index("-c") + 1], RUNTIME_IDENTITY_QUERY)
        self.assertEqual(fake.remove_targets, [fake.container_id])
        self.assertFalse(target.validated)
        with self.assertRaisesRegex(HarnessError, "blocked until the disposable target passes preflight"):
            target.psql("postgres", user="postgres", sql="SELECT 1")
        self.assertEqual(
            [command for command in fake.commands if command[1:2] == ["exec"]],
            exec_commands,
        )

    def test_pinned_private_target_checks_runtime_pgdata_before_ready_and_owns_cleanup(self) -> None:
        fake = FakeDockerRunner()
        target = self._target(fake).start()
        self.assertTrue(target.validated)
        self.assertRegex(target.name or "", r"^shattab-pg18-contract-[0-9a-f]{32}$")
        self.assertEqual(target.container_id, fake.container_id)
        create_command = next(command for command in fake.commands if command[1:2] == ["create"] and "--name" in command)
        self.assertIn("--network", create_command)
        self.assertIn("none", create_command)
        self.assertNotIn("--publish", create_command)
        self.assertNotIn("-p", create_command)
        self.assertIn(f"{HARNESS_OWNER_LABEL}={HARNESS_OWNER_VALUE}", create_command)
        self.assertIn(EXPECTED_IMAGE_REF, create_command)
        start_commands = [command for command in fake.commands if command[1:2] == ["start"]]
        self.assertEqual(start_commands, [["docker", "start", fake.container_id]])
        start_index = fake.commands.index(start_commands[0])
        self.assertTrue(
            any(
                index < start_index
                and command[1:3] == ["container", "inspect"]
                and command[3] == fake.container_id
                for index, command in enumerate(fake.commands)
            ),
            fake.commands,
        )
        self.assertTrue(
            any(
                index < start_index and command[1:3] == ["image", "inspect"]
                for index, command in enumerate(fake.commands)
            ),
            fake.commands,
        )
        exec_commands = [command for command in fake.commands if command[1:2] == ["exec"]]
        self.assertEqual(len(exec_commands), 1)
        runtime_check = exec_commands[0]
        self.assertEqual(runtime_check[2], fake.container_id)
        self.assertEqual(runtime_check[runtime_check.index("-U") + 1], "postgres")
        self.assertEqual(runtime_check[runtime_check.index("-d") + 1], "postgres")
        self.assertEqual(runtime_check[runtime_check.index("-c") + 1], RUNTIME_IDENTITY_QUERY)
        self.assertEqual(fake.commands.index(runtime_check), len(fake.commands) - 1)
        target.cleanup()
        cleanup = fake.commands[-1]
        self.assertEqual(cleanup[1:3], ["rm", "--force"])
        self.assertEqual(cleanup[3], fake.container_id)


class Postgres18StageRoleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if os.environ.get("GITHUB_ACTIONS") != "true":
            raise unittest.SkipTest("the live PostgreSQL behavior suite is restricted to api-stage-contracts CI")

        cls.target = DisposablePostgres()
        cls.target.start()
        try:
            result = cls.target.psql(
                "postgres",
                user="postgres",
                sql="CREATE ROLE shattab_stage_admin LOGIN CREATEROLE;",
            )
            if result.returncode != 0:
                raise RuntimeError("could not initialize the disposable PostgreSQL role")
        except Exception:
            cls.target.cleanup()
            raise

    @classmethod
    def tearDownClass(cls) -> None:
        target = getattr(cls, "target", None)
        if target is not None:
            target.cleanup()

    def control(self, sql: str) -> subprocess.CompletedProcess[str]:
        """Run cluster-wide setup or role-catalog queries on the maintenance DB."""
        return self.target.psql("postgres", user="postgres", sql=sql)

    def stage_control(self, sql: str) -> subprocess.CompletedProcess[str]:
        """Run database-local fixture SQL as the stage database owner."""
        return self.target.psql("shattab_stage", user="shattab_stage_admin", sql=sql)

    def setUp(self) -> None:
        assert_ok(self, self.control("DROP DATABASE IF EXISTS shattab_stage WITH (FORCE);"))
        assert_ok(self, self.control("DROP ROLE IF EXISTS shattab_api;"))
        assert_ok(self, self.control("CREATE DATABASE shattab_stage OWNER shattab_stage_admin;"))

    def run_preflight(self, database: str = "shattab_stage") -> subprocess.CompletedProcess[str]:
        return self.target.psql(database, user="shattab_stage_admin", file=PREFLIGHT)

    def run_role_creation(self, database: str = "shattab_stage") -> subprocess.CompletedProcess[str]:
        return self.target.psql(database, user="shattab_stage_admin", file=ROLE_SQL)

    def assert_api_role_absent(self) -> None:
        role_count = self.control("SELECT count(*) FROM pg_roles WHERE rolname = 'shattab_api';")
        self.assertEqual(assert_ok(self, role_count).strip(), "0")

    def test_stock_postgresql18_defaults_pass_without_acl_changes(self) -> None:
        output = assert_ok(self, self.run_preflight())
        self.assertIn("public schema USAGE= 1", output)
        self.assertIn("database CONNECT= 1", output)
        self.assertIn("database TEMPORARY= 1", output)
        self.assertIn("explicit default ACLs= 0", output)
        self.assertIn("future function EXECUTE defaults= 1", output)
        self.assertIn("PASS: stock PostgreSQL 18 defaults", output)

    def test_wrong_database_fails_both_guards(self) -> None:
        assert_guard_failure(self, self.run_preflight(database="postgres"))
        assert_guard_failure(self, self.run_role_creation(database="postgres"))
        self.assert_api_role_absent()

    def test_existing_api_role_fails_without_modifying_it(self) -> None:
        assert_ok(self, self.control("CREATE ROLE shattab_api NOLOGIN;"))
        assert_guard_failure(self, self.run_preflight())
        assert_guard_failure(self, self.run_role_creation())
        result = self.control("SELECT rolcanlogin FROM pg_roles WHERE rolname = 'shattab_api';")
        self.assertEqual(assert_ok(self, result).strip(), "f")

    def test_nonempty_application_object_fails_both_guards(self) -> None:
        assert_ok(self, self.stage_control("CREATE TABLE public.contract_probe (id integer);"))
        assert_guard_failure(self, self.run_preflight())
        assert_guard_failure(self, self.run_role_creation())
        self.assert_api_role_absent()

    def test_unexpected_public_and_default_acl_fail_both_guards(self) -> None:
        assert_ok(self, self.stage_control("GRANT CREATE ON SCHEMA public TO PUBLIC;"))
        assert_guard_failure(self, self.run_preflight())
        assert_guard_failure(self, self.run_role_creation())
        self.assert_api_role_absent()

        assert_ok(self, self.stage_control("REVOKE CREATE ON SCHEMA public FROM PUBLIC;"))
        assert_ok(self, self.run_preflight())

        # A schema-specific default ACL would silently apply to future tables.
        assert_ok(
            self,
            self.stage_control("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO PUBLIC;"),
        )
        assert_guard_failure(self, self.run_preflight())
        assert_guard_failure(self, self.run_role_creation())
        self.assert_api_role_absent()

    def test_unexpected_public_database_privilege_fails_both_guards(self) -> None:
        # CREATE is not part of the stock PostgreSQL 18 database PUBLIC baseline.
        # The grant exists only in this test-owned disposable database/container.
        assert_ok(self, self.stage_control("GRANT CREATE ON DATABASE shattab_stage TO PUBLIC;"))
        assert_guard_failure(self, self.run_preflight())
        assert_guard_failure(self, self.run_role_creation())
        self.assert_api_role_absent()

    def test_large_object_and_public_read_acl_fail_both_guards(self) -> None:
        created = assert_ok(
            self,
            self.target.psql(
                "shattab_stage",
                user="shattab_stage_admin",
                sql=(
                    "SELECT lo_create(0) AS contract_large_object_oid \\gset\n"
                    "GRANT SELECT ON LARGE OBJECT :contract_large_object_oid TO PUBLIC;"
                ),
            ),
        )
        self.assertIn("GRANT", created)

        # Inspect metadata and the effective PUBLIC ACL only; never read the object data.
        catalog_assertion = self.target.psql(
            "shattab_stage",
            user="shattab_stage_admin",
            sql=(
                "SELECT (SELECT count(*) FROM pg_largeobject_metadata) || '|' || "
                "(SELECT count(*) FROM pg_largeobject_metadata lom "
                "CROSS JOIN LATERAL aclexplode(COALESCE(lom.lomacl, "
                "acldefault('L', lom.lomowner))) AS x WHERE x.grantee = 0 "
                "AND x.privilege_type = 'SELECT');"
            ),
        )
        self.assertEqual(assert_ok(self, catalog_assertion).strip(), "1|1")

        assert_guard_failure(self, self.run_preflight())
        assert_guard_failure(self, self.run_role_creation())
        self.assert_api_role_absent()

    def test_role_attributes_defaults_and_search_path(self) -> None:
        output = assert_ok(self, self.run_role_creation())
        self.assertIn("PASS: created shattab_api", output)

        attributes = self.control(
            "SELECT rolcanlogin AND NOT rolsuper AND NOT rolcreatedb AND NOT rolcreaterole "
            "AND NOT rolreplication AND NOT rolbypassrls AND NOT rolinherit "
            "AND rolconnlimit = 3 FROM pg_roles WHERE rolname = 'shattab_api';"
        )
        self.assertEqual(assert_ok(self, attributes).strip(), "t")

        search_path = self.control(
            "SELECT array_to_string(rolconfig, ',') FROM pg_roles WHERE rolname = 'shattab_api';"
        )
        self.assertEqual(assert_ok(self, search_path).strip(), "search_path=pg_catalog")

        effective_defaults = self.stage_control(
            "SELECT has_schema_privilege('shattab_api', 'public', 'USAGE'), "
            "has_schema_privilege('shattab_api', 'public', 'CREATE'), "
            "has_database_privilege('shattab_api', 'shattab_stage', 'CONNECT'), "
            "has_database_privilege('shattab_api', 'shattab_stage', 'TEMPORARY'), "
            "has_database_privilege('shattab_api', 'shattab_stage', 'CREATE');"
        )
        self.assertEqual(assert_ok(self, effective_defaults).strip(), "t|f|t|t|f")

        memberships = self.control(
            "SELECT count(*) FROM pg_auth_members WHERE member = 'shattab_api'::regrole;"
        )
        self.assertEqual(assert_ok(self, memberships).strip(), "0")


class StageControlHelperTests(unittest.TestCase):
    def test_stage_control_uses_stage_database_and_admin_identity(self) -> None:
        class RecordingTarget:
            call: tuple[tuple[object, ...], dict[str, object]] | None = None

            def psql(self, *args: object, **kwargs: object) -> subprocess.CompletedProcess[str]:
                self.call = (args, kwargs)
                return subprocess.CompletedProcess(args, 0, "", "")

        target = RecordingTarget()
        fixture = object.__new__(Postgres18StageRoleTests)
        fixture.target = target  # type: ignore[assignment]

        result = fixture.stage_control("CREATE TABLE public.contract_probe (id integer);")

        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            target.call,
            (
                ("shattab_stage",),
                {
                    "user": "shattab_stage_admin",
                    "sql": "CREATE TABLE public.contract_probe (id integer);",
                },
            ),
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
