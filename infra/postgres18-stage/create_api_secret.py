#!/usr/bin/env python3
"""Safely bootstrap stage secrets or create the staged API password file."""

from __future__ import annotations

import argparse
import errno
import getpass
import os
import secrets
import stat
import sys
import warnings
from pathlib import Path


STAGE_ROOT = Path("/home/ubuntu/shattab-pg18-stage")
SECRETS_NAME = "secrets"
POSTGRES_SECRET_NAME = "postgres_password"
API_SECRET_NAME = "api_password"


class SecretProvisionError(Exception):
    """A sanitized failure that never includes password or OS error text."""


class SecretAlreadyExists(SecretProvisionError):
    """A destination exists and must not be overwritten."""


def _require_dirfd_support() -> None:
    required_flags = ("O_DIRECTORY", "O_NOFOLLOW", "O_CLOEXEC", "O_NONBLOCK")
    if os.name != "posix" or any(not hasattr(os, name) for name in required_flags):
        raise SecretProvisionError("secure directory-descriptor operations are unavailable")

    dir_fd_apis = getattr(os, "supports_dir_fd", set())
    if any(
        api not in dir_fd_apis
        for api in (os.open, os.stat, os.link, os.unlink, os.mkdir)
    ):
        raise SecretProvisionError("secure directory-descriptor operations are unavailable")
    follow_symlink_apis = getattr(os, "supports_follow_symlinks", set())
    if os.stat not in follow_symlink_apis or os.link not in follow_symlink_apis:
        raise SecretProvisionError("secure no-follow operations are unavailable")
    if any(not hasattr(os, name) for name in ("fstat", "fchown", "fchmod", "fsync")):
        raise SecretProvisionError("secure file-descriptor operations are unavailable")


def _directory_flags() -> int:
    _require_dirfd_support()
    return os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC


def _close_quietly(descriptor: int | None) -> None:
    if descriptor is None:
        return
    try:
        os.close(descriptor)
    except OSError:
        pass


def _open_absolute_directory(path: Path, *, label: str) -> int:
    """Walk an absolute directory path from / without following symlinks."""
    flags = _directory_flags()
    absolute = Path(os.path.abspath(os.fspath(path)))
    if not absolute.is_absolute():
        raise SecretProvisionError(f"{label} must be an absolute directory")

    current_fd: int | None = None
    try:
        current_fd = os.open(os.sep, flags)
        if not stat.S_ISDIR(os.fstat(current_fd).st_mode):
            raise SecretProvisionError(f"{label} is not a real directory")
        for component in absolute.parts[1:]:
            child_fd: int | None = None
            try:
                child_fd = os.open(component, flags, dir_fd=current_fd)
                child_stat = os.fstat(child_fd)
                if not stat.S_ISDIR(child_stat.st_mode):
                    raise SecretProvisionError(f"{label} is not a real directory")
            except Exception:
                _close_quietly(child_fd)
                raise
            _close_quietly(current_fd)
            current_fd = child_fd
        result = current_fd
        current_fd = None
        return result
    except SecretProvisionError:
        raise
    except OSError:
        raise SecretProvisionError(f"{label} could not be safely opened") from None
    finally:
        _close_quietly(current_fd)


def _open_child_directory(parent_fd: int, name: str, *, label: str) -> int:
    if not name or name in (".", "..") or "/" in name or "\x00" in name:
        raise SecretProvisionError(f"{label} path is invalid")
    descriptor: int | None = None
    try:
        descriptor = os.open(name, _directory_flags(), dir_fd=parent_fd)
        if not stat.S_ISDIR(os.fstat(descriptor).st_mode):
            _close_quietly(descriptor)
            descriptor = None
            raise SecretProvisionError(f"{label} is not a real directory")
        result = descriptor
        descriptor = None
        return result
    except SecretProvisionError:
        raise
    except OSError:
        raise SecretProvisionError(f"{label} could not be safely opened") from None
    finally:
        _close_quietly(descriptor)


def _validate_stage_directory(descriptor: int) -> os.stat_result:
    try:
        info = os.fstat(descriptor)
    except OSError:
        raise SecretProvisionError("staging directory metadata could not be checked") from None
    if not stat.S_ISDIR(info.st_mode):
        raise SecretProvisionError("staging path is not a real directory")
    if stat.S_IMODE(info.st_mode) != 0o700:
        raise SecretProvisionError("staging directory must have mode 0700")
    return info


def _validate_secrets_directory(descriptor: int) -> os.stat_result:
    try:
        info = os.fstat(descriptor)
    except OSError:
        raise SecretProvisionError("secret directory metadata could not be checked") from None
    if not stat.S_ISDIR(info.st_mode):
        raise SecretProvisionError("secret path is not a real directory")
    if info.st_uid != 0:
        raise SecretProvisionError("secret directory must be owned by root")
    if stat.S_IMODE(info.st_mode) != 0o700:
        raise SecretProvisionError("secret directory must have mode 0700")
    return info


