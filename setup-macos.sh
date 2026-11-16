#!/usr/bin/env bash

DIR=$(cd "$(dirname "$0")" && pwd)
DOTFILES_DIR=$DIR
pushd "$DIR" >/dev/null

# Load shared setup functions
source "$DIR/setup-common.sh"

function install-brew() {
	if not-installed brew; then
		echo "Installing brew"
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		export PATH=/opt/homebrew/bin:$PATH
	fi

	brew analytics off
}


function install-xcode() {
	xcode-select -p >/dev/null
	if [ $? -ne 0 ]; then
		echo "Xcode tools"
		xcode-select --install
		sudo xcode-select -s /Applications/Xcode.app
		sudo xcodebuild -license
	fi
}


# Install and upgrade everything in Brewfile.macos. brew bundle carries on past a
# package that fails (a download that times out, the App Store unreachable) and
# reports each failure in the middle of its output, so check afterwards and list
# whatever is still unsatisfied. The check also catches entries bundle skipped
# without saying so.
function install-brew-packages() {
	brew update
	brew bundle --file "$DIR/Brewfile.macos"

	local check line
	local -a pending=()
	check=$(brew bundle check --file "$DIR/Brewfile.macos" --verbose 2>&1) && return 0

	while IFS= read -r line; do
		pending+=("$line")
	done < <(printf '%s\n' "$check" | sed -n 's/^→ //p')
	[ ${#pending[@]} -eq 0 ] && pending=("$check")

	note-problem "Homebrew: Brewfile entries not installed or out of date (${#pending[@]})" \
		"${pending[@]}" \
		"Most often a download that timed out." \
		"Retry: brew bundle --file \"$DIR/Brewfile.macos\""
}

# `cs` and the standard Scala tools only arrive through `coursier setup`; the
# brew formula provides just the `coursier` launcher.
function install-coursier() {
	not-installed cs || return 0

	echo "Setting up Scala tooling with coursier"

	local bin="$HOME/Library/Application Support/Coursier/bin" log status reason
	local noise='^[[:space:]]+at |^[[:space:]]+\.\.\. [0-9]+ more|^Caused by: |^Exception in thread |^WARNING: (.*sun\.misc\.Unsafe|Please consider reporting this to the maintainers)'
	log=$(mktemp "${TMPDIR:-/tmp}/coursier-setup.XXXXXX")

	# - coursier offers to add its bin directory to ~/.profile, ~/.zprofile and
	#   ~/.bash_profile, which are symlinks into this repo; profile.d/paths adds
	#   the directory itself once it exists. Having it on PATH for this call skips
	#   the offer, and the "n" on stdin declines it should it appear anyway.
	# - Java keeps its own trust store, which lacks the root a TLS-inspecting proxy
	#   re-signs HTTPS with, so Maven Central fails with "PKIX path building
	#   failed" where curl succeeds. KeychainStore makes the JVM trust the macOS
	#   Keychain, as curl does.
	# - The full output goes to $log; the screen drops Java stack frames and the
	#   sun.misc.Unsafe notice.
	JAVA_OPTS="-Djavax.net.ssl.trustStoreType=KeychainStore -Djavax.net.ssl.trustStore=NONE ${JAVA_OPTS:-}" \
	PATH="$bin:$PATH" \
		coursier setup <<<"n" 2>&1 | tee "$log" | grep -v -E "$noise"
	status=${PIPESTATUS[0]}

	if [ "$status" -eq 0 ]; then
		rm -f "$log"
		return 0
	fi

	reason=$(sed -n -E 's/^Exception in thread "[^"]*" [A-Za-z0-9_.$]+: ([A-Za-z0-9_.$]+: )?//p' "$log" | head -1)
	note-problem "coursier setup failed${reason:+: $reason}" \
		"This usually means it could not download from Maven Central (network, proxy or certificate)." \
		"To see why: coursier resolve -v -v io.get-coursier:coursier-cli_2.13:latest.release" \
		"Full output: $log" \
		"Retry: $0 install-coursier"
}

function register-brew-shells() {
    grep -sq /opt/homebrew/bin/bash /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /opt/homebrew/bin/bash >> /etc/shells"
    fi

    grep -sq /opt/homebrew/bin/zsh /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /opt/homebrew/bin/zsh >> /etc/shells"
    fi
}

function install-iterm-integration() {
	if [ ! -f $HOME/.iterm2_shell_integration.zsh ]; then
		echo "Configuring iterm shell integration"
		curl -sL https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
	fi
}

function install-node-extras() {
	npm install -g typescript cdk
}

function use-brew-zsh() {
	if [ "$SHELL" != "/opt/homebrew/bin/zsh" ]; then
		echo "Change shell to zsh"
		sudo chsh -s /opt/homebrew/bin/zsh 
	fi
}


function install-powerline() {
	pushd /tmp >/dev/null

	ls ~/Library/Fonts | grep -i powerline >/dev/null
	if [ ! $? -eq 0 ]; then
		pipx install powerline-status

		git clone https://github.com/powerline/fonts.git --depth=1
		cd fonts
		./install.sh
		cd ..
		rm -fr fonts
	fi

	popd >/dev/null
}

# Install "Zellij 💻.app": a launcher that opens the Zellij terminal on the "💻"
# session (see zellij-launcher/launcher). It is copied rather than symlinked because
# Spotlight and the Dock do not treat a symlinked bundle as an app.
function install-zellij-launcher() {
	local zellij_app="$HOME/Applications/Zellij.app"
	local launcher_app="$HOME/Applications/Zellij 💻.app"

	if [ ! -d "$zellij_app" ]; then
		echo "Installing Zellij.app"
		zellij setup --install-desktop-entry
	fi

	echo "Installing $launcher_app"
	rm -rf "$launcher_app"
	mkdir -p "$launcher_app/Contents/MacOS" "$launcher_app/Contents/Resources"
	cp "$DIR/zellij-launcher/Info.plist" "$launcher_app/Contents/Info.plist"
	cp "$DIR/zellij-launcher/launcher" "$launcher_app/Contents/MacOS/launcher"
	chmod +x "$launcher_app/Contents/MacOS/launcher"
	cp "$zellij_app/Contents/Resources/zellij.icns" "$launcher_app/Contents/Resources/zellij.icns"
}

# Done-checks: return 0 when the step has nothing to do. Cheap, no side effects.
function brew-installed() { is-installed brew; }
function brew-shells-registered() {
	grep -sq /opt/homebrew/bin/bash /etc/shells && grep -sq /opt/homebrew/bin/zsh /etc/shells
}
function iterm-integration-installed() { [ -f "$HOME/.iterm2_shell_integration.zsh" ]; }
function coursier-installed() { is-installed cs; }
function xcode-installed() { xcode-select -p >/dev/null 2>&1; }
function node-extras-installed() { is-installed tsc && is-installed cdk; }
function powerline-installed() { find "$HOME/Library/Fonts" -iname '*powerline*' 2>/dev/null | grep -q .; }
function brew-zsh-in-use() { [ "$SHELL" = "/opt/homebrew/bin/zsh" ]; }

add-step install-brew              "Homebrew"                                  brew-installed
add-step install-brew-packages     "Brewfile.macos: install and upgrade"
add-step register-brew-shells      "Add Homebrew bash and zsh to /etc/shells"  brew-shells-registered
add-step install-iterm-integration "iTerm2 shell integration"                  iterm-integration-installed
add-step install-coursier          "Scala tooling (coursier setup)"            coursier-installed
add-step apply-dotfiles            "Symlink the dotfiles into place"
add-step seed-gitconfig            "Git name and email in ~/.gitconfig"        git-identity-set
add-step install-zellij-launcher   "Zellij launcher app"
add-step install-xcode             "Xcode command line tools"                  xcode-installed
add-step install-node              "Node.js via nvm"                           node-installed
add-step install-node-extras       "Global npm packages (typescript, cdk)"     node-extras-installed
add-step install-powerline         "Powerline fonts"                           powerline-installed
add-step use-brew-zsh              "Make Homebrew zsh the login shell"         brew-zsh-in-use
add-step install-zsh               "zsh and Oh My Zsh"                         zsh-installed
add-step install-bash              "Oh My Bash"                                bash-installed

run-setup macOS "$@"
status=$?
popd >/dev/null
exit $status
