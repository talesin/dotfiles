#!/usr/bin/env bash
# Status line for Claude Code, shared by the primary (~/.claude) and secondary
# (~/.claude-secondary) profiles set up by functions/claude. The profile
# label is passed as $1 rather than sniffed from the environment, since the
# primary profile deliberately leaves CLAUDE_CONFIG_DIR unset.
#
# Wired in via settings.json:
#   "statusLine": { "type": "command", "command": "~/.dotfiles/claude-statusline.sh primary" }
#   "statusLine": { "type": "command", "command": "~/.dotfiles/claude-statusline.sh secondary" }
#
# Must always exit 0: Claude Code discards the status line output on a
# non-zero exit and leaves the previous line on screen.

profile="${1:-primary}"
payload="$(cat)"

case "$profile" in
  secondary)
    label=" SECONDARY "
    # reverse video + magenta background, bold
    badge_style=$'\033[7;35;1m'
    ;;
  *)
    label=" PRIMARY "
    # reverse video + cyan background, bold
    badge_style=$'\033[7;36;1m'
    ;;
esac
reset=$'\033[0m'

dir=""
model=""
if command -v jq >/dev/null 2>&1; then
  dir="$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)"
  model="$(printf '%s' "$payload" | jq -r '.model.display_name // empty' 2>/dev/null)"
fi

# Collapse $HOME to ~ for display.
if [ -n "$dir" ]; then
  case "$dir" in
    "$HOME") dir="~" ;;
    "$HOME"/*) dir="~${dir#"$HOME"}" ;;
  esac
fi

branch=""
if [ -n "$dir" ] && command -v git >/dev/null 2>&1; then
  git_dir="${dir/#\~/$HOME}"
  branch="$(git -C "$git_dir" branch --show-current 2>/dev/null)"
fi

line="${badge_style}${label}${reset}"
[ -n "$dir" ] && line="${line}  ${dir}"
[ -n "$branch" ] && line="${line}  (${branch})"
[ -n "$model" ] && line="${line}  ${model}"

printf '%s\n' "$line"
exit 0
