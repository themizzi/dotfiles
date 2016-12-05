autoload -U compinit && compinit
zmodload -i zsh/complist
zstyle ':completion:*' menu select
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
