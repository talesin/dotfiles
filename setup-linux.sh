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

	# Resolved once and passed down: the apt->tarball fallback used to look
	# this up twice and could download two full payloads for the same version.
	local tag
	tag=$(latest-github-tag PowerShell/PowerShell) || return 1

	if is-installed apt-get && install-powershell-apt "$tag" && pwsh-works; then
		echo "PowerShell installed: $(native-pwsh)"
		return 0
	fi

	if install-powershell-tarball "$tag" && pwsh-works; then
		echo "PowerShell installed: $(native-pwsh)"
		return 0
	fi

	local resolved
	if resolved=$(native-pwsh); then
		echo "Error: $resolved is installed but fails to run — missing runtime dependencies (libicu, libssl)?" >&2
	else
		echo "Error: PowerShell installation failed — no pwsh found after install attempts" >&2
	fi
	return 1
}


# Add Microsoft's apt repo for the running distro and refresh apt's indexes.
# Returns 0 only if apt now offers a `powershell` package — the caller does
# the actual `apt-get install`.
function add-microsoft-apt-repo() {
	local tmpdir="$1"

	if [ ! -r /etc/os-release ]; then
		echo "Error: /etc/os-release not readable; cannot determine distro for Microsoft's apt repo" >&2
		return 1
	fi

	# Read ID/VERSION_ID from a single subshell (avoids a plain `source`
	# polluting the caller's shell with every var os-release defines).
	local os_id os_ver
	{ IFS= read -r os_id; IFS= read -r os_ver; } \
		< <(. /etc/os-release && printf '%s\n%s\n' "$ID" "$VERSION_ID")
	if [ -z "$os_id" ] || [ -z "$os_ver" ]; then
		echo "Error: /etc/os-release did not report both ID and VERSION_ID" >&2
		return 1
	fi

	local ms_deb="$tmpdir/packages-microsoft-prod.deb"
	if ! curl -fsSL -o "$ms_deb" \
		"https://packages.microsoft.com/config/${os_id}/${os_ver}/packages-microsoft-prod.deb" 2>/dev/null; then
		echo "Microsoft apt repo has no config for ${os_id} ${os_ver}" >&2
		return 1
	fi
	sudo dpkg -i "$ms_deb" || return 1

	# Run outside any && chain: apt-get update legitimately exits non-zero if
	# ANY configured source is stale or unreachable — including unrelated
	# repos like the github-cli source install-packages adds above — even
	# when the Microsoft repo itself installed and refreshed fine. Gate
	# success on apt-cache show, not on update's exit status.
	sudo apt-get update
	apt-cache show powershell >/dev/null 2>&1
}


# Debian/Ubuntu strategy: Microsoft's apt repo, falling back to the upstream
# GitHub .deb if the distro/version isn't covered there.
function install-powershell-apt() {
	local tag="$1"
	local tmp
	tmp=$(mktemp -d) || return 1
	trap 'rm -rf "$tmp"' RETURN

	if add-microsoft-apt-repo "$tmp" && sudo apt-get install -y powershell; then
		return 0
	fi

	echo "Microsoft apt repo has no powershell for this distro/version; falling back to GitHub release..." >&2
	local arch
	arch=$(pwsh-arch deb) || return 1

	local ver="${tag#v}"
	local asset="powershell_${ver}-1.deb_${arch}.deb"
	local gh_deb="$tmp/${asset}"
	download-pwsh-asset "$tag" "$asset" "$gh_deb" || return 1

	sudo dpkg -i "$gh_deb" || sudo apt-get install -f -y
	native-pwsh >/dev/null
}


