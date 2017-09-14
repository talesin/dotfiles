# vi: set expandtab:
# vi: noai:ts=2:sw=2
# Source Prezto.

# echo "Running zshrc"

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
alias cls=clear


alias ls='"ls" -Gh'
alias 'ls-al'='ls -al'
alias 'cd..'='cd ..'
alias 'cd...'='cd ...'


if [[ `which -s nvim` ]]; then
  alias vimdiff='nvim -d'
  alias vim="nvim"
  alias vi="nvim"
  export EDITOR=nvim
  export VISUAL=nvim
else
  export EDITOR=vim
  export VISUAL=vim
fi

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

    export BREW_PREFIX=$(brew --prefix)
    export BYOBU_PREFIX=$BREW_PREFIX

    export LDFLAGS="-L/usr/local/opt/openssl/lib"
    export CPPFLAGS="-I/usr/local/opt/openssl/include"

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
#eval $(/usr/libexec/path_helper -s)


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh ]] && . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh ]] && . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh
