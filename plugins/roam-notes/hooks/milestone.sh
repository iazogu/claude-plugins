#!/bin/bash
# Stop hook: when the active plan under <cwd>/thoughts/shared/plans or
# <cwd>/docs/superpowers/plans has just become fully checked, block the stop once per
# (session, plan) and ask for roam-notes.
# Exits 0 silently on any doubt. Never loops: honours stop_hook_active + a marker file.
set -u
. "$(dirname "$0")/lib.sh"
have_jq || exit 0
input=$(cat)
[ -n "$input" ] || exit 0
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || exit 0
# Both plan conventions in use; either directory may be absent.
set --
for d in "$cwd/thoughts/shared/plans" "$cwd/docs/superpowers/plans"; do
  [ -d "$d" ] && set -- "$@" "$d"
done
[ "$#" -gt 0 ] || exit 0

# Most recently modified plan across those directories, touched within 48h — the one being
# worked on. -r keeps GNU xargs from running `ls` (and listing the cwd) on empty input.
plan=$(find "$@" -name '*.md' -mtime -2 -print0 2>/dev/null | xargs -0 -r ls -t 2>/dev/null | head -1)
[ -n "$plan" ] || exit 0
unchecked=$(grep -c '^[[:space:]]*- \[ \]' "$plan" 2>/dev/null); unchecked=${unchecked:-0}
[ "$unchecked" -eq 0 ] || exit 0
grep -q '^[[:space:]]*- \[x\]' "$plan" 2>/dev/null || exit 0   # a file with no tasks is not a finished plan

session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
ensure_state
marker="$markers_dir/$session.plan-$(printf '%s' "$plan" | tr '/' '_')"
[ -e "$marker" ] && exit 0
touch "$marker"

jq -n --arg plan "$plan" --arg nudge "$NUDGE" \
  '{decision: "block", reason: ("Milestone: the plan " + $plan + " is complete. " + $nudge)}'
