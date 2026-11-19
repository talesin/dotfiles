# echo "zshenv start"

# Zsh-specific configuration
NOW=`date +%s`


# Local completions
fpath=(~/.local/share/zsh/completions $fpath)

# Oh My Zsh (zsh-specific)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
# Set ZSH_PLUGINS in ~/.config/env.local to change the plugin list
(( ${+ZSH_PLUGINS} )) || ZSH_PLUGINS=(git vi-mode)
plugins=($ZSH_PLUGINS)
source $ZSH/oh-my-zsh.sh

# Load shared shell configuration
source ~/.shell-common.sh

# echo "zshenv end"

# Zellij resurrection for shell functions. Zellij saves a pane by the argv of
# its foreground process, so a pane running a shell function is saved as the
# bare command the function launched, without the function's flags or
# environment. While an allowlisted function runs, register the typed line as
# the pane's resurrect command; clear it once the pane is back at its prompt.
# Only lines whose first word is the function are registered.
if [[ -n "$ZELLIJ" ]] && is-installed zellij; then
  (( ${+ZELLIJ_RESURRECT_FUNCTIONS} )) || ZELLIJ_RESURRECT_FUNCTIONS=(claude)
  autoload -Uz add-zsh-hook

  _zellij_resurrect_preexec() {
    local line=${1:-$3}
    local first=${${(z)line}[1]}
    (( ${ZELLIJ_RESURRECT_FUNCTIONS[(Ie)$first]} )) || return 0
    [[ "$(whence -w -- "$first" 2>/dev/null)" == *": function" ]] || return 0
    zellij action set-resurrect-command -- "$SHELL" -ic "$line" >/dev/null 2>&1
    _zellij_resurrect_set=1
    return 0
  }

  _zellij_resurrect_precmd() {
    [[ -n "$_zellij_resurrect_set" ]] || return 0
    unset _zellij_resurrect_set
    zellij action set-resurrect-command --clear >/dev/null 2>&1
    return 0
  }

  add-zsh-hook preexec _zellij_resurrect_preexec
  add-zsh-hook precmd _zellij_resurrect_precmd
fi
