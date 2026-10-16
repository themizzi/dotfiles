# Login and non-login interactive shells share executable discovery.
[[ -r "$HOME/.zsh/environment.zsh" ]] && source "$HOME/.zsh/environment.zsh"

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=10000
if [[ ! -d "${HISTFILE:h}" ]]; then
  (umask 077; mkdir -p -- "${HISTFILE:h}")
fi
setopt APPEND_HISTORY INC_APPEND_HISTORY HIST_IGNORE_DUPS HIST_REDUCE_BLANKS

# Prepare completion directories before the one compinit call below.
typeset -U fpath
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
if [[ -n ${HOMEBREW_PREFIX:-} && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

# The checked-out submodule is canonical. Never clone or fetch at startup.
if [[ -r "$HOME/.antidote/antidote.zsh" ]]; then
  source "$HOME/.antidote/antidote.zsh"
elif [[ -n ${DOTFILES_ANTIDOTE_HOMEBREW_PATH+x} ]]; then
  [[ -r "$DOTFILES_ANTIDOTE_HOMEBREW_PATH" ]] && source "$DOTFILES_ANTIDOTE_HOMEBREW_PATH"
elif [[ -n ${HOMEBREW_PREFIX:-} && -r "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]]; then
  source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
fi

# Generate a bundle explicitly, then restart the shell to use it.
dotfiles-plugins-update() {
  if (( ! $+functions[antidote] )); then
    print -u2 'Antidote is unavailable; initialize the zsh/.antidote submodule first.'
    return 1
  fi
  local bundle="$XDG_CACHE_HOME/zsh/plugins.zsh" temporary
  (umask 077; mkdir -p -- "${bundle:h}") || return
  temporary=$(mktemp "${bundle}.XXXXXXXX") || return
  if antidote bundle < "$HOME/.zsh_plugins.txt" > "$temporary"; then
    command mv -f -- "$temporary" "$bundle"
  else
    command rm -f -- "$temporary"
    return 1
  fi
}

# Plugins may register completions while also extending fpath. Queue those
# registrations until compinit has seen every plugin's completion directory.
typeset -a _dotfiles_compdefs=()
typeset _dotfiles_needs_compinit=0
if (( ! $+functions[compdef] )); then
  _dotfiles_needs_compinit=1
  compdef() { _dotfiles_compdefs+=("${(j: :)${(q)@}}") }
fi
[[ -r "$XDG_CACHE_HOME/zsh/plugins.zsh" ]] && source "$XDG_CACHE_HOME/zsh/plugins.zsh"
autoload -Uz compinit
if (( _dotfiles_needs_compinit )); then
  unfunction compdef
  # Do not bypass compinit's security checks for completion directories.
  (umask 077; mkdir -p -- "$XDG_CACHE_HOME/zsh")
  compinit -i -d "$XDG_CACHE_HOME/zsh/zcompdump"
fi
for _dotfiles_compdef in "${_dotfiles_compdefs[@]}"; do
  eval "compdef $_dotfiles_compdef"
done
unset _dotfiles_compdef _dotfiles_compdefs _dotfiles_needs_compinit

if (( $+widgets[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
elif [[ -n ${HOMEBREW_PREFIX:-} && -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
  source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
fi

(( $+commands[hugo] )) && source <(hugo completion zsh)
if [[ ${TERM:-dumb} != dumb ]] && (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Private, untracked machine-specific settings; see docs/zsh.md.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
