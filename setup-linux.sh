#!/usr/bin/env bash

DIR=`cd $(dirname $0); pwd`
pushd $DIR >/dev/null

OPT=$1
shift

function is-installed() {
	if [ ! $FORCE_INSTALL ]; then
		return 0
	else
		which $1 1>/dev/null 2>/dev/null
		return $?
	fi
}

function not-installed() {
	! is-installed $1
	return $?
}

function install-apps() {
  sudo yum -y install $(cat $DIR/packages.clouddesktop.lst)

  mkdir -p $HOME/.local/bin >/dev/null
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

function install-zellij() {
  if not-installed zellij; then
    if [ ! -f $HOME/.local/bin/zellij ]; then 
      echo "Installing zellij"
      mkdir -p /tmp/zellij >/dev/null
      pushd /tmp/zellij >/dev/null

      wget https://github.com/zellij-org/zellij/releases/download/v0.39.2/zellij-x86_64-unknown-linux-musl.tar.gz

      tar -xvf zellij*.tar.gz
      cp zellij $HOME/.local/bin
      chmod +x zellij

      rm -fr /tmp/zellij >/dev/null

      popd >/dev/null
    fi
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

function install-spacevim() {
	curl -sLf https://spacevim.org/install.sh | bash
}

function install-zsh() {
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

case $OPT in
"")
  install-dotbot
  install-apps
  install-node
  install-spacevim
  install-zsh
  install-bash
  install-zellij
  ;;

*)
  check-midway
  $OPT $@
  ;;
esac

popd >/dev/null
