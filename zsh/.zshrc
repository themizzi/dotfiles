# Make zsh directory
mkdir -p ~/.zsh

# Homebrew
test -d /usr/local/bin/brew && eval $(/usr/local/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
test -d /opt/homebrew/bin && eval $(/opt/homebrew/bin/brew shellenv)

# ZSH History
HISTFILE=~/.zsh/history

# Initialize completions
autoload -Uz compinit && compinit

# Completion menu configuration with highlighting
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:*:*:*' list-colors '=(#b) #([0-9]#)*=0=01;32'

# Antidote
if [[ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
elif [[ -f /usr/local/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /usr/local/opt/antidote/share/antidote/antidote.zsh
elif [[ -f /home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh
fi

# Initialize antidote and load plugins
antidote load

# zsh-history-substring-search configuration
bindkey '^[[A' history-substring-search-up # or '\eOA'
bindkey '^[[B' history-substring-search-down # or '\eOB'
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Starship Prompt
eval "$(starship init zsh)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# TMUX
export TMUX_CONF="$XDG_CONFIG_HOME/tmux/tmux.conf"
alias tmux='tmux -f "$TMUX_CONF"'

# NANO
export NANORC="$XDG_CONFIG_HOME/nano/nanorc"

# GO
export PATH=~/go/bin:$PATH

# HUGO
type hugo &> /dev/null && source <(hugo completion zsh)
