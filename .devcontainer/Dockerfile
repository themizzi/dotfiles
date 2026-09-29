FROM mcr.microsoft.com/devcontainers/base:debian

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        fd-find \
        fzf \
        git \
        neovim \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        unzip \
        wget \
        zellij \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin

RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

RUN if id -u vscode >/dev/null 2>&1; then chsh -s /usr/bin/zsh vscode; fi