def _validate_password(password: bytes) -> None:
    if not isinstance(password, bytes) or not 32 <= len(password) <= 4096:
        raise SecretProvisionError("password length is outside the accepted range")
    if b"\x00" in password or b"\n" in password or b"\r" in password:
        raise SecretProvisionError("password contains a disallowed control character")


def _stat_at(directory_fd: int, name: str) -> os.stat_result | None:
    try:
        return os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
    except FileNotFoundError:
        return None
    except OSError:
        raise SecretProvisionError("secret path could not be safely inspected") from None


def _require_absent_at(directory_fd: int, name: str) -> None:
    if not name or name in (".", "..") or "/" in name or "\x00" in name:
        raise SecretProvisionError("secret target path is invalid")
    if _stat_at(directory_fd, name) is not None:
        raise SecretAlreadyExists("secret target already exists; it was not replaced")


def _same_file(left: os.stat_result, right: os.stat_result) -> bool:
    return left.st_dev == right.st_dev and left.st_ino == right.st_ino


def _unlink_if_same(
    directory_fd: int,
    name: str,
    expected: os.stat_result,
) -> bool:
    current = _stat_at(directory_fd, name)
    if current is None:
        return True
    if not _same_file(current, expected):
        return False
    try:
        os.unlink(name, dir_fd=directory_fd)
    except FileNotFoundError:
        return True
    return True


def _write_all(descriptor: int, contents: bytes) -> None:
    remaining = memoryview(contents)
    while remaining:
        written = os.write(descriptor, remaining)
        if written <= 0:
            raise OSError("secret write was incomplete")
        remaining = remaining[written:]


def _create_secret_at(
    directory_fd: int,
    target_name: str,
    password: bytes,
    *,
    owner_uid: int,
    owner_gid: int,
    mode: int,
) -> None:
    """Publish a completed secret using only names relative to a pinned dir FD."""
    _require_dirfd_support()
    if os.geteuid() != 0:
        raise SecretProvisionError("secret creation requires a root process")
    if owner_uid < 0 or owner_gid < 0 or mode not in (0o440, 0o600):
        raise SecretProvisionError("secret ownership or mode is invalid")
    _validate_password(password)
    _validate_secrets_directory(directory_fd)
    _require_absent_at(directory_fd, target_name)

    file_fd: int | None = None
    temporary_name: str | None = None
    temporary_stat: os.stat_result | None = None
    published = False
    cleanup_failed = False
    failure: SecretProvisionError | None = None
    try:
        for _ in range(5):
            candidate = f".{target_name}.tmp.{os.getpid()}.{secrets.token_hex(8)}"
            try:
                file_fd = os.open(
                    candidate,
                    os.O_WRONLY
                    | os.O_CREAT
                    | os.O_EXCL
                    | os.O_NOFOLLOW
                    | os.O_CLOEXEC,
                    0o600,
                    dir_fd=directory_fd,
                )
                temporary_name = candidate
                temporary_stat = os.fstat(file_fd)
                break
            except FileExistsError:
                continue
        if file_fd is None or temporary_name is None:
            raise SecretProvisionError("a private temporary secret file could not be allocated")

        _write_all(file_fd, password)
        os.fchown(file_fd, owner_uid, owner_gid)
        os.fchmod(file_fd, mode)
        os.fsync(file_fd)

        temporary_stat = os.fstat(file_fd)
        if (
            not stat.S_ISREG(temporary_stat.st_mode)
            or temporary_stat.st_uid != owner_uid
            or temporary_stat.st_gid != owner_gid
            or stat.S_IMODE(temporary_stat.st_mode) != mode
            or temporary_stat.st_size != len(password)
        ):
            raise SecretProvisionError("secret metadata did not match the required contract")

        os.close(file_fd)
        file_fd = None

        # linkat-style publication is atomic and cannot replace an existing entry.
        os.link(
            temporary_name,
            target_name,
            src_dir_fd=directory_fd,
            dst_dir_fd=directory_fd,
            follow_symlinks=False,
        )
        published = True
        final_stat = _stat_at(directory_fd, target_name)
        if final_stat is None or not _same_file(final_stat, temporary_stat):
            raise SecretProvisionError(
                "secret target may have changed; inspect it before retrying"
            )
        if (
            not stat.S_ISREG(final_stat.st_mode)
            or final_stat.st_uid != owner_uid
            or final_stat.st_gid != owner_gid
            or stat.S_IMODE(final_stat.st_mode) != mode
            or final_stat.st_size != len(password)
        ):
            raise SecretProvisionError(
                "secret target metadata did not match; inspect it before retrying"
            )

        if not _unlink_if_same(directory_fd, temporary_name, temporary_stat):
            raise SecretProvisionError(
                "secret target may be complete and a temporary file may remain; "
                "inspect both names manually before retrying"
            )
        temporary_name = None
        os.fsync(directory_fd)
    except FileExistsError:
        failure = SecretAlreadyExists("secret target already exists; it was not replaced")
    except SecretProvisionError as error:
        failure = error
    except OSError:
        detail = (
            "secret target may be complete; inspect it before retrying"
            if published
            else "secret file creation failed; no value was displayed"
        )
        failure = SecretProvisionError(detail)
    finally:
        _close_quietly(file_fd)
        if temporary_name is not None:
            if temporary_stat is None:
                cleanup_failed = True
            else:
                try:
                    if not _unlink_if_same(directory_fd, temporary_name, temporary_stat):
                        cleanup_failed = True
                except (OSError, SecretProvisionError):
                    cleanup_failed = True

    if cleanup_failed:
        if published:
            raise SecretProvisionError(
                "secret target may be complete and a temporary file may remain; "
                "inspect both names manually before retrying"
            ) from None
        raise SecretProvisionError(
            "secret creation failed and a temporary file may remain; "
            "inspect it manually before retrying"
        ) from None
    if failure is not None:
        raise failure


