# echo "zshenv start"

# Zsh-specific configuration
NOW=`date +%s`

# Load functions (zsh-specific)
typeset -U fpath
fdir=$HOME/.functions
if [[ -z ${fpath[(r)$fdir]} ]] ; then
    export fpath=($fdir $fpath)
    autoload -Uz ${fdir}/*(:t)
fi

# Oh My Zsh (zsh-specific)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git vi-mode)
source $ZSH/oh-my-zsh.sh

# Load shared shell configuration
source ~/.shell-common.sh

# echo "zshenv end"