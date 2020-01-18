export ANTIGEN_MUTEX=false
antigen bundle docker-compose
antigen bundle docker
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-history-substring-search
antigen apply

typeset -gA ZSH_HIGHLIGHT_STYLES
export ZSH_HIGHLIGHT_STYLES[comment]="fg=magenta,bold"
bindkey '^ ' autosuggest-accept
# bind UP and DOWN arrow keys
zmodload zsh/terminfo
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