def create_secret_file(
    target: Path,
    password: bytes,
    *,
    node_uid: int,
    node_gid: int,
    owner_uid: int = 0,
) -> None:
    """Create the API file as root:<node_gid> mode 0440, without replacement."""
    if node_uid <= 0 or node_gid < 0 or owner_uid < 0:
        raise SecretProvisionError("verified process identity is invalid")
    target_path = Path(target)
    directory_fd = _open_absolute_directory(target_path.parent, label="secret directory")
    try:
        _validate_secrets_directory(directory_fd)
        _create_secret_at(
            directory_fd,
            target_path.name,
            password,
            owner_uid=owner_uid,
            owner_gid=node_gid,
            mode=0o440,
        )
    finally:
        _close_quietly(directory_fd)


def _pin_stage_and_secrets(*, create_secrets: bool) -> tuple[int, int, os.stat_result]:
    stage_fd = _open_absolute_directory(STAGE_ROOT, label="staging directory")
    secrets_fd: int | None = None
    try:
        stage_stat = _validate_stage_directory(stage_fd)
        try:
            secrets_fd = os.open(
                SECRETS_NAME,
                _directory_flags(),
                dir_fd=stage_fd,
            )
        except FileNotFoundError:
            if not create_secrets:
                raise SecretProvisionError("secret directory is missing") from None
            created_secrets = False
            try:
                os.mkdir(SECRETS_NAME, 0o700, dir_fd=stage_fd)
                created_secrets = True
            except FileExistsError:
                pass
            except OSError:
                raise SecretProvisionError("secret directory could not be created safely") from None
            try:
                secrets_fd = os.open(
                    SECRETS_NAME,
                    _directory_flags(),
                    dir_fd=stage_fd,
                )
            except OSError:
                raise SecretProvisionError("secret directory could not be safely opened") from None
            if created_secrets:
                os.fchmod(secrets_fd, 0o700)
        except OSError:
            raise SecretProvisionError("secret directory could not be safely opened") from None

        _validate_secrets_directory(secrets_fd)
        return stage_fd, secrets_fd, stage_stat
    except Exception:
        _close_quietly(secrets_fd)
        _close_quietly(stage_fd)
        raise


def _bootstrap_postgres_password() -> None:
    stage_fd: int | None = None
    secrets_fd: int | None = None
    password = b""
    try:
        stage_fd, secrets_fd, stage_stat = _pin_stage_and_secrets(create_secrets=True)
        _require_absent_at(secrets_fd, POSTGRES_SECRET_NAME)
        password = secrets.token_hex(32).encode("ascii")
        _create_secret_at(
            secrets_fd,
            POSTGRES_SECRET_NAME,
            password,
            owner_uid=stage_stat.st_uid,
            owner_gid=stage_stat.st_gid,
            mode=0o600,
        )
    finally:
        password = b""
        _close_quietly(secrets_fd)
        _close_quietly(stage_fd)


