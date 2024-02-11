#!/usr/bin/env bash

DIR=`cd $(dirname $0); pwd`
pushd $DIR >/dev/null

OPT=$1
shift

function is-installed() {
	which $1 >/dev/null
	return $?
}

function not-installed() {
	! is-installed $1
	return $?
}

function check-midway() {
	if not-installed mwinit; then
		echo "Install mwinit from Self Service"
		exit 1
	fi

	NOW=`date +%s`
	EXPIRES=`date -jf '%FT%T' $(ssh-keygen -L -f $HOME/.ssh/id_ecdsa-cert.pub | grep Valid | sed 's/^ *//;s/ *$//' | cut -d $' ' -f 5) +%s`
	if [[ $NOW -ge $EXPIRES ]]; then
		echo "*** Midway ***"
		mwinit -s --aea
	fi
}

function check-toolbox() {
	if not-installed toolbox; then
		open "jamfselfservice://"
		echo "Install toolbox from Self Service"
		exit 1
	fi
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

function install-brew() {
	if not-installed brew; then
		echo "Installing brew"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	brew tap amazon/homebrew-amazon ssh://git.amazon.com/pkg/HomebrewAmazon
	brew tap coursier/formulas

	brew analytics off
}


function install-apps() {
	brew update
	brew bundle

	python3 -m pip install --upgrade pip

    grep -sq /usr/local/bin/bash /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/bash >> /etc/shells"
    fi

    grep -sq /usr/local/bin/zsh /etc/shells
    if [ $? -eq 1 ]; then
        sudo sh -c "echo /usr/local/bin/zsh >> /etc/shells"
    fi

	if [ ! -f $HOME/.iterm2_shell_integration.zsh ]; then
		echo "Configuring iterm shell integration"
		curl -sL https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
	fi

	if not-installed cs; then
		coursier setup
	fi

}

function install-node() {
	if not-installed nvm; then
		NVM_VERSION=$(curl -sL https://raw.githubusercontent.com/nvm-sh/nvm/master/package.json | jq -r '.version')
		PROFILE=/dev/null bash -c "curl -sL -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash"
		export NVM_DIR="$HOME/.nvm"
		[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	fi

	nvm install 16
	nvm use 16

	brazil setup --node
	npm install -g typescript cdk
}

function setup-vscode() {
	# https://w.amazon.com/bin/view/VisualStudioCode/
	# https://w.amazon.com/bin/view/VSCodeCloudDesktop/

	# install extensions
	cat vscode.extensions.lst | xargs -t -L 1 code --install-extension	>/dev/null

	# install viceroy
	pushd /tmp >/dev/null
	mcurl -o vscode-brazil.vsix -sL "https://code.amazon.com/packages/Viceroy/releases/1.0/latest_artifact?version_set=Viceroy/release&path=ext/vscode-brazil.vsix&download=true" 
	code --install-extension vscode-brazil.vsix >/dev/null
	rm -f vscode-brazil.vsix >/dev/null
	popd >/dev/null
}

function install-amazon-apps() {
	toolbox registry add s3://buildertoolbox-registry-hub-create-us-west-2/tools.json
	toolbox registry add s3://buildertoolbox-registry-isengard-cli-us-west-2/tools.json
	toolbox install $(cat packages.toolbox.lst | xargs echo)

	axe init builder-tools

	if not-installed brazil; then
		echo "Reboot and rerun installation to complete brazil installation"
	else
		echo "Installing brazil"
		brazil setup completion
	fi
}

function install-spacevim() {
	curl -sLf https://spacevim.org/install.sh | bash
}


function install-zsh() {
	if [ $SHELL != "/usr/local/bin/zsh" ]; then
		echo "Change shell to zsh"
		sudo chsh -s /usr/local/bin/zsh
	fi

	if [ ! -d $HOME/.oh-my-zsh ]; then
		echo "Installing oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
}

function install-bash() {
	if [ ! -d $HOME/.oh-my-bash ]; then
		echo "Installing oh-my-bash"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
	fi
}

function install-dotbot() {
	pushd $HOME >/dev/null
	if [ ! -d $HOME/.dotfiles ]; then
		git clone ssh://git.amazon.com/pkg/Jeclough-dotfiles $HOME/.dotfiles
	fi

	$HOME/.dotfiles/install
	popd >/dev/null
}

function install-powerline() {
	pushd /tmp >/dev/null

	ls ~/Library/Fonts | grep -i powerline >/dev/null
	if [ ! $? -eq 0 ]; then
		PATH="/usr/local/opt/python/libexec/bin:${PATH}" pip install --user powerline-status

		git clone https://github.com/powerline/fonts.git --depth=1
		cd fonts
		./install.sh
		cd ..
		rm -fr fonts
	fi

	popd >/dev/null
}

function install-chrome() {
	if [ ! -d "/Applications/Google Chrome.app" ]; then
		brew install --cask google-chrome
	fi

	# TBD - https://superuser.com/questions/1650457/installing-chrome-extension-via-cli

	# tamper monkey
	if [ ! -d $HOME/Library/Application\ Support/Google/Chrome/Default/Extensions/dhdgffkkebhmkfjojejmpbldmpobfkfo ]; then
		chrome-cli open "https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?pli=1"

		# https://w.amazon.com/bin/view/Greasemonkey/PhoneTool
		# factorum
		chrome-cli open "https://axzile.corp.amazon.com/-/carthamus/download_script/job-finder-phone-tool-who's-hiring!%3F!.user.js"

		# hyperbadge
		chrome-cli open "https://userscript.hyperbadge.amazon.dev/hyperbadge.user.js"

		# job history
		chrome-cli open "https://ekarulf.corp.amazon.com/job-history/job-history.user.js"
	fi

}

case $OPT in
"")
	check-midway
	check-toolbox
	install-dotbot
	install-brew
	install-apps
	install-xcode
	install-node
	install-amazon-apps
	install-powerline
	install-zsh
	install-bash
	install-chrome
	setup-vscode
	;;

*)
	check-midway
	$OPT $@
	;;
esac

popd >/dev/null
