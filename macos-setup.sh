#!/usr/bin/env bash
DIR=`cd $(dirname $0)/..; pwd`
pushd $DIR

# install iTerm2
if ! [ -d "/Applications/iTerm.app" ]; then
   curl -o /Applications/iTerm.app  https://iterm2.com/downloads/stable/latest 
fi

# install brew
which brew > /dev/null
if [ $? -eq 0 ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    brew update
fi
brew install coreutils git python direnv byobu vim fish

# enable direnv
direnv allow

export PATH="/usr/local/opt/python/libexec/bin;${PATH}"

# install powerline fonts
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
sudo echo /usr/local/bin/fish >> /etc/shells
chsh -s /usr/local/bin/fish

# install .dotfiles
if ! [ -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/talesin/dotfiles.git $HOME/.dotfiles
fi
pushd $HOME/.dotfiles
./install
popd

# setup byobu
byobu-enable

popd