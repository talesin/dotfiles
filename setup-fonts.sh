#!/usr/bin/env bash
DIR=`cd $(dirname $0); pwd`

PATH="/usr/local/opt/python/libexec/bin:${PATH}" pip install --user powerline-status

git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -fr fonts
