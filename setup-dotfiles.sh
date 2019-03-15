#!/usr/bin/env bash
DIR=`cd $(dirname $0); pwd`

if ! [ -d "$HOME/.dotfiles" ]; then
    git clone --recurse-submodules https://github.com/talesin/dotfiles.git $HOME/.dotfiles
fi
pushd $HOME/.dotfiles
./install
popd
