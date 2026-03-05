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
        stow \
        unzip \
        wget \
        zellij \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin

RUN git clone --depth=1 https://github.com/mattmc3/antidote.git /home/vscode/.antidote \
    && chown -R vscode:vscode /home/vscode/.antidote

RUN if id -u vscode >/dev/null 2>&1; then chsh -s /usr/bin/zsh vscode; fi

RUN rm -f \
    /home/vscode/.config/gh/config.yml \
    /home/vscode/.stowrc-gh \
    /home/vscode/.config/gh-copilot/config.yml \
    /home/vscode/.muttrc \
    /home/vscode/.config/nano/nanorc \
    /home/vscode/.config/starship.toml \
    /home/vscode/.config/task/taskrc \
    /home/vscode/.config/tmux/tmux.conf \
    /home/vscode/.config/zellij/config.kdl \
    /home/vscode/.config/zellij/layouts/default.kdl \
    /home/vscode/.zsh_plugins.txt \
    /home/vscode/.zshenv \
    /home/vscode/.zshrc
