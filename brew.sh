# Taps
brew tap homebrew/dupes
brew tap homebrew/php
brew tap telemachus/desc

# Packages
brew install bash
brew install bash-completion
brew install zsh
brew install coreutils
brew install findutils
brew install tmux
brew install htop-osx
brew install python
brew install vim
brew install php56
brew install php56-mcrypt
brew install php56-xdebug
brew install composer
brew install sqlite
brew install wget
brew install clamav
brew install mysql
brew install sshfs
brew install git
brew install nano
brew install subversion

# Casks
brew tap caskroom/cask
brew install brew-cask
brew cask install adobe-air
brew cask install caffeine
brew cask install cyberduck
brew cask install flash-player
brew cask install id3-editor
brew cask install phpstorm
brew cask install sublime-text3
brew cask install airmail-beta
brew cask install chromium
brew cask install evernote
brew cask install gimp
brew cask install xquartz
brew cask install inkscape
brew cask install transmission
brew cask install vlc
brew cask install android-file-transfer
brew cask install clamxav
brew cask install feeds
brew cask install handbrake
brew cask install kindle
brew cask install spectacle
brew cask install appcleaner
brew cask install colloquy
brew cask install firefox
brew cask install hipchat
brew cask install owncloud
brew cask install spotify
brew cask install vienna

# These may require a password so let's do them at the end
brew cask install virtualbox
brew cask install vagrant

# Cleanup
brew cleanup -s
brew cask cleanup

# Update ZSH completions
rm -f ~/.zcompdump; compinit