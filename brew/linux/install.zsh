echo "  Installing Homebrew for you."
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"

brew install grc
brew install z
brew cleanup -e
