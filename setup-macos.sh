#!/usr/bin/env bash


DIR=$HOME/.dotfiles
mkdir -p $DIR 2>/dev/null
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

function install-brew() {
	if not-installed brew; then
		echo "Installing brew"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		export PATH=/opt/homebrew/bin:$PATH
	fi

	brew tap coursier/formulas

	brew analytics off
}

function setup-dotbot() {
	pip install dotbot --force
	dotbot -c $DIR/install.conf.yaml
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

	python -m pip install --upgrade pip

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

function install-node() {
	if not-installed nvm; then
		NVM_VERSION=$(curl -sL https://raw.githubusercontent.com/nvm-sh/nvm/master/package.json | jq -r '.version')
		PROFILE=/dev/null bash -c "curl -sL -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash"
		export NVM_DIR="$HOME/.nvm"
		[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	fi

	npm install -g typescript cdk
}

function setup-vscode() {
	# install extensions
	cat vscode.extensions.lst | xargs -t -L 1 code --install-extension	>/dev/null
}

function install-spacevim() {
	curl -sLf https://spacevim.org/install.sh | bash
}


function install-zsh() {
	if [ $SHELL != "/opt/homebrew/bin/zsh " ]; then
		echo "Change shell to zsh"
		sudo chsh -s /opt/homebrew/bin/zsh 
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
	setup-dotbot
	install-xcode
	install-node
	install-powerline
	install-zsh
	install-bash
	setup-vscode
	;;

*)
	$OPT $@
	;;
esac

popd >/dev/null
