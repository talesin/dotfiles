//! Zellij background plugin: keeps each tab's name equal to the title of the
//! focused pane in that tab. Loaded from the `load_plugins` block in
//! zellij.kdl, so it has no pane and never renders.
//!
//! Titles arrive with `PaneUpdate`, which zellij 0.45.1 sends only on
//! structural changes such as a focus change or a new pane, never when a pane
//! sets its own title through an OSC escape (zellij-org/zellij#5482, fix
//! pending in PR #5399). A timer therefore re-reads the naming pane's title
//! for every tab and renames the tab when it moved.

use std::collections::BTreeMap;

use zellij_tab_title::{rename_for, PaneView};
use zellij_tile::prelude::*;

/// Tab names longer than this are cut short. Override per session with the
/// `max_length` key in the `load_plugins` config block.
const DEFAULT_MAX_LENGTH: usize = 24;

/// How often the naming pane's title is re-read, in milliseconds. Override
/// with the `poll_interval_ms` key; `0` turns polling off.
const DEFAULT_POLL_INTERVAL_MS: u64 = 250;

struct State {
    max_length: usize,
    /// Milliseconds between title polls; `0` disables the poll.
    poll_interval_ms: u64,
    /// Rename commands are rejected until the user grants
    /// ChangeApplicationState, so they are held back until then.
    permission_granted: bool,
    /// Whether a timer is outstanding. `set_timeout` fires once per call, so
    /// the chain is armed after the permission grant and re-armed on each
    /// tick; this guard keeps a repeated grant from starting a second chain.
    polling: bool,
    /// Latest snapshot of each kind. Tabs and panes arrive as separate events,
    /// so both must have landed before a tab can be named.
    tabs: Option<Vec<TabInfo>>,
    panes: Option<PaneManifest>,
}

impl Default for State {
    fn default() -> Self {
        Self {
            max_length: DEFAULT_MAX_LENGTH,
            poll_interval_ms: DEFAULT_POLL_INTERVAL_MS,
            permission_granted: false,
            polling: false,
            tabs: None,
            panes: None,
        }
    }
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.max_length = configuration
            .get("max_length")
            .and_then(|value| value.parse().ok())
            .unwrap_or(DEFAULT_MAX_LENGTH);
        self.poll_interval_ms = configuration
            .get("poll_interval_ms")
            .and_then(|value| value.parse().ok())
            .unwrap_or(DEFAULT_POLL_INTERVAL_MS);

        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        // Subscribe up front: zellij queues events for a plugin whose
        // permission request is pending and replays them once granted, so the
        // initial tab and pane snapshots arrive without waiting for the next
        // focus change.
        subscribe(&[
            EventType::PermissionRequestResult,
            EventType::TabUpdate,
            EventType::PaneUpdate,
            EventType::Timer,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                self.permission_granted = true;
                self.sync_tab_names();
                self.arm_poll();
            }
            Event::PermissionRequestResult(PermissionStatus::Denied) => {
                eprintln!("zellij-tab-title: permission denied, tab names will not be updated");
            }
            Event::TabUpdate(tabs) => {
                self.tabs = Some(tabs);
                self.sync_tab_names();
            }
            Event::PaneUpdate(panes) => {
                self.panes = Some(panes);
                self.sync_tab_names();
            }
            Event::Timer(_) => {
                self.polling = false;
                if self.refresh_titles() {
                    self.sync_tab_names();
                }
                self.arm_poll();
            }
            _ => {}
        }
        // No UI: never ask zellij to render.
        false
    }
}

impl State {
    /// Rename every tab whose name no longer matches its focused pane.
    fn sync_tab_names(&self) {
        if !self.permission_granted {
            return;
        }
        let (Some(tabs), Some(panes)) = (&self.tabs, &self.panes) else {
            return;
        };

        for tab in tabs {
            // Both snapshots key panes by tab position. A manifest that
            // predates a tab being closed can pair a tab with the previous
            // occupant's panes; that costs one wrong rename, which the next
            // event corrects. A tab with no entry yet gets no panes and so is
            // left alone.
            let panes_in_tab = panes
                .panes
                .get(&tab.position)
                .map(|panes| panes.as_slice())
                .unwrap_or_default();

            let Some(name) = rename_for(
                &tab.name,
                tab.are_floating_panes_visible,
                panes_in_tab.iter().map(pane_view),
                self.max_length,
            ) else {
                continue;
            };

            // tab_id is a usize; the rename command takes a u64. try_from keeps
            // that assumption checked rather than implied.
            match u64::try_from(tab.tab_id) {
                Ok(tab_id) => rename_tab_with_id(tab_id, &name),
                Err(_) => eprintln!("zellij-tab-title: tab id {} exceeds u64", tab.tab_id),
            }
        }
    }

    /// Schedule the next title poll unless polling is off or a timer is
    /// already outstanding.
    fn arm_poll(&mut self) {
        if self.poll_interval_ms == 0 || self.polling {
            return;
        }
        self.polling = true;
        set_timeout(self.poll_interval_ms as f64 / 1000.0);
    }

    /// Re-read the live title of the pane that names each tab and patch it
    /// into the cached manifest. Returns whether any title changed. Tabs with
    /// no manifest entry or no eligible pane are skipped, and a pane that has
    /// gone away since the last manifest counts as unchanged.
    fn refresh_titles(&mut self) -> bool {
        let (Some(tabs), Some(panes)) = (&self.tabs, &mut self.panes) else {
            return false;
        };

        let mut changed = false;
        for tab in tabs {
            let Some(panes_in_tab) = panes.panes.get_mut(&tab.position) else {
                continue;
            };
            let Some(pane) = panes_in_tab
                .iter_mut()
                .find(|pane| pane_view(pane).names_the_tab(tab.are_floating_panes_visible))
            else {
                continue;
            };
            let Some(live) = get_pane_info(pane_id(pane)) else {
                continue;
            };
            if live.title != pane.title {
                pane.title = live.title;
                changed = true;
            }
        }
        changed
    }
}

/// Adapts zellij's pane type to the borrowed view the naming rules work on.
fn pane_view(pane: &PaneInfo) -> PaneView<'_> {
    PaneView {
        title: &pane.title,
        is_plugin: pane.is_plugin,
        is_focused: pane.is_focused,
        is_floating: pane.is_floating,
        is_suppressed: pane.is_suppressed,
    }
}

/// The id `get_pane_info` expects: plugin and terminal panes share a numeric
/// id space only within their own kind.
fn pane_id(pane: &PaneInfo) -> PaneId {
    if pane.is_plugin {
        PaneId::Plugin(pane.id)
    } else {
        PaneId::Terminal(pane.id)
    }
}
