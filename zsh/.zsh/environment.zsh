# Shared by .zprofile and .zshrc, once per shell (not inherited by children).
[[ -n ${_DOTFILES_ENV_READY:-} ]] && return
typeset -g _DOTFILES_ENV_READY=1
typeset -U path

# Prefer an already selected executable, then ARM macOS, Intel macOS, Linux.
typeset _dotfiles_brew=${commands[brew]:-} _dotfiles_dir
if [[ ! -x "$_dotfiles_brew" ]]; then
  for _dotfiles_brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -x "$_dotfiles_brew" && ! -d "$_dotfiles_brew" ]] && break
  done
fi
if [[ -x "$_dotfiles_brew" && ! -d "$_dotfiles_brew" ]]; then
  eval "$("$_dotfiles_brew" shellenv)"
fi

# Never introduce dead directories or duplicate PATH entries.
for _dotfiles_dir in "$HOME/.local/bin" "${GOPATH:-$HOME/go}/bin" "$HOME/.cargo/bin" "$HOME/.lmstudio/bin"; do
  [[ -d "$_dotfiles_dir" ]] && path=("$_dotfiles_dir" $path)
done
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  for _dotfiles_dir in "$HOMEBREW_PREFIX/opt/rustup/bin" "$HOMEBREW_PREFIX/share/android-commandlinetools/platform-tools"; do
    [[ -d "$_dotfiles_dir" ]] && path=("$_dotfiles_dir" $path)
  done
fi
if [[ -z ${EDITOR:-} ]]; then
  if (( $+commands[nvim] )); then
    export EDITOR=nvim
  elif (( $+commands[vim] )); then
    export EDITOR=vim
  elif (( $+commands[nano] )); then
    export EDITOR=nano
  else
    export EDITOR=vi
  fi
fi
export VISUAL="${VISUAL:-$EDITOR}"
unset _dotfiles_brew _dotfiles_dir
