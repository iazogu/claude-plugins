#!/bin/bash
# PostToolUse(Bash) hook: after a successful `git commit`, add model-facing context asking
# for roam-notes. One nudge per 600 s per session. Exits 0 silently on any doubt.
set -u
. "$(dirname "$0")/lib.sh"
have_jq || exit 0
input=$(cat)
[ -n "$input" ] || exit 0
[ "$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" = "Bash" ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]|$)' || exit 0
printf '%s' "$cmd" | grep -Fq -- '--dry-run' && exit 0
[ "$(printf '%s' "$input" | jq -r '.tool_response.exit_code // 1' 2>/dev/null)" = "0" ] || exit 0

session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
ensure_state
marker="$markers_dir/$session.commit-last"
now=$(date +%s)
if [ -f "$marker" ]; then
  last=$(cat "$marker" 2>/dev/null)
  case "$last" in ''|*[!0-9]*) last=0;; esac   # corrupt marker: treat as never nudged, rewrite below
  last=$((10#$last))                          # a digits-only marker like 08 is decimal, not octal
  [ $((now - last)) -ge 600 ] || exit 0
fi
printf '%s' "$now" > "$marker"

line=$(printf '%s' "$input" | jq -r '.tool_response.stdout // empty' 2>/dev/null | grep -Eo '^\[[^]]+ [0-9a-f]{7,}\]' | head -1)
what="landed"; [ -n "$line" ] && what="$line landed"
jq -n --arg what "$what" --arg nudge "$NUDGE" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: ("Milestone: commit " + $what + ". " + $nudge)}}'
