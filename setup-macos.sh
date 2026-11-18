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


# Xcode.app comes from the Brewfile's mas entry. The command line tools alone
# satisfy `xcode-select -p`, so the checks look at the app: installed, selected
# as the developer directory, and its license accepted.
XCODE_APP=/Applications/Xcode.app

function xcode-selected() {
	[ "$(xcode-select -p 2>/dev/null)" = "$XCODE_APP/Contents/Developer" ]
}

function install-xcode() {
	if [ ! -d "$XCODE_APP" ]; then
		xcode-select -p >/dev/null 2>&1 || xcode-select --install
		note-problem "Xcode: $XCODE_APP is not installed" \
			"The Brewfile installs it through mas when it is absent, so install-brew-packages probably failed or was skipped." \
			"Retry: $0 install-brew-packages, then $0 install-xcode"
		return 0
	fi

	xcode-selected || sudo xcode-select -s "$XCODE_APP" || return
	xcodebuild -license check >/dev/null 2>&1 || sudo xcodebuild -license
}


# Install and upgrade everything in Brewfile.macos. brew bundle carries on past a
# package that fails (a download that times out, the App Store unreachable) and
# reports each failure in the middle of its output, so check afterwards and list
# whatever is still unsatisfied. The check also catches entries bundle skipped
# without saying so.
function install-brew-packages() {
	brew update
	brew bundle --file "$DIR/Brewfile.macos"

	# Once Xcode.app is installed, brew refuses to run until it is selected and its
	# license accepted, which would fail the check below with that error instead of
	# a list of what is missing.
	[ -d "$XCODE_APP" ] && install-xcode

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

# Write a Java trust store to $1 holding the roots of the JVM that runs coursier
# plus every certificate in the System and login keychains. Java reads one trust
# store, and neither candidate suffices alone: its own (cacerts) lacks the root a
# TLS-inspecting proxy re-signs HTTPS with, so Maven Central fails with "PKIX path
# building failed" where curl succeeds; the KeychainStore type holds that root but
# not the public CAs, so github.com, which the proxy leaves alone, fails the same
# way. Returns 1 when the JVM's keytool or cacerts cannot be found.
function build-jvm-truststore() {
	local dest=$1 java_home keytool certs cert
	java_home=$(java -XshowSettings:properties -version 2>&1 | sed -n 's/^ *java\.home = //p')
	keytool="$java_home/bin/keytool"
	[ -x "$keytool" ] && [ -f "$java_home/lib/security/cacerts" ] || return 1

	"$keytool" -importkeystore -noprompt \
		-srckeystore "$java_home/lib/security/cacerts" -srcstorepass changeit \
		-destkeystore "$dest" -deststoretype PKCS12 -deststorepass changeit >/dev/null 2>&1 || return 1

	certs=$(mktemp -d "${TMPDIR:-/tmp}/keychain-certs.XXXXXX")
	security find-certificate -a -p /Library/Keychains/System.keychain "$HOME/Library/Keychains/login.keychain-db" 2>/dev/null |
		awk -v dir="$certs" '/BEGIN CERTIFICATE/ { n++ } n { print > sprintf("%s/%03d.pem", dir, n) }'
	for cert in "$certs"/*.pem; do
		[ -e "$cert" ] || break
		"$keytool" -importcert -noprompt -alias "keychain-$(basename "$cert" .pem)" \
			-file "$cert" -keystore "$dest" -storepass changeit >/dev/null 2>&1
	done
	rm -rf "$certs"
}

# `cs` and the standard Scala tools only arrive through `coursier setup`; the
# brew formula provides just the `coursier` launcher. `cs` lands first, so a setup
# that fails partway leaves it behind: `scala` is the mark that it finished.
function install-coursier() {
	coursier-installed && return 0

	echo "Setting up Scala tooling with coursier"

	local bin="$HOME/Library/Application Support/Coursier/bin" log status reason
	local trust java_opts=${JAVA_OPTS:-}
	local noise='^[[:space:]]+at |^[[:space:]]+\.\.\. [0-9]+ more|^Caused by: |^Exception in thread |^WARNING: (.*sun\.misc\.Unsafe|Please consider reporting this to the maintainers)'
	log=$(mktemp "${TMPDIR:-/tmp}/coursier-setup.XXXXXX")

	# - coursier offers to add its bin directory to ~/.profile, ~/.zprofile and
	#   ~/.bash_profile, which are symlinks into this repo; profile.d/paths adds
	#   the directory itself once it exists. Having it on PATH for this call skips
	#   the offer, and the "n" on stdin declines it should it appear anyway.
	# - The JVM trusts what curl trusts (see build-jvm-truststore). Without the
	#   store it keeps Java's default and a TLS-inspecting proxy fails the run.
	# - The full output goes to $log; the screen drops Java stack frames and the
	#   sun.misc.Unsafe notice.
	trust=$(mktemp -d "${TMPDIR:-/tmp}/coursier-truststore.XXXXXX")
	if build-jvm-truststore "$trust/trust.p12"; then
		java_opts="-Djavax.net.ssl.trustStore=$trust/trust.p12 -Djavax.net.ssl.trustStorePassword=changeit $java_opts"
	fi
	JAVA_OPTS="$java_opts" \
	PATH="$bin:$PATH" \
		coursier setup <<<"n" 2>&1 | tee "$log" | grep -v -E "$noise"
	status=${PIPESTATUS[0]}
	rm -rf "$trust"

	if [ "$status" -eq 0 ]; then
		rm -f "$log"
		return 0
	fi

	reason=$(sed -n -E 's/^Exception in thread "[^"]*" [A-Za-z0-9_.$]+: ([A-Za-z0-9_.$]+: )?//p' "$log" | head -1)
	note-problem "coursier setup failed${reason:+: $reason}" \
		"This usually means it could not download from Maven Central or GitHub releases (network, proxy or certificate)." \
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
function coursier-installed() { is-installed cs && is-installed scala; }
function xcode-ready() { xcode-selected && xcodebuild -license check >/dev/null 2>&1; }
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
add-step install-xcode             "Select Xcode.app and accept its license"   xcode-ready
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
