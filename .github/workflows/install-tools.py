"""CI-only release installer. Digests are pinned from GitHub release asset metadata."""
import hashlib
import io
import os
from pathlib import Path
import platform
import tarfile
import urllib.request
import zipfile


# neovim/neovim v0.12.3 and casey/just 1.43.1, not moving stable/latest URLs.
RELEASES = {
    ("Linux", "x86_64"): (
        "linux-x86_64", "c441b547142860bf01bcce39e36cbed185c41112813e15443b16e5237750724d",
        "x86_64-unknown-linux-musl", "6a3003f68fa4d86ada8afe33830a88ffdb6c2fcaff4e5a840b1cb90eaf6f46fc",
    ),
    ("Darwin", "arm64"): (
        "macos-arm64", "532da1d00e465a660fa01c3d4991333d09c52107dce7df937368545daca0a14e",
        "aarch64-apple-darwin", "96f4338e06966443b60666620ab3da0c2c6105ca1302275839c0f57fcbfa99d6",
    ),
    ("Darwin", "x86_64"): (
        "macos-x86_64", "4b40e318eb7073321fa5fc06d7f60c3c0de1d7ea50ffbaa8b04286f5484d294f",
        "x86_64-apple-darwin", "e41d03872e28636b9c4461229e4e83771d7b4a0ef2bb6596dfc1e5e393c7ebe0",
    ),
}

STYLUA = {
    ('Linux', 'x86_64'): ('linux-x86_64', 'a485f72bbfa22e4642e77a84b5edc2611a5cab7477b34e2e709dd8f78e919895'),
    ('Darwin', 'arm64'): ('macos-aarch64', 'dab9b66d340ca5ffc8225211f1dcf89b84783e09b8cbec8c518497eba81f3c42'),
    ('Darwin', 'x86_64'): ('macos-x86_64', '90779aa873837b2dff8eb3361bd27950303914c24265a59cae0a0d0629d71585'),
}


def extract(url, digest, destination):
    with urllib.request.urlopen(url, timeout=60) as response:
        archive = response.read()
    actual = hashlib.sha256(archive).hexdigest()
    if actual != digest:
        raise SystemExit(f"SHA256 mismatch: {url}: {actual} != {digest}")
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as source:
        source.extractall(destination, filter="data")


def main():
    nvim, nvim_hash, just, just_hash = RELEASES[(platform.system(), platform.machine())]
    destination = Path(os.environ["RUNNER_TEMP"]) / "dotfiles-tools"
    destination.mkdir(parents=True, exist_ok=True)
    extract(f"https://github.com/neovim/neovim/releases/download/v0.12.3/nvim-{nvim}.tar.gz",
            nvim_hash, destination)
    extract(f"https://github.com/casey/just/releases/download/1.43.1/just-1.43.1-{just}.tar.gz",
             just_hash, destination)
    target, digest = STYLUA[(platform.system(), platform.machine())]
    url = f'https://github.com/JohnnyMorganz/StyLua/releases/download/v2.6.0/stylua-{target}.zip'
    with urllib.request.urlopen(url, timeout=60) as response:
        archive = response.read()
    if hashlib.sha256(archive).hexdigest() != digest:
        raise SystemExit(f'SHA256 mismatch: {url}')
    with zipfile.ZipFile(io.BytesIO(archive)) as source:
        binary = destination / 'stylua'
        binary.write_bytes(source.read('stylua'))
        binary.chmod(0o755)
    with open(os.environ["GITHUB_PATH"], "a", encoding="utf-8") as paths:
        paths.write(f"{destination / ('nvim-' + nvim) / 'bin'}\n{destination}\n")


if __name__ == "__main__":
    main()
