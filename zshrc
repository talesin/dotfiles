#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
alias cls=clear
alias ls='ls -Gh'
alias 'ls-al'='ls -al'
alias 'cd..'='cd ..'
alias 'cd...'='cd ...'

export PATH="~/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"

if [ "$(uname -s)" = "Darwin" ]; then
  export ARCHFLAGS="-arch x86_64"
  export VAGRANT_DEFAULT_PROVIDER="virtualbox"
  export JAVA_HOME=`/usr/libexec/java_home`

  export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/usr/libexec/git-core:/Applications/Xcode.app//Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin


  export NVM_DIR=~/.nvm
  source $(brew --prefix nvm)/nvm.sh
  nvm use stable > /dev/null

  export PATH="$HOME/bin:$HOME/.rvm/bin:$PATH" # Add RVM to PATH for scripting

  if [ `boot2docker status` != "running" ]; then
    echo "Starting boot2docker"
    boot2docker up
  fi

  $(boot2docker shellinit 2> /dev/null)

  docker-ip() {
    boot2docker ip 2> /dev/null
  }

  #export LC_BYOBU=1
  export PATH="/usr/local/sbin:$PATH"
fi
