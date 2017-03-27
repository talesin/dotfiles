# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/jeremy/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/jeremy/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/jeremy/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/jeremy/.fzf/shell/key-bindings.bash"

