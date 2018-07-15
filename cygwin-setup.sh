#!/usr/bin/env bash

pushd $TEMP

# install cygwin packages
curl -L -o setup-x86_64.exe https://cygwin.com/setup-x86_64.exe
./setup-x86_64.exe -q --packages=bash,vim,git,fish,python,tmux,make,lynx,wget

# install byobu
BYOBU_VERSION=5.125
BYOBU_TAR=byobu_${BYOBU_VERSION}.orig.tar.gz
BYOBU_MAKEDIR=byobu-${BYOBU_VERSION}
curl -L -o $BYOBU_TAR https://launchpad.net/byobu/trunk/5.125/+download/$BYOBU_TAR
tar xvzf $BYOBU_TAR
pushd $BYOBU_MAKEDIR
./configure --prefix=/usr/local
make
make install
popd
rm -fr $BYOBU_MAKEDIR

# setup fish
curl -L https://get.oh-my.fish > omf-install.fish
fish omf-install.fish --noninteractive
rm omf-install.fish
sed 's/db_shell.*//' /etc/nsswitch.conf | awk NF > /etc/nsswitch.conf
FISH_PATH=`which fish`
echo "db_shell: $FISH_PATH" >> /etc/nsswitch.conf

# install .dotfiles
if ! [ -d "$HOME/.dotfiles" ]; then
    git clone --recurse-submodules https://github.com/talesin/dotfiles.git $HOME/.dotfiles
fi
pushd $HOME/.dotfiles
./install
popd

# setup byobu
/usr/local/bin/byobu-enable

popd