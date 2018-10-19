# read -sk# vi: set expandtab:
# vi: noai:ts=2:sw=2

fish_vi_key_bindings

test -e {$HOME}/.iterm2_shell_integration.fish; and source {$HOME}/.iterm2_shell_integration.fish

if [ -z $LANG ]
    set -U LANG en_US.UTF-8
    set -U LC_CTYPE en_US.UTF-8
end

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
    which $argv >/dev/null 2>/dev/null
end

alias cls=clear
alias 'ls-al'='ls -al'
alias 'cd..'='cd ..'
alias 'cd...'='cd ...'

if whch nvim
    alias vimdiff='nvim -d'
    alias vim="nvim"
    alias vi="nvim"
    set -Ux EDITOR nvim
    set -Ux VISUAL nvim
else
    set -Ux EDITOR vim
    set -Ux VISUAL vim
end

set -U VISUAL $EDITOR

if [ -z $FISHENV ]
    set -Ux INITIAL_TERM_PROGRAM $TERM_PROGRAM
    set -Ux LSCOLORS gxfxcxdxbxegedabagacad
    set -Ux LS_COLORS 'di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

    ssh-add

    if not test -d $HOME/.local/bin
        mkdir $HOME/.local/bin
    end

    set -U PATH $HOME/.local/bin /usr/local/bin /usr/local/sbin /usr/bin /bin

    if whch brew
        set BREW_PREFIX (brew --prefix)
        set -Ux PYTHON_BIN $BREW_PREFIX/opt/python/libexec/bin
        prepend-path $PYTHON_BIN

        set -Ux GROOVY_HOME $BREW_PREFIX/opt/groovy/libexec
        prepend-path $GROOVY_HOME
    end


    if whch stack
      append-path (stack path --bin-path 2>/dev/null)
    end

    prepend-path "/usr/local/sbin"
    prepend-path "/usr/local/bin"
    prepend-path "$HOME/.local/bin"

    append-path "/Applications/Xcode.app/Contents/Developer/usr/libexec/git-core"
    append-path "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
    append-path "/usr/local/share/dotnet"
    append-path "/Library/Frameworks/Mono.framwork/Versions/Current/bin"

    append-path "/bin"
    append-path "/usr/bin"
    append-path "/usr/sbin"
    append-path "/sbin"
    append-path "/opt/X11/bin"

    set -Ux FISHENV 1
else
    set -Ux FISHENV (math $FISHENV + 1)
end

if whch direnv
    eval (direnv hook fish)
end

if [ $TERM_PROGRAM = $INITIAL_TERM_PROGRAM ]
    set -Ux BYOBU_PYTHON (which python3)
    status --is-login; and status --is-interactive; and exec byobu-launcher
end

# echo "FISHENV=$FISHENV TERM_PROGRAM=$TERM_PROGRAM INITIAL_TERM_PROGRAM=$INITIAL_TERM_PROGRAM"

