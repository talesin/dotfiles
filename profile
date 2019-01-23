# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

echo Profile

export LANG=en_US.UTF-8    
export LC_CTYPE=en_US.UTF-8

export LSCOLORS=gxfxcxdxbxegedabagacad
export LS_COLORS=di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

if [ -d "/usr/local/bin" ] ; then
    export PATH="/usr/local/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    export PATH="$HOME/bin:$PATH"
fi

if ! [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME=`/usr/libexec/java_home`
fi

if [ -z "$SCALA_HOME" ] && [ -e /usr/local/share/scala ]; then
    export SCALA_HOME="/usr/local/share/scala"
    export PATH="$PATH:$SCALA_HOME/bin"
fi

which -s stack >/dev/null
if [ $? -eq 0 ]; then
  export PATH=`stack path --bin-path 2>/dev/null`
fi

if [ -d "${HOME}/.local/bin" ]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

if [ -d "/usr/local/share/dotnet" ]; then
  export PATH="${PATH}:/usr/local/share/dotnet"
fi

if [ -d "/Library/Frameworks/Mono.framework/Versions/Current/bin" ]; then
  export PATH="${PATH}:/Library/Frameworks/Mono.framework/Versions/Current/bin"
fi

if [ -z "$SSH_AGENT_PID" ]; then
    eval `ssh-agent`
fi

export BYOBU_PYTHON=/usr/local/bin/python3

launchctl setenv PATH $PATH
_byobu_sourced=1 . /usr/local/Cellar/byobu/5.125/bin/byobu-launch 2>/dev/null || true
