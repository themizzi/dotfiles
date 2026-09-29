from __future__ import annotations

import subprocess
from pathlib import Path

from behave import given, then, when

from features.environment import make_install_env, require_executable


@given("a temporary HOME for install testing")
def step_temp_home_for_install(context):
    require_executable("chezmoi")
    env, home_dir = make_install_env(context)
    context.install_env = env
    context.install_home = home_dir


@when("I run the dotfiles install script")
def step_run_install_script(context):
    result = subprocess.run(
        ["sh", "install.sh"],
        cwd=context.repo_root,
        env=context.install_env,
        capture_output=True,
        text=True,
        check=False,
    )
    context.install_last_result = result
    assert result.returncode == 0, (
        "install.sh failed\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )


@then('"{home_path}" should contain the contents of "{repo_rel}"')
def step_home_path_matches_source(context, home_path, repo_rel):
    expanded = home_path.replace("~", str(context.install_home), 1)
    installed = Path(expanded)
    expected = context.repo_root / repo_rel
    assert installed.is_file(), f"Expected managed file at {installed}"
    assert installed.read_bytes() == expected.read_bytes(), (
        f"Expected {installed} to match {expected}"
    )