def verify_secret_for_current_process(path: Path) -> None:
    """Check root:<primary-gid> mode 0440 using only a pinned parent FD."""
    if os.name != "posix" or not hasattr(os, "geteuid"):
        raise SecretProvisionError("Linux permission verification is required")
    if os.getuid() == 0 or os.geteuid() == 0:
        raise SecretProvisionError("secret access check must run as a non-root process")
    _require_dirfd_support()

    path = Path(os.path.abspath(os.fspath(path)))
    directory_fd = _open_absolute_directory(path.parent, label="mounted secret directory")
    read_fd: int | None = None
    write_fd: int | None = None
    try:
        before = _stat_at(directory_fd, path.name)
        if before is None:
            raise SecretProvisionError("secret file could not be safely checked")
        if (
            not stat.S_ISREG(before.st_mode)
            or before.st_uid != 0
            or before.st_gid != os.getgid()
            or stat.S_IMODE(before.st_mode) != 0o440
        ):
            raise SecretProvisionError(
                "secret metadata does not match root:<process-gid> mode 0440"
            )

        try:
            read_fd = os.open(
                path.name,
                os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC,
                dir_fd=directory_fd,
            )
            opened = os.fstat(read_fd)
            if (
                not stat.S_ISREG(opened.st_mode)
                or not _same_file(opened, before)
                or opened.st_uid != 0
                or opened.st_gid != os.getgid()
                or stat.S_IMODE(opened.st_mode) != 0o440
                or opened.st_size < 1
                or not os.read(read_fd, 1)
            ):
                raise SecretProvisionError(
                    "secret could not be read as the expected regular file"
                )
        except SecretProvisionError:
            raise
        except OSError:
            raise SecretProvisionError("secret could not be read by the current process") from None
        finally:
            _close_quietly(read_fd)
            read_fd = None

        try:
            write_fd = os.open(
                path.name,
                os.O_WRONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC,
                dir_fd=directory_fd,
            )
        except OSError as error:
            if error.errno not in (errno.EACCES, errno.EPERM, errno.EROFS):
                raise SecretProvisionError("write denial could not be verified") from None
        else:
            _close_quietly(write_fd)
            write_fd = None
            raise SecretProvisionError("current process can open the secret for writing")
    finally:
        _close_quietly(read_fd)
        _close_quietly(write_fd)
        _close_quietly(directory_fd)


def _has_controlling_tty() -> bool:
    if os.name != "posix":
        return False
    try:
        tty_fd = os.open("/dev/tty", os.O_RDWR | getattr(os, "O_NOCTTY", 0))
    except OSError:
        return False
    _close_quietly(tty_fd)
    return True


def _run_api_secret(node_uid: int, node_gid: int) -> None:
    if node_uid <= 0 or node_gid < 0:
        raise SecretProvisionError("supply the verified non-root Node UID and primary GID")
    if not _has_controlling_tty():
        raise SecretProvisionError("an interactive controlling terminal is required")

    stage_fd: int | None = None
    secrets_fd: int | None = None
    password_text = ""
    confirmation = ""
    password = b""
    try:
        stage_fd, secrets_fd, _ = _pin_stage_and_secrets(create_secrets=False)
        _require_absent_at(secrets_fd, API_SECRET_NAME)

        with warnings.catch_warnings():
            warnings.simplefilter("error", getpass.GetPassWarning)
            password_text = getpass.getpass("API password: ")
            confirmation = getpass.getpass("Repeat API password: ")
        if password_text != confirmation:
            raise SecretProvisionError("entered values did not match")
        try:
            password = password_text.encode("utf-8", errors="strict")
        except UnicodeEncodeError:
            raise SecretProvisionError("entered value is not valid UTF-8") from None

        _create_secret_at(
            secrets_fd,
            API_SECRET_NAME,
            password,
            owner_uid=0,
            owner_gid=node_gid,
            mode=0o440,
        )
    finally:
        password_text = ""
        confirmation = ""
        password = b""
        _close_quietly(secrets_fd)
        _close_quietly(stage_fd)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Bootstrap stage secrets or create the API password file safely."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--bootstrap-postgres-password",
        action="store_true",
        help="create the root-owned secrets directory if absent and a random bootstrap file",
    )
    mode.add_argument("--node-uid", type=int)
    parser.add_argument("--node-gid", type=int)
    args = parser.parse_args(argv)

    if os.name != "posix" or not hasattr(os, "geteuid") or os.geteuid() != 0:
        print("ERROR: run this helper with sudo on Linux.", file=sys.stderr)
        return 2

    try:
        _require_dirfd_support()
        if args.bootstrap_postgres_password:
            if args.node_gid is not None:
                raise SecretProvisionError("bootstrap mode does not accept Node identity arguments")
            _bootstrap_postgres_password()
            print(
                "PASS: created root-owned secrets directory if absent and a "
                "staging-owner mode-0600 bootstrap file; value was not displayed."
            )
            return 0

        if args.node_uid is None or args.node_gid is None:
            raise SecretProvisionError("supply both verified Node UID and primary GID")
        _run_api_secret(args.node_uid, args.node_gid)
    except SecretAlreadyExists as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    except SecretProvisionError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    except Exception:
        print("ERROR: secret setup failed; inspect the target before retrying.", file=sys.stderr)
        return 1

    print(f"PASS: created root:{args.node_gid} mode 0440; password value was not displayed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
