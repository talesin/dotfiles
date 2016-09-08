# vi: set expandtab:
# vi: noai:ts=2:sw=2
# Source Prezto.

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
alias cls=clear


alias ls='"ls" -Gh'
alias 'ls-al'='ls -al'
alias 'cd..'='cd ..'
alias 'cd...'='cd ...'

export PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:$PATH"
export EDITOR=vim
export VISUAL="$EDITOR"

autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd v edit-command-line

case "$(uname -s)" in
  Darwin)

    export ARCHFLAGS="-arch x86_64"
    export VAGRANT_DEFAULT_PROVIDER="virtualbox"
    export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
    export PROMPT='${SSH_TTY:+"%F{9}%n%f%F{7}@%f%F{3}%m%f "}%F{6}${_prompt_sorin_pwd}%(!. %B%F{1}#%f%b.)${editor_info[keymap]} '

    if ! [ -z "$JAVA_HOME" ]; then
      export JAVA_HOME=`/usr/libexec/java_home`
    fi

    export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/usr/libexec/git-core:/Applications/Xcode.app//Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin

    export BREW_PREFIX=$(brew --prefix)
    export BYOBU_PREFIX=$BREW_PREFIX

    export LDFLAGS="-L/usr/local/opt/openssl/lib"
    export CPPFLAGS="-I/usr/local/opt/openssl/include"

    if [ `which -s docker-machine` 2>/dev/null ]; then
      if [ `docker-machine status default` != "Running" ]; then
        echo "Starting docker machine default"
        docker-machine start default
      fi

      eval "$(docker-machine env default)"
    fi

    #export LC_BYOBU=1
    export PATH="/usr/local/sbin:$PATH"

    if [ -e /usr/local/share/zsh/site-functions/_aws ]; then
      source /usr/local/share/zsh/site-functions/_aws
    fi

    fpath=(/usr/local/share/zsh-completions $fpath)
  ;;

  Linux)
    echo "Linux"
  ;;

esac

#export LC_BYOBU=0
