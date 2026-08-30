#!/bin/bash
# Shared helpers for roam-notes hooks. Source this; do not execute.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/roam-notes"
markers_dir="$state_dir/markers"
outbox_dir="$state_dir/outbox"
ensure_state() { mkdir -p "$markers_dir" "$outbox_dir" 2>/dev/null; }
have_jq() { command -v jq >/dev/null 2>&1; }
NUDGE='Invoke the roam-notes skill now to capture learnings from this work, then continue.'
