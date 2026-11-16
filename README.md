# dotfiles

Fork and clone repo then run `setup.sh`.

## Setup

`./setup.sh` picks the macOS or Linux script and shows a full-screen checklist of steps. Steps that are already done start unticked; move with the arrows or `j`/`k`, toggle with space or a click, `a` for all, `n` for none, `d` for the defaults, Enter to run, `q` to quit. On a small or dumb terminal, or with `SETUP_MENU=lines`, a line menu takes numbers or ranges (`4 7 9-11`) to toggle instead.

| Command | Effect |
|---|---|
| `./setup.sh` | Checklist menu, then run the ticked steps |
| `./setup.sh --yes` | Run every step with no prompts |
| `./setup.sh --skip a,b` | Untick these steps in the menu, or leave them out with `--yes` |
| `./setup.sh --list` | Print each step and whether it is done, then exit |
| `./setup.sh --dry-run` | Go through selection, print the steps that would run, then exit |
| `./setup.sh <name> [args...]` | Run one step or helper function by name |

Step names are function names (`install-brew`, `apply-dotfiles`), the same names the failure summary uses in its `Retry:` lines. With no terminal and no `--yes`, the script installs nothing and exits with status 2.

`--yes` does not suppress `sudo`: a step that needs it can still stop for a password. `seed-gitconfig` asks for a name and email on a terminal; under `--yes` it records the missing identity in the summary instead.
