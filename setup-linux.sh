#!/usr/bin/env bash

DIR=`cd $(dirname $0); pwd`
pushd $DIR >/dev/null

# Load shared setup functions
source "$DIR/setup-common.sh"

OPT=$1
shift


function install-apps() {
  sudo yum -y install $(cat $DIR/packages.clouddesktop.lst)

  mkdir -p $HOME/.local/bin >/dev/null
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



case $OPT in
"")
  apply-dotbot
  install-apps
  install-node
  install-spacevim
  install-zsh
  install-bash
  install-zellij
  ;;

*)
  $OPT $@
  ;;
esac

popd >/dev/null
