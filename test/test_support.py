"""The editor test sandbox uses only standard-library APIs and explicit envs."""
import os
from pathlib import Path
import stat
import tempfile
import unittest
from unittest.mock import patch

from scripts.test_support import STARTUP_OVERRIDES, isolated_env, prepare_nvim_home


ROOT = Path(__file__).resolve().parents[1]


class SandboxTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='editor test home ')
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)

    def test_home_and_xdg_paths_are_private(self):
        env = isolated_env(self.home)
        self.assertEqual(env['HOME'], str(self.home))
        for name, value in env.items():
            if name.startswith('XDG_') or name in ('TMPDIR', 'TMP', 'TEMP'):
                self.assertTrue(Path(value).is_relative_to(self.home), name)
                self.assertTrue(Path(value).is_dir(), name)
        self.assertEqual(stat.S_IMODE(Path(env['XDG_RUNTIME_DIR']).stat().st_mode), 0o700)

    def test_preparing_a_child_does_not_change_parent_environment(self):
        before = os.environ.copy()
        env = prepare_nvim_home(ROOT, self.home)
        self.assertEqual(dict(os.environ), before)
        self.assertEqual(env.get('PATH'), before.get('PATH'))

    def test_host_startup_and_git_overrides_are_removed(self):
        poisoned = {name: '/host/do-not-read' for name in STARTUP_OVERRIDES}
        poisoned.update(XDG_UNKNOWN_HOME='/host/custom', NVIM_APPNAME='host-app',
                        GIT_CONFIG_COUNT='1', GIT_CONFIG_KEY_0='safe.directory',
                        GIT_CONFIG_VALUE_0='*')
        with patch.dict(os.environ, poisoned):
            env = isolated_env(self.home)
            for name in poisoned:
                self.assertNotIn(name, env)
            self.assertEqual(os.environ['GIT_CONFIG_VALUE_0'], '*')

    def test_ai_secrets_and_enable_flags_are_not_inherited(self):
        with patch.dict(os.environ, DOTFILES_NVIM_AI='1', DOTFILES_NVIM_AI_API_KEY='private',
                        DOTFILES_NVIM_MCP='1', DOTFILES_SKIP_PLUGIN_BOOTSTRAP='0'):
            env = isolated_env(self.home)
            self.assertFalse(any(name.startswith('DOTFILES_NVIM_') for name in env))
            self.assertEqual(env['DOTFILES_SKIP_PLUGIN_BOOTSTRAP'], '1')

    def test_git_configuration_is_private_and_has_no_wildcard_trust(self):
        env = isolated_env(self.home)
        self.assertEqual(env['GIT_CONFIG_GLOBAL'], str(self.home / '.gitconfig'))
        self.assertEqual(env['GIT_CONFIG_NOSYSTEM'], '1')
        self.assertFalse((self.home / '.gitconfig').exists())

    def test_editor_configuration_is_a_writable_copy_not_a_source_link(self):
        env = prepare_nvim_home(ROOT, self.home)
        config = Path(env['XDG_CONFIG_HOME']) / 'nvim'
        self.assertFalse(config.is_symlink())
        self.assertFalse((self.home / '.vimrc').is_symlink())
        self.assertEqual((config / 'init.vim').read_bytes(), (ROOT / 'nvim/.config/nvim/init.vim').read_bytes())
        self.assertEqual((self.home / '.vimrc').read_bytes(), (ROOT / 'vim/.vimrc').read_bytes())
        (config / 'test-only').write_text('private')
        self.assertFalse((ROOT / 'nvim/.config/nvim/test-only').exists())

    def test_preparing_home_does_not_bootstrap_plugins(self):
        env = prepare_nvim_home(ROOT, self.home)
        self.assertFalse((Path(env['XDG_DATA_HOME']) / 'nvim/lazy').exists())
