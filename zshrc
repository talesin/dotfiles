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

case "$(uname -s)" in
  Darwin)

          export ARCHFLAGS="-arch x86_64"
          export VAGRANT_DEFAULT_PROVIDER="virtualbox"

          if ! [ -z "$JAVA_HOME" ]; then
            export JAVA_HOME=`/usr/libexec/java_home`
          fi

          export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/usr/libexec/git-core:/Applications/Xcode.app//Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin

          export BREW_PREFIX=$(brew --prefix)
          export BYOBU_PREFIX=$BREW_PREFIX

          if [ -f $BREW_PREFIX/nvm.sh ]; then
            export NVM_DIR=~/.nvm
            source $BREW_PREFIX/nvm.sh
            nvm use stable > /dev/null
          fi

          if [ -e $HOME/.rvm ]; then
            export PATH="$HOME/bin:$HOME/.rvm/bin:$PATH" # Add RVM to PATH for scripting
          fi

          if [ `which -s boot2docker` ]; then
            if [ `boot2docker status` != "running" ]; then
              echo "Starting boot2docker"
              boot2docker up
            fi

            $(boot2docker shellinit 2> /dev/null)

            docker-ip() {
              boot2docker ip 2> /dev/null
            }
          fi

          #export LC_BYOBU=1
          export PATH="/usr/local/sbin:$PATH"
  ;;

  Linux)
          echo "Linux"
  ;;

esac
