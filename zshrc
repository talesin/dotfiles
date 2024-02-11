# echo zshrc

NOW=`date +%s`

if [[ -z $ZPROFILE_LOADED ]]; then
    source $HOME/.zprofile
fi

if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# load functions
typeset -U fpath
fdir=$HOME/.functions
if [[ -z ${fpath[(r)$fdir]} ]] ; then
    export fpath=($fdir $fpath)
    autoload -Uz ${fdir}/*(:t)
fi

refresh-sshkey

update-tools

# oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git vi-mode)
source $ZSH/oh-my-zsh.sh


# iterm & brew
if is-mac; then
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
  is-installed brew && eval "$(brew shellenv)"
fi


# zellij
if is-installed zellij; then
  export ZELLIJ_AUTO_ATTACH=true
  eval "$(zellij setup --generate-auto-start zsh)"
fi

