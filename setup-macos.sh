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
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		export PATH=/opt/homebrew/bin:$PATH
	fi

	brew tap coursier/formulas

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


function install-apps() {
	brew update
	brew bundle

	python3 -m pip install --upgrade pip

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

	if not-installed cs; then
		coursier setup
	fi

	if [ ! -f $HOME/.config/gitconfig.local ]; then
		mkdir -p $HOME/.config 2>/dev/null
		touch $HOME/.config/gitconfig.local
	fi
}

function install-node-extras() {
	npm install -g typescript cdk
}

function setup-vscode() {
	# install extensions
	cat vscode.extensions.lst | xargs -t -L 1 code --install-extension	>/dev/null
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
		PATH="/opt/homebrew/bin:${PATH}" pip install --user powerline-status

		git clone https://github.com/powerline/fonts.git --depth=1
		cd fonts
		./install.sh
		cd ..
		rm -fr fonts
	fi

	popd >/dev/null
}

case $OPT in
"")
	install-brew
	install-apps
	apply-dotbot
	install-xcode
	install-node
	install-node-extras
	install-powerline
	install-zsh-macos
	install-bash
	setup-vscode
	;;

*)
	$OPT $@
	;;
esac

popd >/dev/null
