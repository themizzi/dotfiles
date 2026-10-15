"""Environment hooks are testable without Behave, pynvim, or Neovim."""
import os
from pathlib import Path
import stat
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

from features import environment


class FakeContext(SimpleNamespace):
    def add_cleanup(self, callback, *args):
        self.cleanups.append((callback, args))

    def cleanup(self):
        for callback, args in reversed(self.cleanups):
            callback(*args)
        self.cleanups.clear()


class EnvironmentTests(unittest.TestCase):
    def setUp(self):
        self.context = FakeContext(cleanups=[])
        environment.before_all(self.context)
        self.original = os.environ.copy()
        self.addCleanup(self.assert_environment_restored)
        # unittest cleanups are LIFO: cleanup the hook before checking restoration.
        self.addCleanup(self.context.cleanup)

    def assert_environment_restored(self):
        self.assertEqual(dict(os.environ), self.original)

    def start(self):
        environment.before_scenario(self.context, None)
        return Path(os.environ["HOME"])

    def test_all_xdg_paths_are_private(self):
        home = self.start()
        self.assertNotEqual(str(home), self.original.get("HOME"))
        for name, value in os.environ.items():
            if name.startswith("XDG_") and name.endswith(("HOME", "DIR", "DIRS")):
                self.assertTrue(Path(value).is_relative_to(home), name)
                self.assertTrue(Path(value).is_dir(), name)
        self.assertEqual(stat.S_IMODE(Path(os.environ["XDG_RUNTIME_DIR"]).stat().st_mode), 0o700)
        self.assertTrue(Path(os.environ["TMPDIR"]).is_relative_to(home))

    def test_startup_overrides_are_removed_and_restored(self):
        poisoned = {name: "/host/do-not-source" for name in environment._STARTUP_OVERRIDES}
        with patch.dict(os.environ, poisoned):
            self.start()
            for name in poisoned:
                if name != "DOTFILES_SKIP_PLUGIN_BOOTSTRAP":
                    self.assertNotIn(name, os.environ)
            self.assertEqual(os.environ["DOTFILES_SKIP_PLUGIN_BOOTSTRAP"], "1")
            environment.after_scenario(self.context, None)
            for name, value in poisoned.items():
                self.assertEqual(os.environ[name], value)

    def test_preserves_path(self):
        self.start()
        self.assertEqual(os.environ.get("PATH"), self.original.get("PATH"))

    def test_unknown_inherited_xdg_paths_are_not_forwarded(self):
        with patch.dict(os.environ, {"XDG_CUSTOM_HOME": "/host/custom"}):
            self.start()
            self.assertNotIn("XDG_CUSTOM_HOME", os.environ)
            environment.after_scenario(self.context, None)
            self.assertEqual(os.environ["XDG_CUSTOM_HOME"], "/host/custom")

    def test_ai_settings_are_not_inherited(self):
        with patch.dict(os.environ, {'DOTFILES_NVIM_AI': '1',
                                     'DOTFILES_NVIM_AI_ENDPOINT': 'https://host.invalid',
                                     'DOTFILES_NVIM_AI_API_KEY': 'private'}):
            self.start()
            self.assertFalse(any(name.startswith('DOTFILES_NVIM_') for name in os.environ))
            environment.after_scenario(self.context, None)
            self.assertEqual(os.environ['DOTFILES_NVIM_AI_API_KEY'], 'private')

    def test_git_trust_is_scoped_to_checkout_and_drops_host_injections(self):
        with patch.dict(os.environ, {'GIT_CONFIG_COUNT': '1',
                                     'GIT_CONFIG_KEY_0': 'safe.directory',
                                     'GIT_CONFIG_VALUE_0': '*'}):
            home = self.start()
            self.assertNotIn('GIT_CONFIG_COUNT', os.environ)
            self.assertNotIn('GIT_CONFIG_VALUE_0', os.environ)
            config = (home / '.gitconfig').read_text()
            self.assertIn(str(self.context.repo_root.resolve()), config)
            self.assertNotIn('*', config)
            _, install_home = environment.make_install_env(self.context)
            self.assertEqual((install_home / '.gitconfig').read_text(), config)
            environment.after_scenario(self.context, None)
            self.assertEqual(os.environ['GIT_CONFIG_VALUE_0'], '*')

    def test_nvim_config_is_private_copy(self):
        self.start()
        env = environment.make_nvim_env(self.context)
        config = Path(env["XDG_CONFIG_HOME"]) / "nvim"
        self.assertTrue((config / "init.vim").is_file())
        self.assertFalse(config.is_symlink())
        (config / "test-only").write_text("private")
        self.assertFalse((self.context.repo_root / "nvim/.config/nvim/test-only").exists())
        vimrc = Path(env["HOME"]) / ".vimrc"
        self.assertFalse(vimrc.is_symlink())
        self.assertEqual(vimrc.read_text(), (self.context.repo_root / "vim/.vimrc").read_text())

    def test_install_environment_does_not_modify_parent_environment(self):
        self.start()
        parent = os.environ.copy()
        env, home = environment.make_install_env(self.context)
        self.assertEqual(dict(os.environ), parent)
        self.assertEqual(env["HOME"], str(home))
        self.assertTrue(Path(env["XDG_DATA_HOME"]).is_relative_to(home))

    def test_cleanup_removes_all_homes_and_closes_child(self):
        scenario_home = self.start()
        nvim_env = environment.make_nvim_env(self.context)
        _, install_home = environment.make_install_env(self.context)
        self.context.zsh_home_tmp = tempfile.TemporaryDirectory(dir=scenario_home)
        zsh_home = Path(self.context.zsh_home_tmp.name)
        child = self.context.nvim = Mock()
        environment.after_scenario(self.context, None)
        child.close.assert_called_once_with()
        child.request.assert_not_called()  # Never wait for a synchronous qa! RPC.
        self.assertIsNone(self.context.nvim)
        for home in (scenario_home, Path(nvim_env["HOME"]), install_home, zsh_home):
            self.assertFalse(home.exists())

    def test_failed_child_close_still_cleans_and_restores(self):
        home = self.start()
        self.context.nvim = Mock()
        self.context.nvim.close.side_effect = RuntimeError("broken transport")
        with self.assertRaisesRegex(RuntimeError, "broken transport"):
            environment.after_scenario(self.context, None)
        self.assertFalse(home.exists())
        self.assert_environment_restored()

    def test_registered_cleanup_handles_failed_scenario_hook(self):
        home = self.start()
        self.context.cleanup()  # Simulate Behave cleanup without after_scenario.
        self.assertFalse(home.exists())
        self.assert_environment_restored()

    def test_failed_temp_cleanup_does_not_prevent_other_cleanup(self):
        home = self.start()
        self.context.install_home_tmp = Mock()
        self.context.install_home_tmp.cleanup.side_effect = RuntimeError("cleanup failed")
        self.context.nvim_home_tmp = Mock()
        temporary = self.context.nvim_home_tmp
        with self.assertRaisesRegex(RuntimeError, "cleanup failed"):
            environment.after_scenario(self.context, None)
        temporary.cleanup.assert_called_once_with()
        self.assertFalse(home.exists())

    def test_cleanup_is_idempotent(self):
        self.start()
        environment.after_scenario(self.context, None)
        environment.after_scenario(self.context, None)
        self.context.cleanup()

    def test_repeated_home_creation_removes_previous_home(self):
        self.start()
        _, first = environment.make_install_env(self.context)
        _, second = environment.make_install_env(self.context)
        self.assertFalse(first.exists())
        self.assertTrue(second.is_dir())

    def test_cached_zsh_home_is_reset(self):
        self.context.zsh_test_home = Path("/stale-home")
        self.start()
        self.assertFalse(hasattr(self.context, "zsh_test_home"))

    def test_missing_executable_fails_explicitly(self):
        with patch.object(environment.shutil, "which", return_value=None):
            with self.assertRaisesRegex(AssertionError, "Required executable.*missing-tool"):
                environment.require_executable("missing-tool")

    def test_executable_resolution(self):
        with patch.object(environment.shutil, "which", return_value="/test/bin/nvim"):
            self.assertEqual(environment.require_executable("nvim"), "/test/bin/nvim")

    def test_reaps_child_without_rpc(self):
        with patch.object(environment.os, "waitpid", side_effect=[(0, 0), (123, 0)]), \
                patch.object(environment.os, "kill") as kill, \
                patch.object(environment.time, "sleep"):
            environment._reap_child(123)
        kill.assert_called_once_with(123, environment.signal.SIGKILL)

    def test_already_reaped_child_is_harmless(self):
        with patch.object(environment.os, "waitpid", side_effect=ChildProcessError), \
                patch.object(environment.os, "kill") as kill:
            environment._reap_child(123)
        kill.assert_not_called()

    def test_child_reaping_has_deadline(self):
        with patch.object(environment.os, "waitpid", return_value=(0, 0)), \
                patch.object(environment.os, "kill"), \
                patch.object(environment.time, "monotonic", side_effect=[0, 3]):
            with self.assertRaisesRegex(AssertionError, "did not exit within 2s"):
                environment._reap_child(123)

    def test_reaps_even_if_close_raises(self):
        child = self.context.nvim = Mock()
        child.close.side_effect = RuntimeError("broken close")
        with patch.object(environment, "_embedded_child_pid", return_value=123), \
                patch.object(environment, "_reap_child") as reap:
            with self.assertRaisesRegex(RuntimeError, "broken close"):
                environment._safe_close_nvim(self.context)
        reap.assert_called_once_with(123)


if __name__ == "__main__":
    unittest.main()
