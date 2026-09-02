//! Zellij background plugin: keeps each tab's name equal to the title of the
//! focused pane in that tab. Loaded from the `load_plugins` block in
//! zellij.kdl, so it has no pane and never renders.

use std::collections::BTreeMap;

use zellij_tab_title::{rename_for, PaneView};
use zellij_tile::prelude::*;

/// Tab names longer than this are cut short. Override per session with the
/// `max_length` key in the `load_plugins` config block.
const DEFAULT_MAX_LENGTH: usize = 24;

struct State {
    max_length: usize,
    /// Rename commands are rejected until the user grants
    /// ChangeApplicationState, so they are held back until then.
    permission_granted: bool,
    /// Latest snapshot of each kind. Tabs and panes arrive as separate events,
    /// so both must have landed before a tab can be named.
    tabs: Option<Vec<TabInfo>>,
    panes: Option<PaneManifest>,
}

impl Default for State {
    fn default() -> Self {
        Self {
            max_length: DEFAULT_MAX_LENGTH,
            permission_granted: false,
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
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                self.permission_granted = true;
                self.sync_tab_names();
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
