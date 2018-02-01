export HOMEBREW_CASK_OPTS="--appdir=/Applications"

echo "  Installing Homebrew for you."
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Taps
brew tap homebrew/php
brew tap telemachus/desc
brew tap caskroom/versions
brew tap buo/cask-upgrade

# Update
brew update

# Packages
brew install bash
brew install bash-completion
brew install zsh
brew install coreutils
brew install findutils
brew install htop-osx
brew install php71
brew install php71-intl
brew install php71-mcrypt
brew install php71-xdebug
brew install php71-apcu
brew install php71-apcu-bc
brew install composer
brew install sqlite
brew install wget
brew install mysql
brew install git
brew install nano
brew install z
brew install grc
brew install mas
brew install node

# Casks
brew tap caskroom/cask
brew cask install caffeine
brew cask install phpstorm
brew cask install atom
brew cask install gimp
brew cask install transmission
brew cask install firefox
brew cask install google-chrome
brew cask install spotify
brew cask install postman
brew cask install slack

# github
brew cask install java
brew install git-credential-manager

# Cleanup
brew cleanup -s
brew cask cleanup
