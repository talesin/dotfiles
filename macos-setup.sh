#!/usr/bin/env bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install python direnv byobu vim coreutils fish
direnv allow

export PATH="/usr/local/opt/python/libexec/bin;${PATH}"
pip install --user powerline-status

pushd /tmp
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -fr fonts
popd

curl -L https://get.oh-my.fish | fish
sudo echo /usr/local/bin/fish >> /etc/shells
chsh -s /usr/local/bin/fish

byobu-enable
