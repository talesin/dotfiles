#!/usr/bin/env bash

DIR=$HOME/.dotfiles
mkdir -p $DIR 2>/dev/null
pushd $DIR >/dev/null

# Load shared setup functions
source "$DIR/setup-common.sh"

OPT=$1
shift

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

function install-apps() {
	install-brew-packages

    grep -sq /opt/homebrew/bin/bash /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /opt/homebrew/bin/bash >> /etc/shells"
    fi

    grep -sq /opt/homebrew/bin/zsh /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /opt/homebrew/bin/zsh >> /etc/shells"
    fi

	if [ ! -f $HOME/.iterm2_shell_integration.zsh ]; then
		echo "Configuring iterm shell integration"
		curl -sL https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
	fi

	install-coursier

	seed-gitconfig
}

function install-node-extras() {
	npm install -g typescript cdk
}

function install-zsh-macos() {
	if [ "$SHELL" != "/opt/homebrew/bin/zsh" ]; then
		echo "Change shell to zsh"
		sudo chsh -s /opt/homebrew/bin/zsh 
	fi
	
	# Call shared zsh installation
	install-zsh
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

case $OPT in
"")
	run-step install-brew
	run-step install-apps
	run-step apply-dotfiles "$DIR"
	run-step install-zellij-launcher
	run-step install-xcode
	run-step install-node
	run-step install-node-extras
	run-step install-powerline
	run-step install-zsh-macos
	run-step install-bash
	;;

*)
	run-step "$OPT" "$@"
	;;
esac

popd >/dev/null
report-problems
