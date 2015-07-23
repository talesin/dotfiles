unbind-key -n C-a
set -g prefix ^A
set -g prefix2 ^A
bind a send-prefix

# new split on top (alt+up)
bind-key -n M-S-Up split-window -v \; swap-pane -s :. -t :.- \; select-pane -t :.-
# new split on left (alt+left)
bind-key -n M-S-Left split-window -h \; swap-pane -s :. -t :.- \;  select-pane -t :.-
# new split on right (alt+right)
bind-key -n M-S-Right split-window -h
# new split on bottom (alt+down)
bind-key -n M-S-Down split-window -v
