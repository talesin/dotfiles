# echo zshrc start

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

#refresh-sshkey

update-tools

# oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git vi-mode)
source $ZSH/oh-my-zsh.sh

# iterm
if is-mac; then
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

eval "$(brew shellenv)"


eval "$(direnv hook zsh)"

# zsh parameter completion for the dotnet CLI
if is-installed dotnet; then
  _dotnet_zsh_complete()
  {
    local completions=("$(dotnet complete "$words")")

    # If the completion list is empty, just continue with filename selection
    if [ -z "$completions" ]
    then
      _arguments '*::arguments: _normal'
      return
    fi

    # This is not a variable assignment, don't remove spaces!
    _values = "${(ps:\n:)completions}"
  }

  compdef _dotnet_zsh_complete dotnet
fi

# zellij
if is-installed zellij; then
  export ZELLIJ_AUTO_ATTACH=true
  eval "$(zellij setup --generate-auto-start zsh)"
fi

# echo zshrc end
