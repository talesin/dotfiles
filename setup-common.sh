#!/usr/bin/env bash
# Common setup functions shared across platform-specific setup scripts

# Check if a command is available
function is-installed() {
    command -v "$1" >/dev/null 2>&1
}

# Inverse of is-installed
function not-installed() {
    ! is-installed "$1"
}

# Install Node.js via NVM
function install-node() {
    export NVM_DIR="$HOME/.nvm"

    # Check if NVM is installed (it's a shell function, not a binary)
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "Installing nvm"
        # Use latest stable NVM version
        NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    fi

    # Load NVM
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

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
        if is-installed apt-get; then
            sudo apt-get install -y zsh
        elif is-installed dnf; then
            sudo dnf install -y zsh
        elif is-installed yum; then
            sudo yum install -y zsh
        elif is-installed brew; then
            brew install zsh
        fi
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing oh-my-zsh"
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

# Install Bash and Oh My Bash
function install-bash() {
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        echo "Installing oh-my-bash"
        OSH_UNATTENDED=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    fi
}

# Create a symlink, removing any existing file/symlink
function link-dotfile() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    ln -sfn "$src" "$dest"
    echo "  $dest -> $src"
}

# Apply dotfile symlinks
function apply-dotfiles() {
    local dotfiles_dir="${1:-$(pwd)}"

    echo "Applying dotfile symlinks..."

    link-dotfile "$dotfiles_dir/aliases" ~/.aliases
    link-dotfile "$dotfiles_dir/vimrc" ~/.vimrc
    link-dotfile "$dotfiles_dir/bashrc" ~/.bashrc
    link-dotfile "$dotfiles_dir/bash_profile" ~/.bash_profile
    link-dotfile "$dotfiles_dir/gitconfig" ~/.gitconfig
    link-dotfile "$dotfiles_dir/profile" ~/.profile
    link-dotfile "$dotfiles_dir/zshenv" ~/.zshenv
    link-dotfile "$dotfiles_dir/zshrc" ~/.zshrc
    link-dotfile "$dotfiles_dir/zprofile" ~/.zprofile
    link-dotfile "$dotfiles_dir/functions" ~/.functions
    link-dotfile "$dotfiles_dir/zellij.kdl" ~/.config/zellij/config.kdl
    link-dotfile "$dotfiles_dir/profile.d" ~/.profile.d
    link-dotfile "$dotfiles_dir/shell-common.sh" ~/.shell-common.sh

    echo "Done."
}