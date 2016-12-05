if test ! $(which brew); then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
fi

brew install grc
brew install z
brew cleanup -e
