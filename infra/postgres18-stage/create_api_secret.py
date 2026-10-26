#!/usr/bin/env python3
"""Create the staged API password file without displaying or replacing it."""

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


class SecretProvisionError(Exception):
    """A sanitized failure that never includes the password or OS error text."""


class SecretAlreadyExists(SecretProvisionError):
    """The destination exists and must not be overwritten."""


def _validate_parent(parent: Path) -> None:
    try:
        parent_stat = os.lstat(parent)
    except OSError:
        raise SecretProvisionError("secret directory could not be safely checked") from None

    if not stat.S_ISDIR(parent_stat.st_mode) or stat.S_ISLNK(parent_stat.st_mode):
        raise SecretProvisionError("secret directory must be a real directory")
    if parent_stat.st_uid != 0:
        raise SecretProvisionError("secret directory must be owned by root")
    if stat.S_IMODE(parent_stat.st_mode) != 0o700:
        raise SecretProvisionError("secret directory must have mode 0700")


def _validate_password(password: bytes) -> None:
    if not isinstance(password, bytes) or not 32 <= len(password) <= 4096:
        raise SecretProvisionError("password length is outside the accepted range")
    if b"\x00" in password or b"\n" in password or b"\r" in password:
        raise SecretProvisionError("password contains a disallowed control character")


def create_secret_file(
    target: Path,
    password: bytes,
    *,
    node_uid: int,
    node_gid: int,
    owner_uid: int = 0,
) -> None:
    """Atomically create root:<node_gid> 0440 at an absent-only target.

    The caller must obtain the password through a hidden prompt. This function
    never returns or prints password bytes. Production invokes it as root with
    ``owner_uid=0``; tests use temporary paths only.
    """
    if node_uid <= 0 or node_gid < 0 or owner_uid < 0:
        raise SecretProvisionError("verified process identity is invalid")
    _validate_password(password)
    target = Path(target)
    parent = target.parent
    _validate_parent(parent)

    if os.path.lexists(target):
        raise SecretAlreadyExists("secret target already exists; it was not replaced")

    directory_fd: int | None = None
    temporary_path: Path | None = None
    file_fd: int | None = None
    published = False
    cleanup_failed = False
    failure: SecretProvisionError | None = None
    try:
        directory_fd = os.open(parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
        for _ in range(5):
            candidate = parent / f".api_password.tmp.{os.getpid()}.{secrets.token_hex(8)}"
            try:
                file_fd = os.open(
                    candidate,
                    os.O_WRONLY
                    | os.O_CREAT
                    | os.O_EXCL
                    | getattr(os, "O_NOFOLLOW", 0),
                    0o600,
                )
                temporary_path = candidate
                break
            except FileExistsError:
                continue
        if file_fd is None or temporary_path is None:
            raise OSError("temporary file could not be allocated")

        remaining = memoryview(password)
        while remaining:
            written = os.write(file_fd, remaining)
            if written <= 0:
                raise OSError("secret write was incomplete")
            remaining = remaining[written:]

        os.fchown(file_fd, owner_uid, node_gid)
        os.fchmod(file_fd, 0o440)
        os.fsync(file_fd)

        file_stat = os.fstat(file_fd)
        if (
            not stat.S_ISREG(file_stat.st_mode)
            or file_stat.st_uid != owner_uid
            or file_stat.st_gid != node_gid
            or stat.S_IMODE(file_stat.st_mode) != 0o440
            or file_stat.st_size != len(password)
        ):
            raise OSError("secret metadata did not match the required contract")

        os.close(file_fd)
        file_fd = None

        # A hard link publishes the complete file without replacing any target,
        # including a symlink created by a concurrent process.
        os.link(temporary_path, target, follow_symlinks=False)
        published = True
        try:
            os.unlink(temporary_path)
        except OSError:
            raise SecretProvisionError(
                "API secret target may be complete and a temporary file may remain; "
                "inspect both paths manually before retrying."
            ) from None
        temporary_path = None
        os.fsync(directory_fd)
    except FileExistsError:
        failure = SecretAlreadyExists("secret target already exists; it was not replaced")
    except SecretProvisionError as error:
        failure = error
    except OSError:
        detail = (
            "secret target may already contain a complete file; inspect it before retrying"
            if published
            else "secret file creation failed; no value was displayed"
        )
        failure = SecretProvisionError(detail)
    finally:
        if file_fd is not None:
            os.close(file_fd)
        if temporary_path is not None:
            try:
                os.unlink(temporary_path)
            except OSError:
                cleanup_failed = True
        if directory_fd is not None:
            os.close(directory_fd)

    if cleanup_failed:
        if published:
            raise SecretProvisionError(
                "API secret target may be complete and a temporary file may remain; "
                "inspect both paths manually before retrying."
            ) from None
        if isinstance(failure, SecretAlreadyExists):
            raise SecretProvisionError(
                "API secret target already existed and was not overwritten; a temporary "
                "file may remain; inspect it manually before retrying."
            ) from None
        raise SecretProvisionError(
            "API secret creation failed; a temporary file may remain; inspect it "
            "manually before retrying; no value was displayed."
        ) from None
    if failure is not None:
        raise failure


def verify_secret_for_current_process(path: Path) -> None:
    """Verify exact root:<primary-gid> 0440 metadata and real read/no-write."""
    if os.name != "posix" or not hasattr(os, "geteuid"):
        raise SecretProvisionError("Linux permission verification is required")
    if os.getuid() == 0 or os.geteuid() == 0:
        raise SecretProvisionError("secret access check must run as a non-root process")

    path = Path(path)
    try:
        before = os.lstat(path)
    except OSError:
        raise SecretProvisionError("secret file could not be safely checked") from None

    if (
        not stat.S_ISREG(before.st_mode)
        or stat.S_ISLNK(before.st_mode)
        or before.st_uid != 0
        or before.st_gid != os.getgid()
        or stat.S_IMODE(before.st_mode) != 0o440
    ):
        raise SecretProvisionError("secret metadata does not match root:<process-gid> mode 0440")

    read_fd: int | None = None
    try:
        read_fd = os.open(
            path,
            os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0),
        )
        opened = os.fstat(read_fd)
        if (
            opened.st_dev != before.st_dev
            or opened.st_ino != before.st_ino
            or not stat.S_ISREG(opened.st_mode)
            or opened.st_size < 1
            or not os.read(read_fd, 1)
        ):
            raise SecretProvisionError("secret could not be read as the expected regular file")
    except SecretProvisionError:
        raise
    except OSError:
        raise SecretProvisionError("secret could not be read by the current process") from None
    finally:
        if read_fd is not None:
            os.close(read_fd)

    write_fd: int | None = None
    try:
        write_fd = os.open(
            path,
            os.O_WRONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0),
        )
    except OSError as error:
        if error.errno not in (errno.EACCES, errno.EPERM, errno.EROFS):
            raise SecretProvisionError("write denial could not be verified") from None
    else:
        os.close(write_fd)
        raise SecretProvisionError("current process can open the secret for writing")


