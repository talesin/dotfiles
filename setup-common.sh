#!/usr/bin/env bash
# Common setup functions shared across platform-specific setup scripts

# Check if a command is available
function is-installed() {
    which $1 >/dev/null 2>&1
    return $?
}

# Inverse of is-installed
function not-installed() {
    ! is-installed $1
    return $?
}

# Install Node.js via NVM
function install-node() {
    if not-installed nvm; then
        echo "Installing nvm"
        # Use latest stable NVM version
        NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
    
    if not-installed node; then
        echo "Installing node"
        nvm install node
        nvm use node
    fi
}

# Install Zsh and Oh My Zsh
function install-zsh() {
    if not-installed zsh; then
        echo "Installing zsh"
        if is-installed brew; then
            brew install zsh
        elif is-installed yum; then
            sudo yum install -y zsh
        elif is-installed apt-get; then
            sudo apt-get install -y zsh
        fi
    fi
    
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing oh-my-zsh"
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

# Install Bash and Oh My Bash
function install-bash() {
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        echo "Installing oh-my-bash"
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    fi
}

# Apply dotbot configuration
function apply-dotbot() {
    if not-installed dotbot; then
        echo "Installing dotbot"
        git submodule update --init --recursive
    fi
    
    echo "Applying dotbot configuration"
    dotbot -c install.conf.yaml
}