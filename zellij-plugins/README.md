# zellij-plugins

`zellij-tab-title.wasm` is a background zellij plugin that keeps each tab's
name in sync with the title of that tab's focused pane. It has no UI of its
own; it just watches tab and pane updates and renames tabs to match.

Zellij itself shows a pane's title as the tab name only while the tab has a
single tiled pane and still has its default name, and `zellij action
list-tabs` reports the stored default name in that state. The plugin extends
this to tabs with several panes and to floating panes.

## Loading

The plugin is loaded from the `load_plugins` block in `../zellij.kdl` by its
bare filename (`file:zellij-tab-title.wasm`), which zellij resolves against
its plugin directory:

- macOS: `~/Library/Application Support/org.Zellij-Contributors.Zellij/plugins`
- Linux: `${XDG_DATA_HOME:-~/.local/share}/zellij/plugins`

`apply-dotfiles` symlinks the committed wasm into that directory, so the
`load_plugins` line works unmodified on every machine.

## Permissions

The plugin needs the `ReadApplicationState` and `ChangeApplicationState`
permissions. Zellij renders a grant prompt inside the requesting plugin's
pane, and a background plugin loaded from `load_plugins` has no pane, so the
request is cached against a pane that never exists and the user is never
asked; the plugin waits for the grant forever. Granting by loading the plugin
in a foreground pane (`zellij plugin -- file:...`) does not help either: the
CLI resolves the `file:` path against its own working directory, so the grant
is cached under a different key than the background instance checks.

`apply-dotfiles` therefore seeds the grant directly into zellij's permission
cache (`seed-zellij-plugin-permissions` in `../setup-common.sh`):

- macOS: `~/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl`
- Linux: `${XDG_CACHE_HOME:-~/.cache}/zellij/permissions.kdl`

The cache key is the `load_plugins` path verbatim (`zellij-tab-title.wasm`),
which zellij stores unresolved, so the seeded entry is identical on every
machine. Zellij reads the cache when a session starts; after seeding, kill
the session and open a new terminal.

## Why the artifact is committed

The compiled `.wasm` is committed to the repo rather than built on each
machine, so a machine with no Rust toolchain still gets working tab names.

## Building

Once per machine:

```sh
rustup target add wasm32-wasip1
```

Then, from this directory:

```sh
./tab-title/build.sh
```

`build.sh` runs the crate's tests first and then refreshes the committed
`zellij-tab-title.wasm`. Rebuild and commit the wasm together with any change
to the source in `tab-title/`.

## Configuration

`max_length` (default `24`) caps the tab name in characters, not bytes, so
multi-byte titles such as the `✳` Claude Code prefix aren't cut mid-character.
A truncated name ends in an ellipsis.

`poll_interval_ms` (default `250`) sets how often the plugin re-reads the
naming pane's title, in milliseconds; see the next section. `0` turns the
poll off.

## Polling for title changes

Zellij 0.45.1 sends plugins a pane update only on structural changes such as
a focus change or a new pane. A title a pane sets for itself through an OSC
escape (the shell's cwd at each prompt, the running command, a program's own
status line) is stored but never pushed, so a tab named from its pane's first
update would keep reading `Pane #1` until the next focus change. This is
zellij-org/zellij#5482; a fix is pending in PR #5399.

To cover the gap the plugin polls: on a timer it re-reads, for every tab, the
title of the pane that names the tab and renames the tab when the title has
changed. Each tick costs one synchronous pane query per tab. Once zellij
pushes title changes itself, set `poll_interval_ms` to `0` or drop the poll.

## Development

A rebuilt wasm is picked up when a session starts, so after `build.sh` kill
the session and open a new terminal; the shell's auto-attach discards the
exited session and creates a fresh one. `zellij action start-or-reload-plugin`
cannot reload the instance from `load_plugins`: the CLI resolves a `file:`
path against its own working directory, so the paths never match and it
starts a second copy in a pane instead.

The plugin owns tab names: a manual tab rename triggers a tab update, which
renames the tab straight back to the focused pane's title.