def _has_controlling_tty() -> bool:
    if os.name != "posix":
        return False
    try:
        tty_fd = os.open("/dev/tty", os.O_RDWR | getattr(os, "O_NOCTTY", 0))
    except OSError:
        return False
    os.close(tty_fd)
    return True


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Create the PostgreSQL API password file without displaying its value."
    )
    parser.add_argument("--node-uid", required=True, type=int)
    parser.add_argument("--node-gid", required=True, type=int)
    args = parser.parse_args(argv)

    if os.name != "posix" or os.geteuid() != 0:
        print("ERROR: run this helper with sudo on Linux.", file=sys.stderr)
        return 2
    if args.node_uid <= 0 or args.node_gid < 0:
        print("ERROR: supply the verified non-root Node UID and primary GID.", file=sys.stderr)
        return 2
    if not _has_controlling_tty():
        print("ERROR: an interactive controlling terminal is required; no secret was read.", file=sys.stderr)
        return 2

    target = Path(__file__).resolve().parent / "secrets" / "api_password"
    try:
        _validate_parent(target.parent)
        if os.path.lexists(target):
            raise SecretAlreadyExists("secret target already exists; it was not replaced")

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
        create_secret_file(
            target,
            password,
            node_uid=args.node_uid,
            node_gid=args.node_gid,
            owner_uid=0,
        )
    except SecretProvisionError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    except Exception:
        print("ERROR: secret setup failed; inspect the target before retrying.", file=sys.stderr)
        return 1
    finally:
        if "password_text" in locals():
            password_text = ""
        if "confirmation" in locals():
            confirmation = ""
        if "password" in locals():
            password = b""

    print(f"PASS: created root:{args.node_gid} mode 0440; password value was not displayed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
