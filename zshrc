# echo "zshenv start"

# Zsh-specific configuration
NOW=`date +%s`


# Local completions
fpath=(~/.local/share/zsh/completions $fpath)

# Oh My Zsh (zsh-specific)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git vi-mode)
source $ZSH/oh-my-zsh.sh

# Load shared shell configuration
source ~/.shell-common.sh

# echo "zshenv end"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/jeremy/.lmstudio/bin"
# End of LM Studio CLI section

