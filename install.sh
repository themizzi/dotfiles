set -e

# Homebrew

## Install
command -v brew 1> /dev/null || echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
test -d /usr/local/bin/brew && eval $(/usr/local/bin/brew shellenv) # Darwin
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) # Linux

## Setup Linux
if command -v apt 1> /dev/null && ! apt list --installed 2> /dev/null | grep -q build-essential; then
  sudo apt update
  sudo apt install build-essential -y
fi

## Bundle
brew bundle

# Dotfiles

ln -sf $(pwd)/.tmux.conf ${HOME}/.tmux.conf
ln -sf $(pwd)/.nanorc ${HOME}/.nanorc
ln -sf $(pwd)/.zshrc ${HOME}/.zshrc

# Nano
ln -sf $(brew --prefix nanorc)/share/nanorc ${HOME}/.nanorc.d
