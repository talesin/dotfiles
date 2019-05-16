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
}

function setup-fish() {
    curl -s -L https://get.oh-my.fish > omf-install.fish
    fish omf-install.fish --noninteractive
    rm omf-install.fish
    fish -c "omf install agnoster"
    fish -c "omf theme agnoster"
    fish -c "omf install bass"
    grep -sq fish /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/fish >> /etc/shells"
    fi
}

function setup-zsh() {
    if [ -d $HOME/.oh-my-zsh ]; then
        rm -fr $HOME/.oh-my-zsh
    fi
    expect << EOF
spawn sh -c "curl -fsSL 'https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh' | bash"
expect "Password for ${USER}: "
send "\r"
EOF
    grep -sq /usr/local/bin/zsh /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/zsh >> /etc/shells"
    fi
}

function install-nvm() {    
    curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
}

function setup-powershell() {
    mkdir $HOME/.config/powershell/ 2>/dev/null
    mkdir $HOME/Documents/WindowsPowerShell/ 2>/dev/null
    mkdir $HOME/Documents/PowerShell/ 2>/dev/null
    pwsh -noprofile -c { Install-Module posh-git -Scope AllUsers }
    pwsh -noprofile -c { Install-Module oh-my-posh -Scope AllUsers }
    pwsh -noprofile -c { Install-Module -Name PSReadLine -AllowPrerelease -Scope AllUsers -Force }
    grep -sq pwsh /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/pwsh >> /etc/shells"
    fi
}

function install-spacevim() {
    curl -sLf https://spacevim.org/install.sh | bash
}

function install-dotfiles() {
    if ! [ -d "$HOME/.dotfiles" ]; then
        git clone --recurse-submodules https://github.com/talesin/dotfiles.git $HOME/.dotfiles
    fi
    pushd $HOME/.dotfiles
    git submodule update --init --remote dotbot && git add dotbot
    ./install
    popd
}


pushd $DIR

case $1 in
"")
    install-brew
    install-apps
    install-powerline
    install-nvm
    install-spacevim

    setup-bash
    setup-fish
    setup-zsh
    setup-powershell

    install-dotfiles
    ;;

*)
    $1
    ;;

esac

# chsh -s /usr/local/bin/pwsh
# chsh -s /usr/local/bin/bash
# chsh -s /usr/local/bin/fish
# /usr/local/bin/byobu-enable

popd
