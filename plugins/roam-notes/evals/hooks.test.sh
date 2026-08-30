#!/bin/bash
# Both hooks, driven with synthetic hook JSON. State is isolated via XDG_STATE_HOME.
. "$(dirname "$0")/lib.sh"
hooks="$(cd "$(dirname "$0")/../hooks" && pwd)"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export XDG_STATE_HOME="$tmp/state"

# ---------- milestone.sh (Stop) ----------
proj="$tmp/proj"; plans="$proj/thoughts/shared/plans"; mkdir -p "$plans"
stop_json() { jq -n --arg cwd "$proj" --arg s "$1" --argjson active "${2:-false}" '{session_id:$s, cwd:$cwd, stop_hook_active:$active, transcript_path:"/dev/null"}'; }

out=$(printf '' | bash "$hooks/milestone.sh"); assert_empty "milestone: empty stdin → silent" "$out"
out=$(echo '{"cwd":"/nonexistent-dir-xyz","session_id":"s"}' | bash "$hooks/milestone.sh"); assert_empty "milestone: no plans dir → silent" "$out"

printf -- '- [x] a\n- [ ] b\n' > "$plans/p1.md"
out=$(stop_json s1 | bash "$hooks/milestone.sh"); assert_empty "milestone: unchecked remain → silent" "$out"

printf -- '# notes\nno tasks here\n' > "$plans/p1.md"
out=$(stop_json s1 | bash "$hooks/milestone.sh"); assert_empty "milestone: no checkboxes at all → silent" "$out"

printf -- '- [x] a\n- [x] b\n' > "$plans/p1.md"
out=$(stop_json s1 true | bash "$hooks/milestone.sh"); assert_empty "milestone: stop_hook_active → silent" "$out"

out=$(stop_json s1 | bash "$hooks/milestone.sh")
assert_eq "milestone: complete plan → block" "$(printf '%s' "$out" | jq -r .decision)" "block"
assert_contains "milestone: reason names plan" "$(printf '%s' "$out" | jq -r .reason)" "$plans/p1.md"
assert_contains "milestone: reason carries nudge" "$(printf '%s' "$out" | jq -r .reason)" "Invoke the roam-notes skill now"

out=$(stop_json s1 | bash "$hooks/milestone.sh"); assert_empty "milestone: second stop same session → silent (marker)" "$out"
out=$(stop_json s2 | bash "$hooks/milestone.sh"); assert_eq "milestone: different session fires again" "$(printf '%s' "$out" | jq -r .decision)" "block"

touch -t 202001010000 "$plans/p1.md"
out=$(stop_json s3 | bash "$hooks/milestone.sh"); assert_empty "milestone: stale plan (>48h) → silent" "$out"

report
