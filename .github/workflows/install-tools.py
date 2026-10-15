"""CI-only release installer. Digests are pinned from GitHub release asset metadata."""
import hashlib
import io
import os
from pathlib import Path
import platform
import tarfile
import urllib.request
import zipfile


# neovim/neovim v0.11.5 and casey/just 1.43.1, not moving stable/latest URLs.
RELEASES = {
    ("Linux", "x86_64"): (
        "linux-x86_64", "b2f91117be5b5ea39edd7297156dc2a4a8df4add6c95a90809a8df19e7ab6f52",
        "x86_64-unknown-linux-musl", "6a3003f68fa4d86ada8afe33830a88ffdb6c2fcaff4e5a840b1cb90eaf6f46fc",
    ),
    ("Darwin", "arm64"): (
        "macos-arm64", "79143d3b408f7034f90b7cf59af2276de09ef8a4c2f1a28e4c99581b249d3107",
        "aarch64-apple-darwin", "96f4338e06966443b60666620ab3da0c2c6105ca1302275839c0f57fcbfa99d6",
    ),
    ("Darwin", "x86_64"): (
        "macos-x86_64", "6612760a7037ca2518e456908baf5e43101fa79819d18979fc4d4e8441d9dfa5",
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
    extract(f"https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-{nvim}.tar.gz",
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
