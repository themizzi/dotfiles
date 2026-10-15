#!/bin/sh
# Syntax checks only: never source configuration or import repository modules.
set -eu

for executable in sh bash zsh python3 git; do
    if ! command -v "$executable" >/dev/null 2>&1; then
        echo "check: required executable not found in PATH: $executable" >&2
        exit 1
    fi
done

cd "$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
python3 -B - <<'PY'
import ast
import json
import os
from pathlib import Path
import subprocess
import sys
import tokenize

# Include new, unignored files as well as tracked files; do not enter submodules,
# virtual environments, or ignored plugin/vendor trees. NULs preserve spaces.
result = subprocess.run(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
    check=True, stdout=subprocess.PIPE,
)
failed = False
checked = 0
for name in sorted(set(result.stdout.split(b"\0")) - {b""}):
    path = Path(os.fsdecode(name))
    if not path.is_file():
        continue
    try:
        if path.suffix == ".sh":
            with path.open(encoding="utf-8") as source:
                first_line = source.readline()
            shell = "bash" if "bash" in first_line else "sh"
            subprocess.run([shell, "-n", str(path)], check=True)
        elif path.suffix == ".zsh" or path.name in (".zshrc", ".zshenv", ".zprofile", ".zlogin", ".zlogout"):
            subprocess.run(["zsh", "-f", "-n", str(path)], check=True)
        elif path.suffix == ".json":
            with path.open(encoding="utf-8") as source:
                json.load(source)
        elif path.suffix == ".py":
            with tokenize.open(path) as source:
                ast.parse(source.read(), filename=str(path))
        else:
            continue
        checked += 1
    except (OSError, ValueError, SyntaxError, subprocess.CalledProcessError) as error:
        print(f"check: {path}: {error}", file=sys.stderr)
        failed = True
if failed:
    sys.exit(1)
print(f"check: syntax OK ({checked} files)")
PY
