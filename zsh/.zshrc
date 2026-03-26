# Make zsh directory
mkdir -p ~/.zsh

# Homebrew
test -d /usr/local/bin/brew && eval $(/usr/local/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
test -d /opt/homebrew/bin && eval $(/opt/homebrew/bin/brew shellenv)

# ZSH History
HISTFILE=~/.zsh/history

export PATH="$HOME/.local/bin:$PATH"

# Completion system
autoload -Uz compinit
if ! (( $+functions[compdef] )); then
  compinit
fi

source $HOME/.antidote/antidote.zsh
if command -v antidote >/dev/null 2>&1; then
  antidote load "$HOME/.zsh_plugins.txt"
fi

# zsh-history-substring-search configuration
if (( $+widgets[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up # or '\eOA'
  bindkey '^[[B' history-substring-search-down # or '\eOB'
fi
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Starship Prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# TMUX
export TMUX_CONF="$XDG_CONFIG_HOME/tmux/tmux.conf"
alias tmux='tmux -f "$TMUX_CONF"'
alias zj='zellij'

# NANO
export NANORC="$XDG_CONFIG_HOME/nano/nanorc"

# GO
export PATH=~/go/bin:$PATH

# HUGO
type hugo &> /dev/null && source <(hugo completion zsh)
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# ANDROID
export PATH="/opt/homebrew/share/android-commandlinetools/platform-tools:$PATH"

# Rust / Cargo
export PATH="$HOME/.cargo/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/themizzi/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
