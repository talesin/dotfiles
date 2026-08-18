#!/usr/bin/env bash
# Common setup functions shared across platform-specific setup scripts

# Check if running under WSL
function is-wsl() {
    [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease
}

# Check if a command is available
function is-installed() {
    command -v "$1" >/dev/null 2>&1
}

# Inverse of is-installed
function not-installed() {
    ! is-installed "$1"
}

# Print the latest release tag for a GitHub repo (e.g. "PowerShell/PowerShell").
# Returns 1 and prints an error if the API call fails or returns no tag.
function latest-github-tag() {
    local repo="$1" tag
    tag=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$tag" ]; then
        echo "Error: failed to fetch latest release tag for ${repo} from GitHub API" >&2
        return 1
    fi
    printf '%s' "$tag"
}

# Print the path to a real (non-shim) pwsh interpreter, or return 1 if none.
# Deliberately does NOT consult $PATH/command -v: under WSL, ~/.local/bin/pwsh
# (highest PATH precedence, see profile.d/paths) is the scripts/pwsh shim that
# execs Windows pwsh.exe — using it here would make install-powershell think
# a native interpreter is already present. Probe the fixed locations the
# .deb/tarball/Homebrew installs actually use instead. Keep this list in sync
# with the candidates in shell-common.sh's PowerShell completion block.
function native-pwsh() {
    local candidate
    for candidate in /usr/bin/pwsh /usr/local/bin/pwsh /opt/homebrew/bin/pwsh /opt/microsoft/powershell/7/pwsh; do
        if [ -x "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

# Install Node.js via NVM
function install-node() {
    export NVM_DIR="$HOME/.nvm"

    # Check if NVM is installed (it's a shell function, not a binary)
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "Installing nvm"
        # Use latest stable NVM version
        NVM_VERSION=$(latest-github-tag nvm-sh/nvm) || return 1
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
    link-dotfile "$dotfiles_dir/direnv.toml" ~/.config/direnv/direnv.toml
    link-dotfile "$dotfiles_dir/profile.d" ~/.profile.d
    link-dotfile "$dotfiles_dir/shell-common.sh" ~/.shell-common.sh

    # Symlink scripts to ~/.local/bin (WSL only)
    if is-wsl && [ -d "$dotfiles_dir/scripts" ]; then
        mkdir -p "$HOME/.local/bin"
        for script in "$dotfiles_dir/scripts"/*; do
            [ -f "$script" ] && link-dotfile "$script" "$HOME/.local/bin/$(basename "$script")"
        done
    fi

    echo "Done."
}