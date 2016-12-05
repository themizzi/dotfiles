antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search
# bind UP and DOWN arrow keys
zmodload zsh/terminfo
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
antigen bundle zsh-users/zsh-autosuggestions
bindkey '^ ' autosuggest-accept
