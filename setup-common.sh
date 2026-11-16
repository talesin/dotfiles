#!/usr/bin/env bash
# Common setup functions shared across platform-specific setup scripts

DOTFILES_DIR=${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# Check if running under WSL
function is-wsl() {
    [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease
}

# Print zellij's plugin directory for this OS. Does not require zellij to be
# installed, so it is safe to call before install-zellij has run.
function zellij-plugin-dir() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        printf '%s' "$HOME/Library/Application Support/org.Zellij-Contributors.Zellij/plugins"
    else
        printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/zellij/plugins"
    fi
}

# Grant the tab-title plugin its permissions by seeding zellij's permission
# cache. The grant prompt renders in a plugin's pane, and a background plugin
# loaded from load_plugins has no pane, so the prompt never reaches the user
# and the plugin waits forever. The cache key is the config's file: path
# verbatim (zellij never resolves it), so it is the same on every machine.
# Skipped when the key is already present, whether seeded or granted live.
function seed-zellij-plugin-permissions() {
    local cache_file
    if [[ "$(uname -s)" == "Darwin" ]]; then
        cache_file="$HOME/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl"
    else
        cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/zellij/permissions.kdl"
    fi

    if [[ -f "$cache_file" ]] && grep -q "zellij-tab-title.wasm" "$cache_file"; then
        return 0
    fi

    mkdir -p "$(dirname "$cache_file")"
    cat >> "$cache_file" <<'EOF'
"zellij-tab-title.wasm" {
    ReadApplicationState
    ChangeApplicationState
}
EOF
    echo "  granted zellij-tab-title.wasm permissions in $cache_file"
}

# Check if a command is available
function is-installed() {
    command -v "$1" >/dev/null 2>&1
}

# Inverse of is-installed
function not-installed() {
    ! is-installed "$1"
}

# Problems found while a setup script runs. A failed step is recorded and the
# script carries on, so one flaky download does not strand the steps after it;
# report-problems prints them together at the end, where they are not buried in
# the output of the steps that worked.
SETUP_PROBLEMS=()

# Record a problem: note-problem <summary> [<detail line>...]. The summary is
# echoed now; the detail lines appear only in the final report.
function note-problem() {
    SETUP_PROBLEMS+=("$(printf '%s\n' "$@")")
    echo "  ! $1" >&2
}

# Run a setup step (a function or command). A non-zero exit is recorded as a
# problem with a retry command; the script's functions are all runnable by name.
function run-step() {
    local status
    "$@"
    status=$?
    if [ "$status" -ne 0 ]; then
        note-problem "$1 failed (exit status $status)" \
            "The output above has the details." \
            "Retry: $0 $1"
    fi
}

# Print every recorded problem and return 1, or return 0 when there are none.
function report-problems() {
    local count=${#SETUP_PROBLEMS[@]} entry line first
    [ "$count" -eq 0 ] && return 0

    echo
    if [ "$count" -eq 1 ]; then
        echo "Setup finished, but 1 step needs attention:"
    else
        echo "Setup finished, but $count steps need attention:"
    fi
    for entry in "${SETUP_PROBLEMS[@]}"; do
        echo
        first=1
        while IFS= read -r line; do
            if [ "$first" -eq 1 ]; then
                echo "  * $line"
                first=0
            else
                echo "      $line"
            fi
        done <<<"$entry"
    done
    return 1
}

# Print the latest release tag for a GitHub repo (e.g. "PowerShell/PowerShell").
# Returns 1 and prints an error if the API call fails or returns no tag.
# grep -o anchors on the tag_name key so a `"tag_name": null` release or
# minified JSON body can't be mistaken for a real tag (both previously slipped
# past a bare `[ -z ]` check with `curl -s` and a greedy sed).
function latest-github-tag() {
    local repo="$1" tag
    tag=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep -o '"tag_name": *"[^"]*"' | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
    if [ -z "$tag" ]; then
        echo "Error: failed to fetch latest release tag for ${repo} from GitHub API" >&2
        return 1
    fi
    printf '%s' "$tag"
}

# Print the path to a real (non-shim) pwsh interpreter, or return 1 if none.
# Canonical implementation lives in functions/native-pwsh so the interactive
# shell (shell-common.sh) and setup share one copy.
function native-pwsh() {
    source "$DOTFILES_DIR/functions/native-pwsh"
}

# Install Node.js via NVM
function install-node() {
    export NVM_DIR="$HOME/.nvm"

    # Check if NVM is installed (it's a shell function, not a binary)
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "Installing nvm"
        # Use latest stable NVM version
        NVM_VERSION=$(latest-github-tag nvm-sh/nvm) || return 1
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    fi

    # Load NVM
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    if not-installed node; then
        echo "Installing node"
        nvm install node
        nvm use node
    fi
}

# Install Zsh and Oh My Zsh
function install-zsh() {
    if not-installed zsh; then
        echo "Installing zsh"
        if is-installed apt-get; then
            sudo apt-get install -y zsh
        elif is-installed dnf; then
            sudo dnf install -y zsh
        elif is-installed yum; then
            sudo yum install -y zsh
        elif is-installed brew; then
            brew install zsh
        fi
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing oh-my-zsh"
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

# Install Bash and Oh My Bash
function install-bash() {
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        echo "Installing oh-my-bash"
        OSH_UNATTENDED=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    fi
}

# True when this run can prompt: a terminal on stdin and stdout, and no --yes.
function setup-interactive() {
    [ -t 0 ] && [ -t 1 ] && [ "${SETUP_YES:-0}" != 1 ]
}

# Seed the per-machine ~/.gitconfig with the user identity. link-gitconfig
# creates that file empty, so the gate is the identity itself, not the file.
# Without a terminal to ask on, the missing identity is recorded as a problem.
function seed-gitconfig() {
    local git_name git_email
    git_name=$(git config --file "$HOME/.gitconfig" user.name 2>/dev/null)
    git_email=$(git config --file "$HOME/.gitconfig" user.email 2>/dev/null)
    [ -n "$git_name" ] && [ -n "$git_email" ] && return 0

    # A ~/.gitconfig that is still a symlink into the repo would take the
    # identity into the tracked file; apply-dotfiles replaces the symlink.
    if [ -L "$HOME/.gitconfig" ]; then
        note-problem "seed-gitconfig skipped: ~/.gitconfig is a symlink" \
            "Run apply-dotfiles first, which replaces it with a per-machine file." \
            "Retry: $0 seed-gitconfig"
        return 0
    fi

    if ! setup-interactive; then
        note-problem "seed-gitconfig skipped: no terminal to ask for the git identity" \
            "Retry: $0 seed-gitconfig"
        return 0
    fi

    while [ -z "$git_name" ]; do
        read -rp "Git name: " git_name || return 1
    done
    while [ -z "$git_email" ]; do
        read -rp "Git email: " git_email || return 1
    done

    git config --file "$HOME/.gitconfig" user.name "$git_name"
    git config --file "$HOME/.gitconfig" user.email "$git_email"
}

# Done-check for seed-gitconfig
function git-identity-set() {
    [ -n "$(git config --file "$HOME/.gitconfig" user.name 2>/dev/null)" ] &&
        [ -n "$(git config --file "$HOME/.gitconfig" user.email 2>/dev/null)" ]
}

# Done-checks for the shared install steps
function node-installed() {
    [ -s "$HOME/.nvm/nvm.sh" ] && is-installed node
}

function zsh-installed() {
    is-installed zsh && [ -d "$HOME/.oh-my-zsh" ]
}

function bash-installed() {
    [ -d "$HOME/.oh-my-bash" ]
}

# Create a symlink, removing any existing file/symlink
function link-dotfile() {
    local src="$1" dest="$2"
    if [ -z "$dest" ]; then
        echo "Error: link-dotfile requires a destination path" >&2
        return 1
    fi
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    ln -sfn "$src" "$dest"
    echo "  $dest -> $src"
}

# Link the shared git config to the XDG location and keep ~/.gitconfig as an
# untracked per-machine file. Git reads ~/.gitconfig after the XDG file, so its
# settings win, and `git config --global` writes there whenever it exists; Git
# Credential Manager records per-organisation settings that way, which must stay
# out of the repo.
function link-gitconfig() {
    local dotfiles_dir="$1"
    local legacy="$HOME/.config/gitconfig.local"

    link-dotfile "$dotfiles_dir/gitconfig" "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"

    # Earlier layout: ~/.gitconfig was the symlink into the repo and the
    # per-machine settings lived in ~/.config/gitconfig.local.
    if [ -L "$HOME/.gitconfig" ]; then
        rm "$HOME/.gitconfig"
    fi
    if [ -f "$legacy" ] && [ ! -e "$HOME/.gitconfig" ]; then
        mv "$legacy" "$HOME/.gitconfig"
        echo "  moved $legacy to $HOME/.gitconfig"
    fi

    [ -e "$HOME/.gitconfig" ] || touch "$HOME/.gitconfig"
}

# Apply dotfile symlinks
function apply-dotfiles() {
    local dotfiles_dir="${1:-$DOTFILES_DIR}"

    echo "Applying dotfile symlinks..."

    link-dotfile "$dotfiles_dir/aliases" ~/.aliases
    link-dotfile "$dotfiles_dir/vimrc" ~/.vimrc
    link-dotfile "$dotfiles_dir/bashrc" ~/.bashrc
    link-dotfile "$dotfiles_dir/bash_profile" ~/.bash_profile
    link-gitconfig "$dotfiles_dir"
    link-dotfile "$dotfiles_dir/profile" ~/.profile
    link-dotfile "$dotfiles_dir/zshenv" ~/.zshenv
    link-dotfile "$dotfiles_dir/zshrc" ~/.zshrc
    link-dotfile "$dotfiles_dir/zprofile" ~/.zprofile
    link-dotfile "$dotfiles_dir/functions" ~/.functions
    link-dotfile "$dotfiles_dir/zellij.kdl" ~/.config/zellij/config.kdl
    link-dotfile "$dotfiles_dir/zellij-layouts" ~/.config/zellij/layouts
    link-dotfile "$dotfiles_dir/zellij-plugins/zellij-tab-title.wasm" "$(zellij-plugin-dir)/zellij-tab-title.wasm"
    seed-zellij-plugin-permissions
    link-dotfile "$dotfiles_dir/direnv.toml" ~/.config/direnv/direnv.toml
    link-dotfile "$dotfiles_dir/profile.d" ~/.profile.d
    link-dotfile "$dotfiles_dir/shell-common.sh" ~/.shell-common.sh

    # Symlink scripts to ~/.local/bin (WSL only)
    if is-wsl && [ -d "$dotfiles_dir/scripts" ]; then
        mkdir -p "$HOME/.local/bin"
        for script in "$dotfiles_dir/scripts"/*; do
            [ -f "$script" ] && link-dotfile "$script" "$HOME/.local/bin/$(basename "$script")"
        done
    fi

    echo "Done."
}

# Step registry. A platform script registers its steps in run order with
# add-step, then hands control to run-setup. Step names are function names, so
# the menu, --skip, the positional form and the "Retry: $0 <name>" hints share
# one vocabulary. The arrays are parallel, indexed by registration order.
STEP_FUNCS=()
STEP_DESCS=()
STEP_CHECKS=()
STEP_DONE=()
STEP_DEFAULTS=()
STEP_SELECTED=()

SETUP_YES=0
SETUP_DRY_RUN=0
SETUP_LIST=0
SETUP_HELP=0
SETUP_SKIP=()
SETUP_NAMED=()

# add-step <function> <description> [<done-check>]. The done-check is a
# function that returns 0 when the step has nothing left to do; it must be
# cheap and free of side effects (no network, no sudo). Steps without one are
# always offered ticked.
function add-step() {
    STEP_FUNCS+=("$1")
    STEP_DESCS+=("$2")
    STEP_CHECKS+=("${3:-}")
}

# Print the index of a registered step, or return 1.
function step-index() {
    local i
    for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
        if [ "${STEP_FUNCS[$i]}" = "$1" ]; then
            printf '%s' "$i"
            return 0
        fi
    done
    return 1
}

function step-skipped() {
    local s
    for s in ${SETUP_SKIP[@]+"${SETUP_SKIP[@]}"}; do
        [ "$s" = "$1" ] && return 0
    done
    return 1
}

# Parse the command line into SETUP_*. Flags come first; the first other word
# names a step or function and the rest are its arguments.
function parse-setup-args() {
    local value name
    local -a names
    SETUP_YES=0 SETUP_DRY_RUN=0 SETUP_LIST=0 SETUP_HELP=0
    SETUP_SKIP=()
    SETUP_NAMED=()

    while [ $# -gt 0 ]; do
        case "$1" in
        --yes | -y) SETUP_YES=1 ;;
        --dry-run) SETUP_DRY_RUN=1 ;;
        --list) SETUP_LIST=1 ;;
        --help | -h) SETUP_HELP=1 ;;
        --skip | --skip=*)
            if [ "$1" = "--skip" ]; then
                if [ $# -lt 2 ]; then
                    echo "Error: --skip needs a comma-separated list of step names" >&2
                    return 1
                fi
                value=$2
                shift
            else
                value=${1#--skip=}
            fi
            IFS=, read -ra names <<<"$value"
            for name in ${names[@]+"${names[@]}"}; do
                [ -z "$name" ] && continue
                if ! step-index "$name" >/dev/null; then
                    echo "Error: --skip: unknown step '$name' (see --list)" >&2
                    return 1
                fi
                SETUP_SKIP+=("$name")
            done
            ;;
        -*)
            echo "Error: unknown option '$1' (see --help)" >&2
            return 1
            ;;
        *)
            SETUP_NAMED=("$@")
            return 0
            ;;
        esac
        shift
    done
}

# Evaluate every done-check once, then derive the default selection: done
# steps unticked, everything else ticked, --skip entries unticked.
function compute-step-state() {
    local i check
    STEP_DONE=()
    STEP_DEFAULTS=()
    for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
        check=${STEP_CHECKS[$i]}
        if [ -n "$check" ] && "$check" >/dev/null 2>&1; then
            STEP_DONE[i]=1
        else
            STEP_DONE[i]=0
        fi
        if [ "${STEP_DONE[$i]}" = 1 ] || step-skipped "${STEP_FUNCS[$i]}"; then
            STEP_DEFAULTS[i]=0
        else
            STEP_DEFAULTS[i]=1
        fi
    done
}

# Fill STEP_SELECTED (0/1 per step): select-steps <platform label>. Returns 1
# when the user quits the menu.
function select-steps() {
    local i
    compute-step-state
    STEP_SELECTED=()
    if [ "$SETUP_YES" = 1 ]; then
        for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
            if step-skipped "${STEP_FUNCS[$i]}"; then
                STEP_SELECTED[i]=0
            else
                STEP_SELECTED[i]=1
            fi
        done
        return 0
    fi
    STEP_SELECTED=(${STEP_DEFAULTS[@]+"${STEP_DEFAULTS[@]}"})
    step-menu "$1"
}

# Legend lines shown under the checklist in the full-screen menu.
function step-menu-legend() {
    echo "Up/Down or j/k move   Space, x or click toggle   Home/End g/G jump"
    echo "a=all  n=none  d=defaults   Enter=run  q=quit"
}

# Widest line the full-screen menu draws, in columns.
function step-menu-width() {
    local i max=0 name=0 desc=0 line
    for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
        [ ${#STEP_FUNCS[$i]} -gt "$name" ] && name=${#STEP_FUNCS[$i]}
        [ ${#STEP_DESCS[$i]} -gt "$desc" ] && desc=${#STEP_DESCS[$i]}
    done
    # "> [x] " + name + 3 spaces + description + "   (done)"
    max=$((6 + name + 3 + desc + 9))
    while IFS= read -r line; do
        [ ${#line} -gt "$max" ] && max=${#line}
    done < <(step-menu-legend)
    printf '%s' "$max"
}

STEP_MENU_STTY=""
STEP_MENU_ACTIVE=0

# Undo everything step-menu-tui set up. Safe to call more than once.
function step-menu-restore() {
    [ "$STEP_MENU_ACTIVE" = 1 ] || return 0
    STEP_MENU_ACTIVE=0
    printf '\033[?1006l\033[?1000l\033[?25h\033[?1049l'
    [ -n "$STEP_MENU_STTY" ] && stty "$STEP_MENU_STTY" 2>/dev/null
    return 0
}

# Full-screen checklist on the alternate screen, driven by arrow keys, space
# and the mouse. Same contract as step-menu-lines: 0 runs the ticked steps, 1
# quits (q, Ctrl-D, or end of input).
function step-menu-tui() {
    local label=$1 count=${#STEP_FUNCS[@]}
    local first=3 cur=0 result="" key c b p f ord i n mark note frame
    local width=0 dwidth=0 mx my mb
    local -a legend

    for ((i = 0; i < count; i++)); do
        [ ${#STEP_FUNCS[$i]} -gt "$width" ] && width=${#STEP_FUNCS[$i]}
        [ ${#STEP_DESCS[$i]} -gt "$dwidth" ] && dwidth=${#STEP_DESCS[$i]}
    done
    while IFS= read -r key; do legend+=("$key"); done < <(step-menu-legend)

    STEP_MENU_STTY=$(stty -g 2>/dev/null) || return 1
    STEP_MENU_ACTIVE=1
    trap 'step-menu-restore; exit 130' INT
    trap 'step-menu-restore; exit 143' TERM
    trap 'step-menu-restore; exit 129' HUP
    trap 'step-menu-restore' EXIT
    stty -echo -icanon min 1 time 0
    printf '\033[?1049h\033[?25l\033[?1000h\033[?1006h'

    while true; do
        frame=$'\033[H'"Select steps to run ($label):"$'\033[K\n\033[K\n'
        for ((i = 0; i < count; i++)); do
            mark=" "
            [ "${STEP_SELECTED[$i]}" = 1 ] && mark=x
            note=""
            [ "${STEP_DONE[$i]}" = 1 ] && note="   (done)"
            if [ "$i" = "$cur" ]; then
                frame+=$(printf '\033[7m> [%s] %-*s   %-*s%s\033[0m' "$mark" \
                    "$width" "${STEP_FUNCS[$i]}" "$dwidth" "${STEP_DESCS[$i]}" "$note")
            else
                frame+=$(printf '  [%s] %-*s   %-*s%s' "$mark" \
                    "$width" "${STEP_FUNCS[$i]}" "$dwidth" "${STEP_DESCS[$i]}" "$note")
            fi
            frame+=$'\033[K\n'
        done
        frame+=$'\033[K\n'
        for c in "${legend[@]}"; do frame+="$c"$'\033[K\n'; done
        frame+=$'\033[J'
        printf '%s' "$frame"

        if ! IFS= read -rsn1 key; then result=1; break; fi
        case "$key" in
        "") result=0; break ;;
        q | Q | $'\004') result=1; break ;;
        k) [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;;
        j) [ "$cur" -lt $((count - 1)) ] && cur=$((cur + 1)) ;;
        g) cur=0 ;;
        G) cur=$((count - 1)) ;;
        " " | x) STEP_SELECTED[cur]=$((1 - STEP_SELECTED[cur])) ;;
        a) for ((i = 0; i < count; i++)); do STEP_SELECTED[i]=1; done ;;
        n) for ((i = 0; i < count; i++)); do STEP_SELECTED[i]=0; done ;;
        d) STEP_SELECTED=(${STEP_DEFAULTS[@]+"${STEP_DEFAULTS[@]}"}) ;;
        $'\033')
            if ! IFS= read -rsn1 c; then result=1; break; fi
            case "$c" in
            O)
                if ! IFS= read -rsn1 f; then result=1; break; fi
                case "$f" in
                A) [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;;
                B) [ "$cur" -lt $((count - 1)) ] && cur=$((cur + 1)) ;;
                H) cur=0 ;;
                F) cur=$((count - 1)) ;;
                esac
                ;;
            "[")
                # Parameter and intermediate bytes, then a final byte 0x40-0x7E.
                p=""
                while true; do
                    if ! IFS= read -rsn1 b; then result=1; break 2; fi
                    [ -z "$b" ] && break
                    printf -v ord '%d' "'$b"
                    if [ "$ord" -ge 64 ] && [ "$ord" -le 126 ]; then
                        f=$b
                        break
                    fi
                    [ ${#p} -lt 32 ] && p+=$b
                done
                [ -z "$b" ] && continue
                case "$f" in
                A) [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;;
                B) [ "$cur" -lt $((count - 1)) ] && cur=$((cur + 1)) ;;
                H) cur=0 ;;
                F) cur=$((count - 1)) ;;
                "~")
                    case "$p" in
                    1 | 7) cur=0 ;;
                    4 | 8) cur=$((count - 1)) ;;
                    esac
                    ;;
                M)
                    case "$p" in
                    "<"*)
                        IFS=';' read -r mb mx my <<<"${p#<}"
                        case "$mb$mx$my" in
                        '' | *[!0-9]*) ;;
                        *)
                            if [ -n "$mb" ] && [ -n "$mx" ] && [ -n "$my" ] &&
                                [ ${#mb} -le 5 ] && [ ${#mx} -le 5 ] && [ ${#my} -le 5 ]; then
                                mb=$((10#$mb)) my=$((10#$my))
                                n=$((my - first))
                                if [ "$mb" -eq 0 ]; then
                                    if [ "$n" -ge 0 ] && [ "$n" -lt "$count" ]; then
                                        cur=$n
                                        STEP_SELECTED[cur]=$((1 - STEP_SELECTED[cur]))
                                    fi
                                elif [ "$mb" -eq 64 ]; then
                                    [ "$cur" -gt 0 ] && cur=$((cur - 1))
                                elif [ "$mb" -eq 65 ]; then
                                    [ "$cur" -lt $((count - 1)) ] && cur=$((cur + 1))
                                fi
                            fi
                            ;;
                        esac
                        ;;
                    esac
                    ;;
                esac
                ;;
            esac
            ;;
        esac
    done

    step-menu-restore
    trap - INT TERM HUP EXIT
    return "$result"
}

# Pick the menu: the full-screen checklist on a capable terminal that is big
# enough, else the line menu. SETUP_MENU=lines forces the line menu.
function step-menu() {
    local size rows cols
    if [ "${SETUP_MENU:-}" != lines ] && [ -n "${TERM:-}" ] && [ "$TERM" != dumb ] &&
        size=$(stty size 2>/dev/null) && [ -n "$size" ]; then
        rows=${size% *} cols=${size#* }
        case "$rows$cols" in
        '' | *[!0-9]*) ;;
        *)
            if [ "$((10#$rows))" -ge $((${#STEP_FUNCS[@]} + 6)) ] &&
                [ "$((10#$cols))" -ge "$(step-menu-width)" ]; then
                step-menu-tui "$1"
                return $?
            fi
            ;;
        esac
    fi
    step-menu-lines "$1"
}

# Print the checklist, read one line of input, apply it, repeat. Returns 0 to
# run the ticked steps and 1 to quit (q, or end of input). A line with an
# invalid entry changes nothing.
function step-menu-lines() {
    local label=$1 count=${#STEP_FUNCS[@]}
    local error="" line tok lo hi i mark note width=0 dwidth=0
    local -a next toks

    for ((i = 0; i < count; i++)); do
        [ ${#STEP_FUNCS[$i]} -gt "$width" ] && width=${#STEP_FUNCS[$i]}
        [ ${#STEP_DESCS[$i]} -gt "$dwidth" ] && dwidth=${#STEP_DESCS[$i]}
    done

    while true; do
        echo
        echo "Select steps to run ($label):"
        echo
        for ((i = 0; i < count; i++)); do
            mark=" "
            [ "${STEP_SELECTED[$i]}" = 1 ] && mark=x
            note=""
            [ "${STEP_DONE[$i]}" = 1 ] && note="  (done)"
            printf '  %2d) [%s] %-*s  %-*s%s\n' "$((i + 1))" "$mark" \
                "$width" "${STEP_FUNCS[$i]}" "$dwidth" "${STEP_DESCS[$i]}" "$note"
        done
        echo
        echo "Toggle: numbers or ranges (4 7 9-11)   a=all  n=none  d=defaults"
        echo "Enter=run  q=quit"
        [ -n "$error" ] && echo "$error"
        error=""
        printf '> '
        if ! IFS= read -r line; then
            echo
            return 1
        fi

        [ -z "${line//[[:space:]]/}" ] && return 0

        next=(${STEP_SELECTED[@]+"${STEP_SELECTED[@]}"})
        # read -a splits on whitespace without expanding globs such as "*"
        read -ra toks <<<"$line"
        for tok in ${toks[@]+"${toks[@]}"}; do
            case "$tok" in
            [aA]) for ((i = 0; i < count; i++)); do next[i]=1; done ;;
            [nN]) for ((i = 0; i < count; i++)); do next[i]=0; done ;;
            [dD]) next=(${STEP_DEFAULTS[@]+"${STEP_DEFAULTS[@]}"}) ;;
            [qQ]) return 1 ;;
            *)
                case "$tok" in
                *-*) lo=${tok%%-*} hi=${tok#*-} ;;
                *) lo=$tok hi=$tok ;;
                esac
                case "$lo$hi" in
                '' | *[!0-9]*) error="Not a valid choice: '$tok'"; break ;;
                esac
                if [ -z "$lo" ] || [ -z "$hi" ] || [ ${#lo} -gt 4 ] || [ ${#hi} -gt 4 ]; then
                    error="Not a valid choice: '$tok'"
                    break
                fi
                lo=$((10#$lo)) hi=$((10#$hi))
                if [ "$lo" -lt 1 ] || [ "$hi" -gt "$count" ] || [ "$lo" -gt "$hi" ]; then
                    error="Out of range (1-$count): '$tok'"
                    break
                fi
                for ((i = lo; i <= hi; i++)); do
                    next[i - 1]=$((1 - next[i - 1]))
                done
                ;;
            esac
        done
        [ -z "$error" ] && STEP_SELECTED=(${next[@]+"${next[@]}"})
    done
}

function print-setup-help() {
    cat <<HELP_TEXT
Usage: $0 [options]
       $0 <name> [args...]

With no options, shows a checklist of steps to tick or untick, then runs the
ticked steps. Steps already done start unticked.
The checklist takes arrow keys, space and the mouse; SETUP_MENU=lines selects
the type-a-number menu.

Options:
  --yes, -y        run every step with no menu
  --skip a,b       leave these steps out (unticked in the menu)
  --list           print the steps and whether each is done, then exit
  --dry-run        go through selection, print the steps that would run, exit
  --help, -h       print this help

<name> runs one step or helper function by name; the "Retry:" hints use it.
A step that needs sudo can still stop for a password with --yes.
HELP_TEXT
}

function print-step-list() {
    local i width=0 status
    for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
        [ ${#STEP_FUNCS[$i]} -gt "$width" ] && width=${#STEP_FUNCS[$i]}
    done
    compute-step-state
    for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
        status=pending
        [ "${STEP_DONE[$i]}" = 1 ] && status="done"
        printf '%-*s  %-7s  %s\n' "$width" "${STEP_FUNCS[$i]}" "$status" "${STEP_DESCS[$i]}"
    done
}

# Entry point for the platform scripts, called after their steps are
# registered: run-setup <platform label> "$@". The return value is the exit
# status: 0 on success or quit, 1 for a failed step or a bad command line, 2
# when there is no terminal to prompt on.
function run-setup() {
    local label=$1 i name
    shift

    parse-setup-args "$@" || return 1

    if [ "$SETUP_HELP" = 1 ]; then
        print-setup-help
        return 0
    fi
    if [ "$SETUP_LIST" = 1 ]; then
        print-step-list
        return 0
    fi

    if [ ${#SETUP_NAMED[@]} -gt 0 ]; then
        name=${SETUP_NAMED[0]}
        if [ "$(type -t "$name")" != "function" ]; then
            echo "Error: '$name' is not a step or function in this script (see --list)" >&2
            return 1
        fi
        if [ "$SETUP_DRY_RUN" = 1 ]; then
            echo "${SETUP_NAMED[*]}"
            return 0
        fi
        run-step "${SETUP_NAMED[@]}"
        report-problems
        return $?
    fi

    if [ "$SETUP_YES" != 1 ] && { [ ! -t 0 ] || [ ! -t 1 ]; }; then
        echo "No terminal to prompt on. Pass --yes to run every step, or name a step (see --list)." >&2
        return 2
    fi

    select-steps "$label" || return 0

    if [ "$SETUP_DRY_RUN" = 1 ]; then
        for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
            [ "${STEP_SELECTED[$i]}" = 1 ] && echo "${STEP_FUNCS[$i]}"
        done
        return 0
    fi

    for ((i = 0; i < ${#STEP_FUNCS[@]}; i++)); do
        [ "${STEP_SELECTED[$i]}" = 1 ] && run-step "${STEP_FUNCS[$i]}"
    done
    report-problems
}
