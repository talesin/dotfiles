# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export LSCOLORS=gxfxcxdxbxegedabagacad
export LS_COLORS=di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;4

if is-installed launchctl; then
  launchctl setenv PATH $PATH
fi


# >>> coursier install directory >>>
export PATH="$PATH:/Users/jeremy/Library/Application Support/Coursier/bin"
# <<< coursier install directory <<<
. "$HOME/.cargo/env"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/jeremy/.lmstudio/bin"
