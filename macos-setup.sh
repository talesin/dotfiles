#!/usr/bin/env bash
DIR=`cd $(dirname $0); pwd`

function install-brew() {
    which brew > /dev/null
    if [ $? -eq 1 ]; then
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

function install-apps {
    if ! [ -f Brewfile ]; then
        curl -s 'https://raw.githubusercontent.com/talesin/dotfiles/master/Brewfile' -o Brewfile
    fi

    brew update
    brew bundle
    brew cleanup

    # enable direnv
    direnv allow

    # iterm2 shell integration
    curl -sL https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
}

# install powerline fonts
function install-powerline() {
    PATH="/usr/local/opt/python/libexec/bin:${PATH}" pip install --user powerline-status

    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    ./install.sh
    cd ..
    rm -fr fonts
}

function setup-bash() {
    curl -fsSL https://raw.github.com/ohmybash/oh-my-bash/master/tools/install.sh | /usr/local/bin/bash
    grep -sq /usr/local/bin/bash /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/bash >> /etc/shells"
    fi
    # chsh -s /usr/local/bin/bash
}

function setup-fish() {
    curl -s -L https://get.oh-my.fish > omf-install.fish
    fish omf-install.fish --noninteractive
    rm omf-install.fish
    fish -c omf theme install agnoster
    fish -c omf theme agnoster
    fish -c omf install bass
    grep -sq fish /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/fish >> /etc/shells"
    fi
    # chsh -s /usr/local/bin/fish
}

function install-nvm() {    
    curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
}

function setup-powershell() {
    mkdir ~/.config/powershell/
    pwsh -c { Install-Module posh-git -Scope AllUsers }
    pwsh -c { Install-Module oh-my-posh -Scope AllUsers }
    pwsh -c { Install-Module -Name PSReadLine -AllowPrerelease -Scope AllUsers -Force }
    grep -sq pwsh /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/pwsh >> /etc/shells"
    fi
    # chsh -s /usr/local/bin/pwsh
}

function install-spacevim() {
    curl -sLf https://spacevim.org/install.sh | bash
}

function install-dotfiles() {
    if ! [ -d "$HOME/.dotfiles" ]; then
        git clone --recurse-submodules https://github.com/talesin/dotfiles.git $HOME/.dotfiles
    fi
    pushd $HOME/.dotfiles
    ./install
    popd
}


pushd $DIR

install-brew
install-apps
install-powerline
install-nvm
install-spacevim

setup-bash
setup-fish
setup-powershell

install-dotfiles

#/usr/local/bin/byobu-enable

popd
