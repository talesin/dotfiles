#!/usr/bin/env bash
# Checks that Claude Desktop's integrated terminal would NOT auto-attach to zellij.
# Read-only. Run after a Claude Desktop update; exits non-zero if the gate fails.
#
# Desktop spawns `$SHELL -l` through node-pty with the Electron GUI env plus
# TERM, COLORTERM and TERM_PROGRAM=claude-desktop. This script reproduces that
# spawn on a pty and asks the dotfiles predicates what they would do.
set -u

app=/Applications/Claude.app
asar=$app/Contents/Resources/app.asar
fail=0

if [ -f "$app/Contents/Info.plist" ]; then
  echo "Claude Desktop: $(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist" 2>/dev/null)"
else
  echo "Claude Desktop not found at $app"
fi

if [ -f "$asar" ]; then
  # Two pty spawns share this shape: the Bash-tool pty (TERM + COLORTERM only)
  # and the integrated terminal, which adds TERM_PROGRAM. Only the latter matters.
  echo "Integrated-terminal spawn env (from app.asar):"
  spawn=$(strings -a "$asar" | grep -oE 'TERM:.xterm-256color.,COLORTERM:[^}]*' | grep TERM_PROGRAM | sort -u)
  if [ -n "$spawn" ]; then
    printf '  %s\n' "$spawn"
    printf '%s\n' "$spawn" | grep -q "TERM_PROGRAM:.claude-desktop" \
      || echo "  WARNING: TERM_PROGRAM=claude-desktop no longer set - Desktop changed its spawn env"
  else
    echo "  WARNING: spawn env not found in app.asar - bundle layout changed, inspect manually"
  fi
fi

# Run a command on a real pty, the way node-pty does, and print its output.
run_pty() {
  python3 - "$@" <<'PY'
import os, pty, sys, select, time
pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[1], sys.argv[1:])
out, deadline = [], time.time() + 20
while time.time() < deadline:
    r, _, _ = select.select([fd], [], [], 0.5)
    if r:
        try:
            d = os.read(fd, 4096)
        except OSError:
            break
        if not d:
            break
        out.append(d)
_, status = os.waitpid(pid, 0)
sys.stdout.write(b"".join(out).decode(errors="replace"))
PY
}

probe='for f in is-installed is-agent-shell zellij-autostart-wanted; do eval "function $f { source \$HOME/.functions/$f; }"; done; is-agent-shell; a=$?; zellij-autostart-wanted; w=$?; echo "RESULT agent=$a wanted=$w"'

for sh in zsh bash; do
  command -v "$sh" >/dev/null || continue
  # -f/--norc: only the predicates are under test, not the full rc files, which
  # would exec zellij on failure and hijack the live session.
  case $sh in zsh) args=(-fic) ;; bash) args=(--norc --noprofile -ic) ;; esac
  out=$(run_pty env -i HOME="$HOME" PATH="$PATH" SHELL="$(command -v "$sh")" USER="${USER:-$(id -un)}" \
        TERM=xterm-256color COLORTERM=truecolor TERM_PROGRAM=claude-desktop \
        "$sh" "${args[@]}" "$probe" | tr -d '\r' | grep RESULT)
  case $out in
    *"agent=0 wanted=1"*) echo "$sh: OK   ($out)" ;;
    *) echo "$sh: FAIL ($out) - Desktop's terminal would attach to zellij"; fail=1 ;;
  esac
done

if command -v zellij >/dev/null; then
  echo "zellij sessions:"
  zellij ls 2>/dev/null | sed -e 's/\x1B\[[0-9;]*[mG]//g' | sed 's/^/  /'
fi

exit $fail
