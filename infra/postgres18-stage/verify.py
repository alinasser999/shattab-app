#!/usr/bin/env python3
"""Safely verify the isolated Shattab PostgreSQL 18 staging container."""

from __future__ import annotations

import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path
from typing import Any


PROJECT = "shattab-pg18-stage"
SERVICE = "db"
DATABASE = "shattab_stage"
ADMIN_ROLE = "shattab_stage_admin"
IMAGE = (
    "postgres:18.6-bookworm@sha256:"
    "bbf83594798e144bff365a9c191c5d779f181fb3135902064ab8ff11918020fc"
)
VOLUME = "shattab-pg18-stage_pgdata"
NETWORK = "shattab-pg18-stage_db_internal"
DATA_TARGET = "/var/lib/postgresql"
SECRET_TARGET = "/run/secrets/postgres_password"
ROOT = Path(__file__).absolute().parent
SECRET_DIR = ROOT / "secrets"
SECRET_FILE = SECRET_DIR / "postgres_password"
HEX_PASSWORD = re.compile(rb"[0-9a-f]{64}\n?\Z")
CONTAINER_ID = re.compile(r"[0-9a-f]{12,64}\Z")


class VerificationError(Exception):
    """A safe, non-secret diagnostic for an expected verification failure."""


def docker(args: list[str], *, action: str, timeout: int = 20) -> str:
    """Run Docker without forwarding command output or diagnostics to the user."""
    try:
        completed = subprocess.run(
            ["docker", *args],
            cwd=ROOT,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        raise VerificationError(f"Docker action timed out: {action}.") from exc
    except OSError as exc:
        raise VerificationError(f"Docker CLI could not run: {action}.") from exc
    if completed.returncode != 0:
        raise VerificationError(
            f"Docker action failed: {action} (exit {completed.returncode})."
        )
    return completed.stdout.strip()


def docker_inspect(container_id: str, template: str, *, action: str) -> str:
    return docker(
        ["inspect", "--format", template, container_id], action=action
    )


def decode_json(value: str, *, action: str) -> Any:
    try:
        return json.loads(value)
    except (TypeError, json.JSONDecodeError) as exc:
        raise VerificationError(f"Docker returned invalid metadata: {action}.") from exc


def postgres_version_token(server_version: str) -> str | None:
    """Return the numeric major.minor token, ignoring a distro suffix."""
    match = re.match(r"^([0-9]+\.[0-9]+)(?:[ \t]|$)", server_version)
    return match.group(1) if match else None


def matches_target_postgres_version(server_version: str, version_num: str) -> bool:
    return postgres_version_token(server_version) == "18.6" and version_num == "180006"


def check_secret_file() -> bytes:
    """Read the server-only secret with no-follow and mode/owner checks."""
    try:
        root_stat = ROOT.lstat()
        directory_stat = SECRET_DIR.lstat()
        if not stat.S_ISDIR(root_stat.st_mode) or stat.S_ISLNK(root_stat.st_mode):
            raise VerificationError("The staging directory is not a real directory.")
        if stat.S_IMODE(root_stat.st_mode) != 0o700:
            raise VerificationError("The staging directory must have mode 0700.")
        if not stat.S_ISDIR(directory_stat.st_mode) or stat.S_ISLNK(
            directory_stat.st_mode
        ):
            raise VerificationError("The secrets path is not a real directory.")
        if stat.S_IMODE(directory_stat.st_mode) != 0o700:
            raise VerificationError("The secrets directory must have mode 0700.")
        if directory_stat.st_uid != root_stat.st_uid:
            raise VerificationError(
                "The secrets directory owner must match the staging directory owner."
            )
        flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
        descriptor = os.open(SECRET_FILE, flags)
        try:
            file_stat = os.fstat(descriptor)
            if not stat.S_ISREG(file_stat.st_mode):
                raise VerificationError("The password secret is not a regular file.")
            if stat.S_IMODE(file_stat.st_mode) != 0o600:
                raise VerificationError("The password secret must have mode 0600.")
            if file_stat.st_uid != directory_stat.st_uid:
                raise VerificationError(
                    "The password secret owner must match its secrets directory."
                )
            with os.fdopen(descriptor, "rb", closefd=False) as source:
                password = source.read(66)
        finally:
            os.close(descriptor)
    except VerificationError:
        raise
    except OSError as exc:
        raise VerificationError(
            "The protected server-side password secret could not be inspected."
        ) from exc
    if not HEX_PASSWORD.fullmatch(password):
        raise VerificationError(
            "The password secret format is not the expected 32-byte hex value."
        )
    return password.rstrip(b"\n")


def check_compose_config() -> None:
    # --quiet is intentional: Compose must never render resolved settings here.
    docker(
        [
            "compose",
            "--env-file",
            "/dev/null",
            "-f",
            "compose.yaml",
            "-p",
            PROJECT,
            "config",
            "--quiet",
        ],
        action="quiet Compose configuration validation",
    )


def inspect_main_container() -> tuple[str, str]:
    container_id = docker(
        [
            "compose",
            "--env-file",
            "/dev/null",
            "-f",
            "compose.yaml",
            "-p",
            PROJECT,
            "ps",
            "-q",
            SERVICE,
        ],
        action="find the staging database container",
    )
    if not CONTAINER_ID.fullmatch(container_id):
        raise VerificationError(
            "Expected exactly one running database container for this Compose service."
        )

    labels = decode_json(
        docker_inspect(container_id, "{{json .Config.Labels}}", action="read container labels"),
        action="container labels",
    )
    if not isinstance(labels, dict):
        raise VerificationError("The staging container has no valid Compose labels.")
    if (
        labels.get("com.docker.compose.project") != PROJECT
        or labels.get("com.docker.compose.service") != SERVICE
    ):
        raise VerificationError("The container identity does not match this stage.")

    image_reference = docker_inspect(
        container_id, "{{.Config.Image}}", action="read configured image"
    )
    if image_reference != IMAGE:
        raise VerificationError("The staging container uses an unexpected image reference.")
    image_id = docker_inspect(container_id, "{{.Image}}", action="read image ID")
    image_os = docker(["image", "inspect", "--format", "{{.Os}}", image_id], action="read image OS")
    image_arch = docker(
        ["image", "inspect", "--format", "{{.Architecture}}", image_id],
        action="read image architecture",
    )
    if image_os != "linux" or image_arch != "arm64":
        raise VerificationError("The pulled staging image is not linux/arm64.")

    state = docker_inspect(
        container_id, "{{.State.Status}}", action="read container state"
    )
    health = docker_inspect(
        container_id,
        "{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}",
        action="read health status",
    )
    if state != "running" or health != "healthy":
        raise VerificationError("The staging database is not running and healthy.")

    expected_limits = {
        "memory": "1073741824",
        "nano_cpus": "1000000000",
        "pids": "128",
        "shm": "134217728",
    }
    actual_limits = {
        "memory": docker_inspect(
            container_id, "{{.HostConfig.Memory}}", action="read memory limit"
        ),
        "nano_cpus": docker_inspect(
            container_id, "{{.HostConfig.NanoCpus}}", action="read CPU limit"
        ),
        "pids": docker_inspect(
            container_id, "{{.HostConfig.PidsLimit}}", action="read PID limit"
        ),
        "shm": docker_inspect(
            container_id, "{{.HostConfig.ShmSize}}", action="read shared memory limit"
        ),
    }
    if actual_limits != expected_limits:
        raise VerificationError("The staging resource limits do not match the reviewed plan.")

    restart_policy = docker_inspect(
        container_id,
        "{{.HostConfig.RestartPolicy.Name}}",
        action="read restart policy",
    )
    if restart_policy != "no":
        raise VerificationError("The staging restart policy must be no.")

    port_bindings = decode_json(
        docker_inspect(
            container_id,
            "{{json .HostConfig.PortBindings}}",
            action="read published ports",
        ),
        action="published ports",
    )
    if port_bindings not in (None, {}):
        raise VerificationError("The staging container has a host port mapping.")

    logging_type = docker_inspect(
        container_id,
        "{{.HostConfig.LogConfig.Type}}",
        action="read logging driver",
    )
    logging_config = decode_json(
        docker_inspect(
            container_id,
            "{{json .HostConfig.LogConfig.Config}}",
            action="read logging limits",
        ),
        action="logging limits",
    )
    if (
        not isinstance(logging_config, dict)
        or logging_type != "json-file"
        or logging_config.get("max-size") != "10m"
        or logging_config.get("max-file") != "3"
    ):
        raise VerificationError("The staging log rotation is not configured as reviewed.")

    security_options = decode_json(
        docker_inspect(
            container_id,
            "{{json .HostConfig.SecurityOpt}}",
            action="read security options",
        ),
        action="security options",
    )
    if (
        not isinstance(security_options, list)
        or "no-new-privileges:true" not in security_options
    ):
        raise VerificationError("The staging container lacks no-new-privileges.")

    mounts = decode_json(
        docker_inspect(container_id, "{{json .Mounts}}", action="read mounts"),
        action="container mounts",
    )
    if not isinstance(mounts, list):
        raise VerificationError("The staging container mount metadata is invalid.")
    if {mount.get("Destination") for mount in mounts} != {
        DATA_TARGET,
        SECRET_TARGET,
    }:
        raise VerificationError("The staging container has an unexpected mount.")
    data_mounts = [
        mount
        for mount in mounts
        if mount.get("Destination") == DATA_TARGET
        and mount.get("Type") == "volume"
    ]
    if len(data_mounts) != 1 or data_mounts[0].get("Name") != VOLUME:
        raise VerificationError("The PostgreSQL 18 data volume is not the expected named volume.")
    if any(mount.get("Destination") == "/var/lib/postgresql/data" for mount in mounts):
        raise VerificationError("The PostgreSQL 17 data path must not be mounted here.")
    secret_mounts = [
        mount
        for mount in mounts
        if mount.get("Destination") == SECRET_TARGET
    ]
    if (
        len(secret_mounts) != 1
        or secret_mounts[0].get("Type") != "bind"
        or secret_mounts[0].get("RW") is not False
        or secret_mounts[0].get("Source") != str(SECRET_FILE)
    ):
        raise VerificationError("The bootstrap secret is not mounted read-only as expected.")

    networks = decode_json(
        docker_inspect(
            container_id,
            "{{json .NetworkSettings.Networks}}",
            action="read attached networks",
        ),
        action="attached networks",
    )
    if not isinstance(networks, dict) or set(networks) != {NETWORK}:
        raise VerificationError("The staging container is attached to an unexpected network.")
    internal = docker(
        [
            "network",
            "inspect",
            "--format",
            "{{.Internal}}",
            NETWORK,
        ],
        action="check internal network",
    )
    if internal.lower() != "true":
        raise VerificationError("The staging network is not marked internal.")
    network_driver = docker(
        ["network", "inspect", "--format", "{{.Driver}}", NETWORK],
        action="check network driver",
    )
    network_labels = decode_json(
        docker(
            ["network", "inspect", "--format", "{{json .Labels}}", NETWORK],
            action="read network labels",
        ),
        action="network labels",
    )
    if (
        network_driver != "bridge"
        or not isinstance(network_labels, dict)
        or network_labels.get("com.docker.compose.project") != PROJECT
        or network_labels.get("com.docker.compose.network") != "db_internal"
    ):
        raise VerificationError("The staging network identity does not match the Compose project.")

    return container_id, image_arch


def pgpass_escape(value: bytes) -> bytes:
    return value.replace(b"\\", b"\\\\").replace(b":", b"\\:")


def cleanup_auth_client(name: str, attempted: bool) -> bool:
    if not attempted:
        return True
    # Removal is idempotent. Suppress its diagnostics and then query the daemon
    # by the exact, random name before unmounting/removing the credential file.
    try:
        subprocess.run(
            ["docker", "rm", "-f", name],
            cwd=ROOT,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
            timeout=20,
        )
        remaining = subprocess.run(
            [
                "docker",
                "ps",
                "-a",
                "--filter",
                f"name=^/{name}$",
                "--format",
                "{{.Names}}",
            ],
            cwd=ROOT,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
            timeout=20,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    if remaining.returncode != 0:
        return False
    names = [line.strip() for line in remaining.stdout.splitlines() if line.strip()]
    return not names


def run_password_auth_check(password: bytes) -> list[str]:
    """Use a protected temporary pgpass and remove it only after client removal."""
    client_name = f"shattab-pg18-authcheck-{uuid.uuid4().hex}"
    temp_path: Path | None = None
    create_attempted = False
    cleanup_confirmed = False
    query_result: str | None = None
    failure: str | None = None

    try:
        descriptor, raw_path = tempfile.mkstemp(
            prefix=".shattab-pg18-stage-pgpass-", dir="/tmp"
        )
        temp_path = Path(raw_path)
        with os.fdopen(descriptor, "wb") as destination:
            os.fchmod(destination.fileno(), 0o600)
            content = b":".join(
                (
                    b"db",
                    b"5432",
                    DATABASE.encode("ascii"),
                    ADMIN_ROLE.encode("ascii"),
                    pgpass_escape(password),
                )
            ) + b"\n"
            destination.write(content)
            destination.flush()
            os.fsync(destination.fileno())

        mount = f"type=bind,source={temp_path},target=/root/.pgpass,readonly"
        create_attempted = True
        docker(
            [
                "create",
                "--name",
                client_name,
                "--network",
                NETWORK,
                "--mount",
                mount,
                "--user",
                "0:0",
                "--cap-drop",
                "ALL",
                "--security-opt",
                "no-new-privileges:true",
                "--env",
                "PGPASSFILE=/root/.pgpass",
                "--entrypoint",
                "psql",
                IMAGE,
                "-w",
                "-h",
                SERVICE,
                "-p",
                "5432",
                "-U",
                ADMIN_ROLE,
                "-d",
                DATABASE,
                "-X",
                "-A",
                "-t",
                "-F",
                "|",
                "-q",
                "-c",
                (
                    "SELECT current_user, current_database(), "
                    "current_setting('server_version'), "
                    "current_setting('server_version_num'), "
                    "current_setting('data_directory'), "
                    "(SELECT count(*) FROM pg_class c "
                    "JOIN pg_namespace n ON n.oid = c.relnamespace "
                    "WHERE n.nspname NOT LIKE 'pg_%' "
                    "AND n.nspname <> 'information_schema' "
                    "AND c.relkind IN ('r','p','v','m','f','S')), "
                    "(SELECT rolpassword LIKE 'SCRAM-SHA-256$%' "
                    "FROM pg_authid WHERE rolname = current_user), "
                    "(SELECT count(*) FROM pg_hba_file_rules "
                    "WHERE type IN ('host','hostssl','hostnossl') "
                    "AND auth_method = 'scram-sha-256'), "
                    "(SELECT count(*) FROM pg_hba_file_rules "
                    "WHERE type IN ('host','hostssl','hostnossl') "
                    "AND auth_method IS DISTINCT FROM 'scram-sha-256');"
                ),
            ],
            action="create temporary password-auth client",
        )
        query_result = docker(
            ["start", "--attach", client_name],
            action="run password-auth query",
            timeout=45,
        )
    except VerificationError as exc:
        failure = str(exc)
    except OSError as exc:
        failure = "The protected password-auth check could not complete."
    finally:
        cleanup_confirmed = cleanup_auth_client(client_name, create_attempted)
        if cleanup_confirmed and temp_path is not None:
            try:
                temp_path.unlink(missing_ok=True)
                cleanup_confirmed = not temp_path.exists()
            except OSError:
                cleanup_confirmed = False

    if not cleanup_confirmed:
        retained = (
            f" Protected pgpass file retained at {temp_path}."
            if temp_path is not None and temp_path.exists()
            else ""
        )
        raise VerificationError(
            "Could not confirm temporary auth-client cleanup; do not remove its "
            f"credential mount until Docker state is reviewed.{retained}"
        )
    if failure is not None:
        raise VerificationError(f"Password-auth verification failed safely: {failure}")
    if query_result is None:
        raise VerificationError("The password-auth query returned no result.")

    fields = query_result.split("|")
    if len(fields) != 9:
        raise VerificationError("The password-auth query returned an unexpected result shape.")
    (
        role,
        database,
        version,
        version_num,
        data_directory,
        relation_count,
        scram_verifier,
        scram_rules,
        other_host_rules,
    ) = fields
    if (
        role != ADMIN_ROLE
        or database != DATABASE
        or not matches_target_postgres_version(version, version_num)
        or data_directory != "/var/lib/postgresql/18/docker"
        or relation_count != "0"
        or scram_verifier != "t"
        or not scram_rules.isdigit()
        or int(scram_rules) < 1
        or other_host_rules != "0"
    ):
        raise VerificationError(
            "The staging identity, version, empty-relation, or SCRAM checks did not match."
        )
    fields[2] = postgres_version_token(fields[2]) or ""
    return fields


def main() -> int:
    try:
        if sys.platform != "linux":
            raise VerificationError("Run this verifier on the Ubuntu staging host.")
        check_compose_config()
        password = check_secret_file()
        _, architecture = inspect_main_container()
        fields = run_password_auth_check(password)
        del password
    except VerificationError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    print("PASS: isolated PostgreSQL staging checks succeeded.")
    print(f"Compose project: {PROJECT}; service: {SERVICE}; architecture: linux/{architecture}.")
    print(
        "TCP/SCRAM result: "
        f"role={fields[0]}, database={fields[1]}, PostgreSQL={fields[2]}, "
        f"server_version_num={fields[3]}, data_directory={fields[4]}, "
        f"non-system_relations={fields[5]}, SCRAM_verifier={fields[6]}, "
        f"SCRAM_host_rules={fields[7]}, other_host_auth_rules={fields[8]}."
    )
    print("PASS: no host port mapping; internal network; expected volume and limits verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
