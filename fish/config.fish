# read -sk# vi: set expandtab:
# vi: noai:ts=2:sw=2

fish_vi_key_bindings

test -e {$HOME}/.iterm2_shell_integration.endsh ; and source {$HOME}/.iterm2_shell_integration.endsh

function append-path
  set dir $argv
  if not contains $dir $PATH
    and test -d $dir
    echo "Appending $dir"
    set -U PATH $PATH $dir
  end
end

function prepend-path
  set dir $argv
  if not contains $dir $PATH
    and test -d $dir
    echo "Prepending $dir"
    set -U PATH $dir $PATH
  end
end

function whch
  which $argv > /dev/null
end

alias cls=clear
alias 'ls-al'='ls -al'
alias 'cd..'='cd ..'
alias 'cd...'='cd ...'

if whch nvim
  alias vimdiff='nvim -d'
  alias vim="nvim"
  alias vi="nvim"
  set -U EDITOR nvim
  set -U VISUAL nvim
else
  set -U EDITOR vim
  set -U VISUAL vim
end

set -U VISUAL $EDITOR

if [ -z $FISHENV ]
  if not test -d $HOME/.local/bin
    mkdir $HOME/.local/bin
  end

  set -U PATH $HOME/.local/bin /usr/local/bin /usr/local/sbin /usr/bin /bin

  if whch brew
    set -U PYTHON_BIN (brew --prefix)/opt/python/libexec/bin
    prepend-path $PYTHON_BIN

    set -U GROOVY_HOME (brew --prefix)/opt/groovy/libexec
    prepend-path $GROOVY_HOME
  end


  # if whch stack
  #   set stack_path (stack path --bin-path 2>/dev/null)
  #   export PATH=$stack_path
  # end

  prepend-path "/usr/local/sbin"
  prepend-path "/usr/local/bin"
  prepend-path "$HOME/.local/bin"

  append-path "/Applications/Xcode.app/Contents/Developer/usr/libexec/git-core"
  append-path "/Applications/Xcode.app//Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
  append-path "/usr/local/share/dotnet"
  append-path "/Library/Frameworks/Mono.framework/Versions/Current/bin"

  append-path "/bin"
  append-path "/usr/bin"
  append-path "/usr/sbin"
  append-path "/sbin"
  append-path "/opt/X11/bin"


  set -U FISHENV 1
end

eval (direnv hook fish)

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.fish ]; and . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.fish
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.fish ]; and . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.fish
