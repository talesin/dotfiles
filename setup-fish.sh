#!/usr/bin/env bash
DIR=`cd $(dirname $0); pwd`

curl -s -L https://get.oh-my.fish > omf-install.fish
fish omf-install.fish --noninteractive
rm omf-install.fish
fish -c omf theme install agnoster
fish -c omf theme agnoster
fish -c omf install bass
grep -sq fish /etc/shells
if [ $? -eq 1 ]; then
    sudo sh -c "echo /usr/local/bin/fish >> /etc/shells"
fi