# Distro-agnostic fallback: unpack upstream's self-contained tarball into
# /opt/microsoft/powershell/7, matching the layout the .deb/.rpm packages use.
function install-powershell-tarball() {
	local tag="$1"
	local arch
	arch=$(pwsh-arch tar) || return 1

	# Upstream only ships a musl tarball for x64, not arm.
	if is-musl; then
		if [ "$arch" != "x64" ]; then
			echo "Error: PowerShell has no musl build for architecture '$arch'" >&2
			return 1
		fi
		arch="musl-x64"
	fi

	local ver="${tag#v}"
	local asset="powershell-${ver}-linux-${arch}.tar.gz"
	local tmp
	tmp=$(mktemp -d) || return 1
	trap 'rm -rf "$tmp"' RETURN

	local tarball="$tmp/${asset}"
	download-pwsh-asset "$tag" "$asset" "$tarball" || return 1

	local dest="/opt/microsoft/powershell/7"
	# Clear any prior version first — extracting over an existing tree would
	# mix files from a different version in.
	sudo rm -rf "$dest" \
		&& sudo mkdir -p "$dest" \
		&& sudo tar -xzf "$tarball" -C "$dest" \
		&& sudo chmod +x "$dest/pwsh" \
		&& sudo ln -sf "$dest/pwsh" /usr/local/bin/pwsh
}


# musl vs glibc: the loader path is the definitive signal. `ldd --version`
# doesn't reliably say "musl" — BusyBox's ldd (common on Alpine) prints
# nothing of the sort — which used to let a glibc tarball install silently.
function is-musl() {
	[ -e /lib/ld-musl-"$(uname -m)".so.1 ]
}


# Map `uname -m` to the arch token PowerShell's release assets use. The .deb
# and .tar.gz assets use different vocabularies for the same machine.
function pwsh-arch() {
	local kind="$1" machine
	machine=$(uname -m)
	case "$kind" in
	deb)
		case "$machine" in
		x86_64) printf 'amd64' ;;
		aarch64) printf 'arm64' ;;
		*)
			echo "Error: unsupported architecture '$machine' for PowerShell .deb" >&2
			return 1
			;;
		esac
		;;
	tar)
		case "$machine" in
		x86_64) printf 'x64' ;;
		aarch64) printf 'arm64' ;;
		armv7l) printf 'arm32' ;;
		*)
			echo "Error: unsupported architecture '$machine' for PowerShell tarball" >&2
			return 1
			;;
		esac
		;;
	*)
		echo "Error: pwsh-arch: unknown kind '$kind'" >&2
		return 1
		;;
	esac
}


# Smoke-test a resolved pwsh: `-x` alone doesn't catch a tarball install
# that's missing OS runtime deps (libicu, libssl) or a half-configured .deb.
function pwsh-works() {
	local resolved
	resolved=$(native-pwsh) || return 1
	"$resolved" -NoProfile -NonInteractive -Command 'exit 0' >/dev/null 2>&1
}


# Download a PowerShell release asset and verify it against upstream's
# published hashes.sha256 (covers both the .tar.gz and .deb assets). Warns
# and proceeds if no hash is published or sha256sum isn't available; fails
# hard on a mismatch.
function download-pwsh-asset() {
	local tag="$1" asset="$2" out="$3"
	local base="https://github.com/PowerShell/PowerShell/releases/download/${tag}"

	if ! curl -fsSL -o "$out" "${base}/${asset}"; then
		echo "Error: failed to download PowerShell ${tag} asset ${asset}" >&2
		return 1
	fi

	if ! is-installed sha256sum; then
		echo "Warning: sha256sum not available; skipping checksum verification for ${asset}" >&2
		return 0
	fi

	# hashes.sha256 is UTF-16LE with CRLF line endings; strip both without
	# depending on iconv.
	local hashes expected actual
	hashes=$(curl -fsSL "${base}/hashes.sha256" 2>/dev/null | LC_ALL=C tr -d '\000\377\376\r')
	if [ -z "$hashes" ]; then
		echo "Warning: could not fetch hashes.sha256 for ${tag}; skipping checksum verification for ${asset}" >&2
		return 0
	fi

	expected=$(printf '%s\n' "$hashes" | awk -v f="*${asset}" '$2==f{print $1; exit}')
	if [ -z "$expected" ]; then
		echo "Warning: no published checksum found for ${asset}; skipping verification" >&2
		return 0
	fi

	actual=$(sha256sum "$out" | awk '{print $1}')
	if [ "$actual" != "$expected" ]; then
		echo "Error: checksum mismatch for ${asset} (expected ${expected}, got ${actual})" >&2
		rm -f "$out"
		return 1
	fi
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
