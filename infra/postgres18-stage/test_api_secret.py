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
        create_secret_file(
            self.target,
            FIXTURE_PASSWORD,
            node_uid=TEST_UID,
            node_gid=TEST_GID,
            owner_uid=0,
        )

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
