//! Tab-naming rules for the zellij-tab-title plugin.
//!
//! This layer holds no zellij types so it compiles and links for the host
//! target under `cargo test --lib`. `main.rs` adapts zellij's `PaneInfo` into
//! [`PaneView`] at the boundary.

use std::iter;

/// Replaces the last kept character when a title is cut short.
const ELLIPSIS: char = '…';

/// The part of a pane's state that decides whether it names its tab.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PaneView<'a> {
    pub title: &'a str,
    pub is_plugin: bool,
    pub is_focused: bool,
    pub is_floating: bool,
    pub is_suppressed: bool,
}

impl PaneView<'_> {
    /// A pane names its tab when it is the focused pane of the layer the user
    /// is looking at. Zellij focuses one pane per layer, so the floating layer
    /// and the tiled layer both report a focused pane; only the visible one
    /// counts. Plugin panes (tab-bar, status-bar, session-manager) and
    /// suppressed panes never qualify.
    pub fn names_the_tab(&self, floating_layer_visible: bool) -> bool {
        !self.is_plugin
            && !self.is_suppressed
            && self.is_focused
            && self.is_floating == floating_layer_visible
    }
}

/// Trimmed title of the focused pane in the visible layer. `None` when no
/// eligible pane offers a non-blank title, which leaves the tab name alone.
pub fn pick_focused_title<'a, I>(floating_layer_visible: bool, panes: I) -> Option<&'a str>
where
    I: IntoIterator<Item = PaneView<'a>>,
{
    panes
        .into_iter()
        .filter(|pane| pane.names_the_tab(floating_layer_visible))
        .map(|pane| pane.title.trim())
        .find(|title| !title.is_empty())
}

/// `title` cut to `max_length` characters (not bytes: titles carry emoji such
/// as the `✳` Claude Code prefix), ending in an ellipsis when anything was
/// dropped.
pub fn truncate_title(title: &str, max_length: usize) -> String {
    let max_length = max_length.max(1);
    if title.chars().count() <= max_length {
        return title.to_string();
    }
    title
        .chars()
        .take(max_length - 1)
        .chain(iter::once(ELLIPSIS))
        .collect()
}

/// The name a tab should be renamed to, or `None` to leave it alone. Returning
/// `None` for an already-correct name is what stops the
/// rename -> `TabUpdate` -> rename cycle from running forever.
pub fn rename_for<'a, I>(
    current_name: &str,
    floating_layer_visible: bool,
    panes: I,
    max_length: usize,
) -> Option<String>
where
    I: IntoIterator<Item = PaneView<'a>>,
{
    let title = pick_focused_title(floating_layer_visible, panes)?;
    let desired = truncate_title(title, max_length);
    (desired != current_name).then_some(desired)
}

#[cfg(test)]
mod tests {
    use super::*;

    const TILED: bool = false;
    const FLOATING: bool = true;

    fn pane(title: &str) -> PaneView<'_> {
        PaneView {
            title,
            is_plugin: false,
            is_focused: false,
            is_floating: false,
            is_suppressed: false,
        }
    }

    fn focused(title: &str) -> PaneView<'_> {
        PaneView {
            is_focused: true,
            ..pane(title)
        }
    }

    #[test]
    fn picks_the_focused_tiled_pane() {
        let panes = [pane("other"), focused("dotfiles"), pane("third")];
        assert_eq!(pick_focused_title(TILED, panes), Some("dotfiles"));
    }

    #[test]
    fn ignores_plugin_panes() {
        let panes = [
            PaneView {
                is_plugin: true,
                ..focused("tab-bar")
            },
            focused("dotfiles"),
        ];
        assert_eq!(pick_focused_title(TILED, panes), Some("dotfiles"));
    }

    #[test]
    fn ignores_suppressed_panes() {
        let panes = [
            PaneView {
                is_suppressed: true,
                ..focused("hidden")
            },
            focused("dotfiles"),
        ];
        assert_eq!(pick_focused_title(TILED, panes), Some("dotfiles"));
    }

    #[test]
    fn prefers_the_floating_pane_when_the_floating_layer_is_visible() {
        let panes = [
            focused("tiled"),
            PaneView {
                is_floating: true,
                ..focused("floating")
            },
        ];
        assert_eq!(pick_focused_title(FLOATING, panes), Some("floating"));
        assert_eq!(pick_focused_title(TILED, panes), Some("tiled"));
    }

    #[test]
    fn skips_blank_titles() {
        assert_eq!(pick_focused_title(TILED, [focused("   ")]), None);
    }

    #[test]
    fn trims_surrounding_whitespace() {
        assert_eq!(
            pick_focused_title(TILED, [focused("  dotfiles  ")]),
            Some("dotfiles")
        );
    }

    #[test]
    fn returns_none_without_an_eligible_pane() {
        assert_eq!(pick_focused_title(TILED, [pane("unfocused")]), None);
    }

    #[test]
    fn leaves_short_titles_alone() {
        assert_eq!(truncate_title("dotfiles", 24), "dotfiles");
    }

    #[test]
    fn leaves_titles_of_exactly_max_length_alone() {
        assert_eq!(truncate_title("abcde", 5), "abcde");
    }

    #[test]
    fn truncates_with_an_ellipsis() {
        assert_eq!(truncate_title("abcdef", 5), "abcd…");
    }

    #[test]
    fn counts_characters_rather_than_bytes() {
        // Each ✳ is three bytes; byte-based truncation would cut mid-character.
        assert_eq!(truncate_title("✳✳✳✳✳", 3), "✳✳…");
        assert_eq!(truncate_title("✳ Claude Code", 24), "✳ Claude Code");
    }

    #[test]
    fn clamps_a_zero_max_length() {
        assert_eq!(truncate_title("abc", 0), "…");
    }

    #[test]
    fn skips_the_rename_when_the_name_already_matches() {
        assert_eq!(
            rename_for("dotfiles", TILED, [focused("dotfiles")], 24),
            None
        );
    }

    #[test]
    fn renames_when_the_name_differs() {
        assert_eq!(
            rename_for("Tab #1", TILED, [focused("dotfiles")], 24),
            Some("dotfiles".to_string())
        );
    }

    #[test]
    fn compares_against_the_truncated_name() {
        let panes = [focused("a-very-long-directory-name")];
        assert_eq!(rename_for("a-very-long-directo…", TILED, panes, 20), None);
    }

    #[test]
    fn leaves_the_tab_alone_when_no_pane_offers_a_title() {
        assert_eq!(rename_for("Tab #1", TILED, [pane("unfocused")], 24), None);
    }

    #[test]
    fn names_the_tab_follows_the_visible_layer() {
        let tiled_pane = focused("tiled");
        let floating_pane = PaneView {
            is_floating: true,
            ..focused("floating")
        };
        assert!(tiled_pane.names_the_tab(TILED));
        assert!(!tiled_pane.names_the_tab(FLOATING));
        assert!(floating_pane.names_the_tab(FLOATING));
        assert!(!floating_pane.names_the_tab(TILED));

        let plugin_pane = PaneView {
            is_plugin: true,
            ..focused("tab-bar")
        };
        assert!(!plugin_pane.names_the_tab(TILED));
        assert!(!plugin_pane.names_the_tab(FLOATING));

        let suppressed_pane = PaneView {
            is_suppressed: true,
            ..focused("hidden")
        };
        assert!(!suppressed_pane.names_the_tab(TILED));
        assert!(!suppressed_pane.names_the_tab(FLOATING));
    }
}
