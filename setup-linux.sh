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
		version=$(latest-github-tag zellij-org/zellij) || return 1
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
	# Guard on a real interpreter, not "not-installed pwsh": after apply-dotfiles
	# runs on WSL, ~/.local/bin/pwsh (highest PATH precedence) is the scripts/pwsh
	# shim, which itself requires a native pwsh to fall back to. Checking PATH
	# here would make this function a permanent no-op on WSL re-runs.
	if native-pwsh >/dev/null; then
		return 0
	fi

	echo "Installing PowerShell..."
	if is-installed apt-get; then
		install-powershell-apt || install-powershell-tarball
	else
		install-powershell-tarball
	fi

	local resolved
	if resolved=$(native-pwsh); then
		echo "PowerShell installed: $resolved"
	else
		echo "Error: PowerShell installation failed — no pwsh found after install attempts" >&2
		return 1
	fi
}


# Debian/Ubuntu strategy: Microsoft's apt repo, falling back to the upstream
# GitHub .deb if the distro/version isn't covered there.
function install-powershell-apt() {
	# Read os-release in a subshell so ID/VERSION_ID etc. don't leak into the
	# caller's shell (this used to be a plain `source`, polluting every
	# function that ran afterwards in the same setup.sh invocation).
	local os_id os_ver
	os_id=$(. /etc/os-release && printf '%s' "$ID")
	os_ver=$(. /etc/os-release && printf '%s' "$VERSION_ID")

	local ms_deb="/tmp/packages-microsoft-prod.deb"
	if curl -fsSL -o "$ms_deb" \
		"https://packages.microsoft.com/config/${os_id}/${os_ver}/packages-microsoft-prod.deb" 2>/dev/null \
		&& sudo dpkg -i "$ms_deb" \
		&& sudo apt-get update \
		&& apt-cache show powershell >/dev/null 2>&1 \
		&& sudo apt-get install -y powershell; then
		rm -f "$ms_deb"
		return 0
	fi
	rm -f "$ms_deb"

	echo "Microsoft apt repo has no powershell for ${os_id} ${os_ver}; falling back to GitHub release..."
	local arch
	arch=$(dpkg --print-architecture)
	if [ "$arch" != "amd64" ] && [ "$arch" != "arm64" ]; then
		echo "Error: GitHub .deb fallback only supports amd64/arm64 (got '$arch')" >&2
		return 1
	fi
	local tag
	tag=$(latest-github-tag PowerShell/PowerShell) || return 1
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

	native-pwsh >/dev/null
}


# Distro-agnostic fallback: unpack upstream's self-contained tarball into
# /opt/microsoft/powershell/7, matching the layout the .deb/.rpm packages use.
function install-powershell-tarball() {
	local machine arch
	machine=$(uname -m)
	case "$machine" in
	x86_64) arch="x64" ;;
	aarch64) arch="arm64" ;;
	armv7l) arch="arm32" ;;
	*)
		echo "Error: unsupported architecture '$machine' for PowerShell" >&2
		return 1
		;;
	esac

	# Upstream only ships a musl tarball for x64, not arm.
	if [ "$arch" = "x64" ] && ldd --version 2>&1 | grep -qi musl; then
		arch="musl-x64"
	fi

	local tag
	tag=$(latest-github-tag PowerShell/PowerShell) || return 1
	local ver="${tag#v}"
	local tarball="/tmp/powershell-${ver}-linux-${arch}.tar.gz"
	if ! curl -fsSL -o "$tarball" \
		"https://github.com/PowerShell/PowerShell/releases/download/${tag}/powershell-${ver}-linux-${arch}.tar.gz"; then
		echo "Error: failed to download PowerShell ${tag} for linux-${arch}" >&2
		rm -f "$tarball"
		return 1
	fi

	sudo mkdir -p /opt/microsoft/powershell/7
	sudo tar -xzf "$tarball" -C /opt/microsoft/powershell/7
	sudo chmod +x /opt/microsoft/powershell/7/pwsh
	sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh
	rm -f "$tarball"
}


function install-wsl-tools() {
	if ! is-wsl; then
		return 0
	fi

	if not-installed wslview; then
		if is-installed apt-get && apt-cache show wslu >/dev/null 2>&1; then
			echo "Installing wslu (Windows interop utilities)..."
			sudo apt-get install -y wslu
		else
			echo "wslu not available in apt; installing bundled wslview fallback..."
			mkdir -p "$HOME/.local/bin"
			install -m 755 "$DIR/scripts/wslview" "$HOME/.local/bin/wslview"
		fi
	fi

	if is-installed wslview && [ ! -e /usr/local/bin/xdg-open ]; then
		sudo ln -sf "$(command -v wslview)" /usr/local/bin/xdg-open
	fi

	# Deploy .wslconfig to Windows user profile (mirrored networking for localhost OAuth flows)
	local win_home
	win_home=$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')")
	if [ -n "$win_home" ] && [ -d "$win_home" ]; then
		cp "$DIR/wslconfig" "$win_home/.wslconfig"
		echo "Deployed .wslconfig to $win_home — restart WSL to apply (wsl --shutdown)"
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


function install-dotnet() {
	echo "Installing .NET SDK (LTS)..."
	local installer="$HOME/.local/bin/dotnet-install.sh"
	if [ ! -f "$installer" ]; then
		mkdir -p "$HOME/.local/bin"
		curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$installer" && chmod +x "$installer"
	fi
	"$installer" --channel LTS --install-dir "$HOME/.dotnet"
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
	install-dotnet
	install-wsl-tools
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
