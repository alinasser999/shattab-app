"""Temporary-path tests for the staged API secret contract; never use secrets/."""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


STAGE = Path(__file__).resolve().parent
sys.path.insert(0, str(STAGE))
import create_api_secret as secret_helper  # noqa: E402
import verify as stage_verifier  # noqa: E402
from create_api_secret import (  # noqa: E402
    SecretAlreadyExists,
    SecretProvisionError,
    create_secret_file,
    verify_secret_for_current_process,
)


LINUX_ROOT = os.name == "posix" and hasattr(os, "geteuid") and os.geteuid() == 0
TEST_UID = 61321
TEST_GID = 61321
TEST_EGID = 61322
FIXTURE_PASSWORD = b"test-only-value-that-is-never-printed-74218"
BOOTSTRAP_VERIFIER_FIXTURE = b"0123456789abcdef" * 4 + b"\n"


@unittest.skipUnless(LINUX_ROOT, "permission behavior requires a Linux root runner")
class ApiSecretFileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="shattab-api-secret-test-")
        self.directory = Path(self.temporary.name)
        os.chmod(self.directory, 0o700)
        self.target = self.directory / "api_password"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _run_as_node(self, target: Path) -> subprocess.CompletedProcess[str]:
        # A file-backed container secret is mounted directly beneath the
        # container's accessible /run/secrets directory, not through the
        # protected host directory. Emulate that mounted view in this temp path.
        os.chmod(target.parent, 0o755)
        # The GitHub workspace may not be traversable by TEST_UID. Copy only
        # the non-secret verifier source into an isolated temporary directory
        # that the child can read; never chmod the workspace or add it to the
        # child's import path. TemporaryDirectory removes the copy even when
        # setup or the subprocess fails.
        with tempfile.TemporaryDirectory(
            prefix="shattab-secret-child-", dir=target.parent
        ) as child_import_directory:
            child_directory = Path(child_import_directory)
            module_path = child_directory / "create_api_secret.py"
            shutil.copyfile(STAGE / "create_api_secret.py", module_path)
            os.chmod(module_path, 0o444)
            os.chmod(child_directory, 0o755)

            program = (
                "import sys; "
                "sys.dont_write_bytecode = True; "
                "sys.path.insert(0, sys.argv[2]); "
                "from pathlib import Path; "
                "from create_api_secret import verify_secret_for_current_process; "
                "verify_secret_for_current_process(Path(sys.argv[1])); "
                "print('PASS')"
            )

            def drop_privileges() -> None:
                os.setgroups([TEST_GID])
                os.setgid(TEST_GID)
                os.setegid(TEST_EGID)
                os.setuid(TEST_UID)

            return subprocess.run(
                [sys.executable, "-c", program, str(target), str(child_directory)],
                cwd=child_directory,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
                timeout=10,
                preexec_fn=drop_privileges,
            )

    def _create(self) -> None:
        self._create_target(self.target)

    def _create_target(self, target: Path) -> None:
        create_secret_file(
            target,
            FIXTURE_PASSWORD,
            node_uid=TEST_UID,
            node_gid=TEST_GID,
            owner_uid=0,
        )

    def _create_verifier_fixture(self, label: str) -> tuple[Path, Path, Path]:
        stage = self.directory / f"{label}-stage"
        stage.mkdir(mode=0o700)
        os.chown(stage, TEST_UID, TEST_GID)
        os.chmod(stage, 0o700)

        secrets_directory = stage / "secrets"
        secrets_directory.mkdir(mode=0o700)
        os.chown(secrets_directory, 0, 0)
        os.chmod(secrets_directory, 0o700)

        secret_file = secrets_directory / "postgres_password"
        secret_file.write_bytes(BOOTSTRAP_VERIFIER_FIXTURE)
        os.chown(secret_file, TEST_UID, TEST_GID)
        os.chmod(secret_file, 0o600)
        return stage, secrets_directory, secret_file

    def _check_verifier_fixture(self, stage: Path) -> None:
        secrets_directory = stage / "secrets"
        secret_file = secrets_directory / "postgres_password"
        with mock.patch.multiple(
            stage_verifier,
            ROOT=stage,
            SECRET_DIR=secrets_directory,
            SECRET_FILE=secret_file,
        ):
            # The verifier reads only this temporary dummy fixture. Never
            # inspect, print, or return its bytes from the test.
            stage_verifier.check_secret_file()

    def test_0440_root_group_read_file_passes_as_non_root_process(self) -> None:
        self._create()
        info = os.lstat(self.target)
        self.assertTrue(stat.S_ISREG(info.st_mode))
        self.assertEqual(info.st_uid, 0)
        self.assertEqual(info.st_gid, TEST_GID)
        self.assertEqual(stat.S_IMODE(info.st_mode), 0o440)

        result = self._run_as_node(self.target)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "PASS")
        self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), result.stdout + result.stderr)

    def test_child_import_directory_is_removed_when_subprocess_fails(self) -> None:
        self._create()
        failures: tuple[BaseException, ...] = (
            OSError("mocked child launch failure"),
            subprocess.TimeoutExpired("python", 10),
        )
        for failure in failures:
            with self.subTest(failure=type(failure).__name__):
                with mock.patch.object(subprocess, "run", side_effect=failure) as mocked_run:
                    with self.assertRaises(type(failure)):
                        self._run_as_node(self.target)

                child_directory = Path(mocked_run.call_args.kwargs["cwd"])
                self.assertFalse(child_directory.exists())
                self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), repr(mocked_run.call_args))

    def test_unsafe_modes_fail_the_exact_0440_predicate(self) -> None:
        for mode in (0o400, 0o444, 0o460, 0o640, 0o660):
            with self.subTest(mode=oct(mode)):
                if os.path.lexists(self.target):
                    os.unlink(self.target)
                descriptor = os.open(self.target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                try:
                    os.write(descriptor, FIXTURE_PASSWORD)
                    os.fchown(descriptor, 0, TEST_GID)
                    os.fchmod(descriptor, mode)
                finally:
                    os.close(descriptor)

                result = self._run_as_node(self.target)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), result.stdout + result.stderr)

    def test_non_root_file_owner_fails_even_if_group_readable(self) -> None:
        self._create()
        os.chown(self.target, TEST_UID, TEST_GID)
        os.chmod(self.target, 0o440)

        result = self._run_as_node(self.target)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), result.stdout + result.stderr)

    def test_existing_target_is_not_overwritten(self) -> None:
        self.target.write_bytes(b"existing-test-only-content")
        os.chmod(self.target, 0o600)

        with self.assertRaises(SecretAlreadyExists) as raised:
            self._create()

        self.assertEqual(self.target.read_bytes(), b"existing-test-only-content")
        self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), str(raised.exception))

    def test_non_root_secret_directory_is_rejected(self) -> None:
        # Root can still change ownership for the fixture; reject before any
        # password file or temporary file is created.
        os.chown(self.directory, TEST_UID, TEST_GID)
        with self.assertRaises(SecretProvisionError) as raised:
            self._create()

        self.assertIn("owned by root", str(raised.exception))
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_root_secret_directory_with_unsafe_mode_is_rejected(self) -> None:
        os.chmod(self.directory, 0o750)

        with self.assertRaises(SecretProvisionError) as raised:
            self._create()

        self.assertIn("mode 0700", str(raised.exception))
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_verifier_rejects_non_regular_secret_types(self) -> None:
        source = self.directory / "non-secret-fixture"
        source.write_bytes(b"non-secret fixture")

        for kind in ("symlink", "fifo", "directory"):
            with self.subTest(kind=kind):
                target = self.directory / kind
                if kind == "symlink":
                    target.symlink_to(source)
                elif kind == "fifo":
                    os.mkfifo(target, 0o440)
                    os.chown(target, 0, TEST_GID)
                else:
                    target.mkdir(mode=0o700)
                    os.chown(target, 0, TEST_GID)
                    os.chmod(target, 0o440)

                result = self._run_as_node(target)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), result.stdout + result.stderr)

    def test_bootstrap_and_api_secret_keep_the_valid_split_ownership(self) -> None:
        stage = self.directory / "stage"
        stage.mkdir(mode=0o700)
        os.chown(stage, TEST_UID, TEST_GID)
        os.chmod(stage, 0o700)

        with mock.patch.object(secret_helper, "STAGE_ROOT", stage):
            secret_helper._bootstrap_postgres_password()

        secrets_directory = stage / "secrets"
        secret_directory_stat = os.lstat(secrets_directory)
        self.assertTrue(stat.S_ISDIR(secret_directory_stat.st_mode))
        self.assertEqual(secret_directory_stat.st_uid, 0)
        self.assertEqual(secret_directory_stat.st_gid, 0)
        self.assertEqual(stat.S_IMODE(secret_directory_stat.st_mode), 0o700)

        bootstrap = secrets_directory / "postgres_password"
        bootstrap_stat = os.lstat(bootstrap)
        self.assertTrue(stat.S_ISREG(bootstrap_stat.st_mode))
        self.assertEqual(bootstrap_stat.st_uid, TEST_UID)
        self.assertEqual(bootstrap_stat.st_gid, TEST_GID)
        self.assertEqual(stat.S_IMODE(bootstrap_stat.st_mode), 0o600)

        api_secret = secrets_directory / "api_password"
        self._create_target(api_secret)
        api_stat = os.lstat(api_secret)
        self.assertTrue(stat.S_ISREG(api_stat.st_mode))
        self.assertEqual(api_stat.st_uid, 0)
        self.assertEqual(api_stat.st_gid, TEST_GID)
        self.assertEqual(stat.S_IMODE(api_stat.st_mode), 0o440)

    def test_symlink_secrets_ancestor_is_rejected_without_writing_through_it(self) -> None:
        stage = self.directory / "stage"
        stage.mkdir(mode=0o700)
        os.chown(stage, TEST_UID, TEST_GID)
        os.chmod(stage, 0o700)
        replacement = self.directory / "replacement"
        replacement.mkdir(mode=0o700)
        os.symlink(replacement, stage / "secrets")

        with mock.patch.object(secret_helper, "STAGE_ROOT", stage):
            with self.assertRaises(SecretProvisionError):
                secret_helper._bootstrap_postgres_password()

        self.assertTrue((stage / "secrets").is_symlink())
        self.assertEqual(list(replacement.iterdir()), [])

    def test_path_replacement_after_pin_keeps_creation_on_open_directory(self) -> None:
        secrets_directory = self.directory / "secrets"
        secrets_directory.mkdir(mode=0o700)
        original_directory_stat = os.stat(secrets_directory, follow_symlinks=False)
        pinned_directory = self.directory / "pinned-secrets-directory"
        replacement_directory = self.directory / "replacement-secrets-directory"
        replacement_directory.mkdir(mode=0o700)
        original_create = secret_helper._create_secret_at

        def replace_path_after_pin(
            directory_fd: int,
            target_name: str,
            password: bytes,
            **kwargs: int,
        ) -> None:
            opened_directory_stat = os.fstat(directory_fd)
            self.assertEqual(opened_directory_stat.st_dev, original_directory_stat.st_dev)
            self.assertEqual(opened_directory_stat.st_ino, original_directory_stat.st_ino)
            os.rename(secrets_directory, pinned_directory)
            os.symlink(replacement_directory, secrets_directory, target_is_directory=True)
            original_create(directory_fd, target_name, password, **kwargs)

        with mock.patch.object(
            secret_helper,
            "_create_secret_at",
            side_effect=replace_path_after_pin,
        ):
            self._create_target(secrets_directory / "api_password")

        pinned_secret = pinned_directory / "api_password"
        self.assertTrue(pinned_secret.is_file())
        self.assertTrue(secrets_directory.is_symlink())
        self.assertFalse((replacement_directory / "api_password").exists())
        self.assertEqual(os.lstat(pinned_secret).st_uid, 0)
        self.assertEqual(os.lstat(pinned_secret).st_gid, TEST_GID)
        self.assertEqual(stat.S_IMODE(os.lstat(pinned_secret).st_mode), 0o440)

    def test_target_created_after_absence_check_is_not_overwritten(self) -> None:
        competing_contents = b"safe competing fixture"
        original_link = os.link

        def competing_link(
            source: str,
            target: str,
            *,
            src_dir_fd: int,
            dst_dir_fd: int,
            follow_symlinks: bool,
        ) -> None:
            descriptor = os.open(
                target,
                os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                0o600,
                dir_fd=dst_dir_fd,
            )
            try:
                os.write(descriptor, competing_contents)
            finally:
                os.close(descriptor)
            original_link(
                source,
                target,
                src_dir_fd=src_dir_fd,
                dst_dir_fd=dst_dir_fd,
                follow_symlinks=follow_symlinks,
            )

        with mock.patch.object(secret_helper.os, "link", side_effect=competing_link) as patched_link:
            supported_dir_fd = set(os.supports_dir_fd)
            supported_dir_fd.discard(original_link)
            supported_dir_fd.add(patched_link)
            supported_follow_symlinks = set(os.supports_follow_symlinks)
            supported_follow_symlinks.discard(original_link)
            supported_follow_symlinks.add(patched_link)
            with (
                mock.patch.object(os, "supports_dir_fd", supported_dir_fd),
                mock.patch.object(os, "supports_follow_symlinks", supported_follow_symlinks),
            ):
                with self.assertRaises(SecretAlreadyExists):
                    self._create()

        self.assertEqual(self.target.read_bytes(), competing_contents)
        self.assertEqual([entry.name for entry in self.directory.iterdir()], ["api_password"])
        self.assertEqual(patched_link.call_count, 1)

    def test_write_failure_cleans_temporary_file_and_redacts_error(self) -> None:
        with mock.patch("create_api_secret.os.write", side_effect=OSError("secret-value-must-not-appear")):
            with self.assertRaises(SecretProvisionError) as raised:
                self._create()

        self.assertFalse(os.path.lexists(self.target))
        self.assertEqual(list(self.directory.iterdir()), [])
        self.assertNotIn("secret-value-must-not-appear", str(raised.exception))
        self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), str(raised.exception))

    def test_unlink_failure_reports_possible_temp_file_and_redacts_error(self) -> None:
        unlink_error = "secret-value-must-not-appear-in-unlink-error"
        with mock.patch(
            "create_api_secret.os.unlink",
            side_effect=PermissionError(unlink_error),
        ) as mocked_unlink:
            with self.assertRaises(SecretProvisionError) as raised:
                self._create()

        message = str(raised.exception)
        self.assertIn("temporary file may remain", message)
        self.assertIn("inspect both paths manually", message)
        self.assertNotIn(unlink_error, message)
        self.assertNotIn(FIXTURE_PASSWORD.decode("ascii"), message)
        self.assertEqual(mocked_unlink.call_count, 2)
        entries = list(self.directory.iterdir())
        temporary = [path for path in entries if path != self.target]
        self.assertTrue(self.target.is_file())
        self.assertEqual(len(temporary), 1)
        self.assertEqual(os.lstat(self.target).st_ino, os.lstat(temporary[0]).st_ino)

    def test_verifier_accepts_a_temporary_bootstrap_postgres_secret(self) -> None:
        stage, _, _ = self._create_verifier_fixture("verify-valid")

        self._check_verifier_fixture(stage)

    def test_verifier_rejects_bootstrap_secret_owner_and_mode_mismatches(self) -> None:
        stage, _, secret_file = self._create_verifier_fixture("verify-owner")
        stage_uid = os.stat(stage).st_uid
        os.chown(secret_file, TEST_UID + 1, TEST_GID)
        self.assertNotEqual(os.stat(secret_file).st_uid, stage_uid)

        with self.assertRaises(stage_verifier.VerificationError) as owner_error:
            self._check_verifier_fixture(stage)

        self.assertIn("owner must match", str(owner_error.exception))

        stage, _, secret_file = self._create_verifier_fixture("verify-mode")
        os.chmod(secret_file, 0o640)

        with self.assertRaises(stage_verifier.VerificationError) as mode_error:
            self._check_verifier_fixture(stage)

        self.assertIn("mode 0600", str(mode_error.exception))

    def test_verifier_rejects_bootstrap_secrets_directory_owner_and_mode(self) -> None:
        stage, secrets_directory, _ = self._create_verifier_fixture("verify-dir-owner")
        os.chown(secrets_directory, TEST_UID, TEST_GID)

        with self.assertRaises(stage_verifier.VerificationError) as owner_error:
            self._check_verifier_fixture(stage)

        self.assertIn("secrets directory must be owned by root", str(owner_error.exception))

        stage, secrets_directory, _ = self._create_verifier_fixture("verify-dir-mode")
        os.chmod(secrets_directory, 0o750)

        with self.assertRaises(stage_verifier.VerificationError) as mode_error:
            self._check_verifier_fixture(stage)

        self.assertIn("secrets directory must have mode 0700", str(mode_error.exception))

    def test_verifier_rejects_symlink_fifo_and_directory_as_bootstrap_secret(self) -> None:
        for kind in ("symlink", "fifo", "directory"):
            with self.subTest(kind=kind):
                stage, _, secret_file = self._create_verifier_fixture(f"verify-type-{kind}")
                secret_file.unlink()

                if kind == "symlink":
                    source = self.directory / "verify-symlink-source"
                    source.write_bytes(b"non-secret symlink fixture")
                    os.chown(source, 0, 0)
                    os.chmod(source, 0o600)
                    secret_file.symlink_to(source)
                elif kind == "fifo":
                    os.mkfifo(secret_file, 0o600)
                    os.chown(secret_file, 0, 0)
                else:
                    secret_file.mkdir(mode=0o700)
                    os.chown(secret_file, 0, 0)

                with self.assertRaises(stage_verifier.VerificationError) as raised:
                    self._check_verifier_fixture(stage)

                self.assertNotIn(BOOTSTRAP_VERIFIER_FIXTURE.decode("ascii"), str(raised.exception))

    def test_verifier_rejects_symlink_secrets_directory(self) -> None:
        stage, secrets_directory, _ = self._create_verifier_fixture("verify-symlink-dir")
        secret_file = secrets_directory / "postgres_password"
        secret_file.unlink()
        secrets_directory.rmdir()
        replacement = self.directory / "verify-secrets-replacement"
        replacement.mkdir(mode=0o700)
        os.chown(replacement, 0, 0)
        os.symlink(replacement, secrets_directory, target_is_directory=True)

        with self.assertRaises(stage_verifier.VerificationError):
            self._check_verifier_fixture(stage)

        self.assertTrue(secrets_directory.is_symlink())
        self.assertEqual(list(replacement.iterdir()), [])

    def test_verifier_uses_pinned_secrets_directory_after_path_replacement(self) -> None:
        stage, secrets_directory, _ = self._create_verifier_fixture("verify-pinned-dir")
        pinned_directory = self.directory / "verify-pinned-secrets"
        replacement = self.directory / "verify-pinned-replacement"
        replacement.mkdir(mode=0o700)
        os.chown(replacement, 0, 0)
        original_open_child = stage_verifier._open_child_directory

        def replace_after_pin(parent_fd: int, name: str, *, label: str) -> int:
            descriptor = original_open_child(parent_fd, name, label=label)
            self.assertEqual(name, "secrets")
            os.rename(secrets_directory, pinned_directory)
            os.symlink(replacement, secrets_directory, target_is_directory=True)
            return descriptor

        with mock.patch.multiple(
            stage_verifier,
            ROOT=stage,
            SECRET_DIR=secrets_directory,
            SECRET_FILE=secrets_directory / "postgres_password",
        ):
            with mock.patch.object(
                stage_verifier,
                "_open_child_directory",
                side_effect=replace_after_pin,
            ):
                stage_verifier.check_secret_file()

        self.assertTrue((pinned_directory / "postgres_password").is_file())
        self.assertTrue(secrets_directory.is_symlink())
        self.assertEqual(list(replacement.iterdir()), [])

    def test_cli_without_controlling_tty_does_not_read_or_echo_stdin(self) -> None:
        marker = "temporary-input-that-must-not-be-read-or-echoed"
        result = subprocess.run(
            [
                sys.executable,
                str(STAGE / "create_api_secret.py"),
                "--node-uid",
                str(TEST_UID),
                "--node-gid",
                str(TEST_GID),
            ],
            input=marker,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
            timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(marker, result.stdout + result.stderr)
        self.assertEqual(list(self.directory.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
