#!/usr/bin/env bash
# Common setup functions shared across platform-specific setup scripts

DOTFILES_DIR=${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# Check if running under WSL
function is-wsl() {
    [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease
}

# Print zellij's plugin directory for this OS. Does not require zellij to be
# installed, so it is safe to call before install-zellij has run.
function zellij-plugin-dir() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        printf '%s' "$HOME/Library/Application Support/org.Zellij-Contributors.Zellij/plugins"
    else
        printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/zellij/plugins"
    fi
}

# Grant the tab-title plugin its permissions by seeding zellij's permission
# cache. The grant prompt renders in a plugin's pane, and a background plugin
# loaded from load_plugins has no pane, so the prompt never reaches the user
# and the plugin waits forever. The cache key is the config's file: path
# verbatim (zellij never resolves it), so it is the same on every machine.
# Skipped when the key is already present, whether seeded or granted live.
function seed-zellij-plugin-permissions() {
    local cache_file
    if [[ "$(uname -s)" == "Darwin" ]]; then
        cache_file="$HOME/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl"
    else
        cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/zellij/permissions.kdl"
    fi

    if [[ -f "$cache_file" ]] && grep -q "zellij-tab-title.wasm" "$cache_file"; then
        return 0
    fi

    mkdir -p "$(dirname "$cache_file")"
    cat >> "$cache_file" <<'EOF'
"zellij-tab-title.wasm" {
    ReadApplicationState
    ChangeApplicationState
}
EOF
    echo "  granted zellij-tab-title.wasm permissions in $cache_file"
}

# Check if a command is available
function is-installed() {
    command -v "$1" >/dev/null 2>&1
}

# Inverse of is-installed
function not-installed() {
    ! is-installed "$1"
}

# Problems found while a setup script runs. A failed step is recorded and the
# script carries on, so one flaky download does not strand the steps after it;
# report-problems prints them together at the end, where they are not buried in
# the output of the steps that worked.
SETUP_PROBLEMS=()

# Record a problem: note-problem <summary> [<detail line>...]. The summary is
# echoed now; the detail lines appear only in the final report.
function note-problem() {
    SETUP_PROBLEMS+=("$(printf '%s\n' "$@")")
    echo "  ! $1" >&2
}

# Run a setup step (a function or command). A non-zero exit is recorded as a
# problem with a retry command; the script's functions are all runnable by name.
function run-step() {
    local status
    "$@"
    status=$?
    if [ "$status" -ne 0 ]; then
        note-problem "$1 failed (exit status $status)" \
            "The output above has the details." \
            "Retry: $0 $1"
    fi
}

# Print every recorded problem and return 1, or return 0 when there are none.
function report-problems() {
    local count=${#SETUP_PROBLEMS[@]} entry line first
    [ "$count" -eq 0 ] && return 0

    echo
    if [ "$count" -eq 1 ]; then
        echo "Setup finished, but 1 step needs attention:"
    else
        echo "Setup finished, but $count steps need attention:"
    fi
    for entry in "${SETUP_PROBLEMS[@]}"; do
        echo
        first=1
        while IFS= read -r line; do
            if [ "$first" -eq 1 ]; then
                echo "  * $line"
                first=0
            else
                echo "      $line"
            fi
        done <<<"$entry"
    done
    return 1
}

# Print the latest release tag for a GitHub repo (e.g. "PowerShell/PowerShell").
# Returns 1 and prints an error if the API call fails or returns no tag.
# grep -o anchors on the tag_name key so a `"tag_name": null` release or
# minified JSON body can't be mistaken for a real tag (both previously slipped
# past a bare `[ -z ]` check with `curl -s` and a greedy sed).
function latest-github-tag() {
    local repo="$1" tag
    tag=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep -o '"tag_name": *"[^"]*"' | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
    if [ -z "$tag" ]; then
        echo "Error: failed to fetch latest release tag for ${repo} from GitHub API" >&2
        return 1
    fi
    printf '%s' "$tag"
}

# Print the path to a real (non-shim) pwsh interpreter, or return 1 if none.
# Canonical implementation lives in functions/native-pwsh so the interactive
# shell (shell-common.sh) and setup share one copy.
function native-pwsh() {
    source "$DOTFILES_DIR/functions/native-pwsh"
}

# Install Node.js via NVM
function install-node() {
    export NVM_DIR="$HOME/.nvm"

    # Check if NVM is installed (it's a shell function, not a binary)
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "Installing nvm"
        # Use latest stable NVM version
        NVM_VERSION=$(latest-github-tag nvm-sh/nvm) || return 1
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
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

# Seed the per-machine ~/.gitconfig with the user identity
function seed-gitconfig() {
    if [ ! -e "$HOME/.gitconfig" ]; then
        local git_name git_email
        while [ -z "$git_name" ]; do
            read -rp "Git name: " git_name
        done
        while [ -z "$git_email" ]; do
            read -rp "Git email: " git_email
        done

        git config --file "$HOME/.gitconfig" user.name "$git_name"
        git config --file "$HOME/.gitconfig" user.email "$git_email"
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

# Link the shared git config to the XDG location and keep ~/.gitconfig as an
# untracked per-machine file. Git reads ~/.gitconfig after the XDG file, so its
# settings win, and `git config --global` writes there whenever it exists; Git
# Credential Manager records per-organisation settings that way, which must stay
# out of the repo.
function link-gitconfig() {
    local dotfiles_dir="$1"
    local legacy="$HOME/.config/gitconfig.local"

    link-dotfile "$dotfiles_dir/gitconfig" "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"

    # Earlier layout: ~/.gitconfig was the symlink into the repo and the
    # per-machine settings lived in ~/.config/gitconfig.local.
    if [ -L "$HOME/.gitconfig" ]; then
        rm "$HOME/.gitconfig"
    fi
    if [ -f "$legacy" ] && [ ! -e "$HOME/.gitconfig" ]; then
        mv "$legacy" "$HOME/.gitconfig"
        echo "  moved $legacy to $HOME/.gitconfig"
    fi

    [ -e "$HOME/.gitconfig" ] || touch "$HOME/.gitconfig"
}

# Apply dotfile symlinks
function apply-dotfiles() {
    local dotfiles_dir="${1:-$(pwd)}"

    echo "Applying dotfile symlinks..."

    link-dotfile "$dotfiles_dir/aliases" ~/.aliases
    link-dotfile "$dotfiles_dir/vimrc" ~/.vimrc
    link-dotfile "$dotfiles_dir/bashrc" ~/.bashrc
    link-dotfile "$dotfiles_dir/bash_profile" ~/.bash_profile
    link-gitconfig "$dotfiles_dir"
    link-dotfile "$dotfiles_dir/profile" ~/.profile
    link-dotfile "$dotfiles_dir/zshenv" ~/.zshenv
    link-dotfile "$dotfiles_dir/zshrc" ~/.zshrc
    link-dotfile "$dotfiles_dir/zprofile" ~/.zprofile
    link-dotfile "$dotfiles_dir/functions" ~/.functions
    link-dotfile "$dotfiles_dir/zellij.kdl" ~/.config/zellij/config.kdl
    link-dotfile "$dotfiles_dir/zellij-layouts" ~/.config/zellij/layouts
    link-dotfile "$dotfiles_dir/zellij-plugins/zellij-tab-title.wasm" "$(zellij-plugin-dir)/zellij-tab-title.wasm"
    seed-zellij-plugin-permissions
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