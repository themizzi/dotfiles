export HOMEBREW_CASK_OPTS="--appdir=/Applications"

if test ! $(which brew); then
  echo "Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Taps
brew tap homebrew/dupes
brew tap homebrew/php
brew tap telemachus/desc
brew tap caskroom/versions

# Update
brew update

# Packages
brew install bash
brew install bash-completion
brew install zsh
brew install coreutils
brew install findutils
brew install htop-osx
brew install php70
brew install php70-intl
brew install php70-mcrypt
brew install php70-xdebug
brew install composer
brew install sqlite
brew install wget
brew install clamav
brew install mysql
brew install git
brew install nano
brew install z

# Casks
brew tap caskroom/cask
brew cask install caffeine
brew cask install cyberduck
brew cask install id3-editor
brew cask install phpstorm
brew cask install sublime-text3
brew cask install atom
brew cask install chromium
brew cask install gimp
brew cask install transmission
brew cask install vlc
brew cask install firefox
brew cask install hipchat
brew cask install spotify
brew cask install vagrant-manager
brew cask install virtualbox
brew cask install vagrant
brew cask install sourcetree

# Cleanup
brew cleanup -s
brew cask cleanup
