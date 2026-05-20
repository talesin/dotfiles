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


function install-powershell() {
	if not-installed pwsh; then
		if is-installed apt-get; then
			echo "Installing PowerShell..."
			# shellcheck disable=SC1091
			source /etc/os-release
			local ms_deb="/tmp/packages-microsoft-prod.deb"
			local installed_via_apt=false
			if curl -fsSL -o "$ms_deb" \
				"https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb" 2>/dev/null; then
				sudo dpkg -i "$ms_deb"
				rm -f "$ms_deb"
				sudo apt-get update
				if apt-cache show powershell >/dev/null 2>&1; then
					sudo apt-get install -y powershell
					installed_via_apt=true
				fi
			else
				rm -f "$ms_deb"
			fi
			if [ "$installed_via_apt" = false ]; then
				echo "Microsoft apt repo has no powershell for ${ID} ${VERSION_ID}; falling back to GitHub release..."
				local arch
				arch=$(dpkg --print-architecture)
				if [ "$arch" != "amd64" ] && [ "$arch" != "arm64" ]; then
					echo "Error: GitHub .deb fallback only supports amd64/arm64 (got '$arch')" >&2
					return 1
				fi
				local tag
				tag=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -r .tag_name)
				if [ -z "$tag" ] || [ "$tag" = "null" ]; then
					echo "Error: failed to fetch PowerShell version from GitHub API" >&2
					return 1
				fi
				local ver="${tag#v}"
				local gh_deb="/tmp/powershell_${ver}-1.deb_${arch}.deb"
				if ! curl -fsSL -o "$gh_deb" \
					"https://github.com/PowerShell/PowerShell/releases/download/${tag}/powershell_${ver}-1.deb_${arch}.deb"; then
					echo "Error: failed to download PowerShell ${tag} for ${arch}" >&2
					rm -f "$gh_deb"
					return 1
				fi
				sudo dpkg -i "$gh_deb" || sudo apt-get install -f -y
				rm -f "$gh_deb"
			fi
		else
			echo "Skipping PowerShell: automatic install only supported on apt-based systems"
		fi
	fi
}


function install-fonts() {
	# FiraCode
	if is-installed apt-get; then
		sudo apt-get install -y fonts-firacode
	elif is-installed dnf; then
		sudo dnf install -y fira-code-fonts
	fi

	# Powerline fonts
	if ! fc-list | grep -qi powerline; then
		pushd /tmp >/dev/null
		git clone https://github.com/powerline/fonts.git --depth=1
		cd fonts
		./install.sh
		cd ..
		rm -rf fonts
		popd >/dev/null
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
	install-fonts
	setup-config
	install-zellij
	install-powershell
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
