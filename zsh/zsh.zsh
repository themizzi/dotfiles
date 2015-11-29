autoload -U compinit && compinit
zmodload -i zsh/complist
zstyle ':completion:*' menu select
source $DOTFILES_PATH/lib/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
