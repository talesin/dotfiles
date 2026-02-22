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
        if [ -z "$NVM_VERSION" ]; then
            echo "Error: failed to fetch NVM version from GitHub API" >&2
            return 1
        fi
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

# Seed gitconfig.local with user identity and gh credential helper
function seed-gitconfig() {
    if [ ! -f "$HOME/.config/gitconfig.local" ]; then
        local git_name git_email
        while [ -z "$git_name" ]; do
            read -rp "Git name: " git_name
        done
        while [ -z "$git_email" ]; do
            read -rp "Git email: " git_email
        done

        mkdir -p "$HOME/.config"
        local cfg="$HOME/.config/gitconfig.local"

        git config --file "$cfg" user.name "$git_name"
        git config --file "$cfg" user.email "$git_email"

        if is-installed gh; then
            git config --file "$cfg" 'credential.https://github.com.helper' ''
            git config --file "$cfg" 'credential.https://github.com.helper' '!gh auth git-credential'
            git config --file "$cfg" 'credential.https://gist.github.com.helper' ''
            git config --file "$cfg" 'credential.https://gist.github.com.helper' '!gh auth git-credential'
        fi
    fi
}

# Create a symlink, removing any existing file/symlink
function link-dotfile() {
    local src="$1" dest="$2"
    if [ -z "$dest" ]; then
        echo "Error: link-dotfile requires a destination path" >&2
        return 1
    fi
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

    # Symlink scripts to ~/.local/bin
    if [ -d "$dotfiles_dir/scripts" ]; then
        mkdir -p "$HOME/.local/bin"
        for script in "$dotfiles_dir/scripts"/*; do
            [ -f "$script" ] && link-dotfile "$script" "$HOME/.local/bin/$(basename "$script")"
        done
    fi

    echo "Done."
}