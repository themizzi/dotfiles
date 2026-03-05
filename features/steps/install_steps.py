from __future__ import annotations

import subprocess
from pathlib import Path

from behave import given, then, when

from features.environment import make_install_env, require_executable


@given("a temporary HOME for install testing")
def step_temp_home_for_install(context):
    require_executable("stow")
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


@then('"{home_path}" should symlink to "{repo_rel}"')
def step_home_path_symlink_target(context, home_path, repo_rel):
    expanded = home_path.replace("~", str(context.install_home), 1)
    link_path = Path(expanded)
    assert link_path.is_symlink(), f"Expected symlink at {link_path}"

    target = link_path.resolve(strict=True)
    expected = (context.repo_root / repo_rel).resolve(strict=True)
    assert target == expected, f"Expected {link_path} -> {expected}, got {target}"
