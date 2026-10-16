FROM mcr.microsoft.com/devcontainers/base:debian-13

COPY scripts/packages.sh /tmp/dotfiles-dependencies/scripts/packages.sh
COPY packages/ /tmp/dotfiles-dependencies/packages/
RUN DEBIAN_FRONTEND=noninteractive bash /tmp/dotfiles-dependencies/scripts/packages.sh --install --profile dev \
    && rm -rf /var/lib/apt/lists/*

RUN if id -u vscode >/dev/null 2>&1; then chsh -s /usr/bin/zsh vscode; fi
