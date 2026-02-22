#!/usr/bin/env bash

DIR=$(cd "$(dirname "$0")" && pwd)
pushd "$DIR" >/dev/null

# Load shared setup functions
source "$DIR/setup-common.sh"

OPT=${1:-}
[ $# -gt 0 ] && shift


# Install packages via system package manager (pre-built binaries, no compilation)
function install-packages() {
	echo "Installing packages..."

	if is-installed apt-get; then
		# Debian/Ubuntu
		local packages="bash zsh vim git curl wget jq gnupg direnv python3"

		# Add GitHub CLI repo if not present
		if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
			sudo mkdir -p -m 755 /etc/apt/keyrings
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
			sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
		fi

		sudo apt-get update
		sudo apt-get install -y $packages gh

	elif is-installed dnf; then
		# Fedora
		sudo dnf install -y bash zsh vim git curl wget jq gnupg2 direnv python3 gh

	elif is-installed yum; then
		# RHEL/CentOS (gh requires EPEL or manual install)
		sudo yum install -y bash zsh vim git curl wget jq gnupg2 direnv python3
	fi
}


# Install zellij from GitHub releases (not in apt)
function install-zellij() {
	if not-installed zellij; then
		echo "Installing zellij..."
		local version
		version=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | jq -r .tag_name)
		if [ -z "$version" ] || [ "$version" = "null" ]; then
			echo "Error: failed to fetch zellij version from GitHub API" >&2
			return 1
		fi
		local arch
		arch=$(uname -m)
		if [ "$arch" = "x86_64" ]; then
			arch="x86_64-unknown-linux-musl"
		elif [ "$arch" = "aarch64" ]; then
			arch="aarch64-unknown-linux-musl"
		else
			echo "Error: unsupported architecture '$arch' for zellij" >&2
			return 1
		fi
		curl -fsSL "https://github.com/zellij-org/zellij/releases/download/${version}/zellij-${arch}.tar.gz" | tar -xz -C "$HOME/.local/bin"
	fi
}


function setup-config() {
	mkdir -p "$HOME/.local/bin"
	export PATH="$HOME/.local/bin:$PATH"

	seed-gitconfig
}


case $OPT in
"")
	install-packages
	setup-config
	install-zellij
	apply-dotfiles "$DIR"
	install-node
	install-zsh
	install-bash
	;;

*)
	$OPT "$@"
	;;
esac

popd >/dev/null
