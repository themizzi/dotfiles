#!/bin/sh
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Check for Homebrew
if is_mac; then
  if test ! $(which brew); then
    echo "  Installing Homebrew for you."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # Install taps and formula
  brew tap caskroom/cask
  brew tap caskroom/versions
  brew tap homebrew/completions
  brew tap homebrew/php
  brew tap homebrew/dupes
  brew install bash bash-completion zsh tmux coreutils findutils htop-osx
  brew cleanup -s

  # Update ZSH completions
  rm -f ~/.zcompdump; compinit
fi


