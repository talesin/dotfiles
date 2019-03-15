#!/usr/bin/env bash
DIR=`cd $(dirname $0); pwd`
pushd /tmp

# download iTerm2
if ! [ -d "/Applications/iTerm.app" ]; then
    curl -L -s -o iTerm.zip https://iterm2.com/downloads/stable/latest
    unzip iTerm.zip
    mv iTerm.app /Applications
    
    curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
fi

# install brew
which brew > /dev/null
if [ $? -eq 1 ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update
brew bundle
brew cleanup

# enable direnv
direnv allow

# install powerline fonts
./setup-fonts.sh

# setup bash
./setup-bash.sh

# setup fish
./setup-fish.sh
chsh -s /usr/local/bin/fish

# install nvm
curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

# setup powershell
./setup-pwsh.sh
# chsh -s /usr/local/bin/pwsh

# install .dotfiles
./setup-dotfiles.sh

# setup byobu
/usr/local/bin/byobu-enable

popd
