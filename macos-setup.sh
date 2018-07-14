#!/usr/bin/env bash
DIR=`cd $(dirname $0); pwd`
pushd $DIR

# download iTerm2
if ! [ -d "/Applications/iTerm.app" ]; then
    pushd $HOME/Downloads
    curl -L -s -o iTerm.zip https://iterm2.com/downloads/stable/latest
    unzip iTerm.zip
    mv iTerm.app /Applications
    popd
fi

# install brew
which brew > /dev/null
if [ $? -eq 1 ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    brew update
fi
brew install coreutils git python direnv byobu vim fish

# enable direnv
direnv allow

# install powerline fonts
export PATH="/usr/local/opt/python/libexec/bin:${PATH}"
pip install --user powerline-status

pushd /tmp
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -fr fonts
popd

# setup fish
curl -L https://get.oh-my.fish | fish
grep -sq fish /etc/shells
if [ $? -eq 1 ]; then
    sudo sh -c "echo /usr/local/bin/fish >> /etc/shells"
fi

# install .dotfiles
if ! [ -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/talesin/dotfiles.git $HOME/.dotfiles
fi
pushd $HOME/.dotfiles
./install
popd

# setup byobu
/usr/local/bin/byobu-enable

popd

chsh -s /usr/local/bin/fish