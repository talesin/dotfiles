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

## Development

A rebuilt wasm is picked up when a session starts, so after `build.sh` kill
the session and open a new terminal; the shell's auto-attach discards the
exited session and creates a fresh one. `zellij action start-or-reload-plugin`
cannot reload the instance from `load_plugins`: the CLI resolves a `file:`
path against its own working directory, so the paths never match and it
starts a second copy in a pane instead.

The plugin owns tab names: a manual tab rename triggers a tab update, which
renames the tab straight back to the focused pane's title.
