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

# ---------- commit.sh (PostToolUse / Bash) ----------
post_json() { jq -n --arg s "$1" --arg cmd "$2" --arg so "${3:-}" --argjson ec "${4:-0}" --arg tn "${5:-Bash}" \
  '{session_id:$s, cwd:"/tmp", tool_name:$tn, tool_input:{command:$cmd}, tool_response:{stdout:$so, stderr:"", exit_code:$ec, interrupted:false}}'; }
ctx() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }

out=$(post_json c1 'ls -la' | bash "$hooks/commit.sh"); assert_empty "commit: non-git command → silent" "$out"
out=$(post_json c1 'git log --grep "commit" --oneline' | bash "$hooks/commit.sh"); assert_empty "commit: git log mentioning commit → silent" "$out"
out=$(post_json c1 'git commit --dry-run' | bash "$hooks/commit.sh"); assert_empty "commit: --dry-run → silent" "$out"
out=$(post_json c1 'git commit -m x' '' 1 | bash "$hooks/commit.sh"); assert_empty "commit: exit 1 → silent" "$out"
out=$(post_json c1 'git commit -m x' '[main abc1234] x' 0 Read | bash "$hooks/commit.sh"); assert_empty "commit: non-Bash tool → silent" "$out"

out=$(post_json c1 'git add -A && git commit -m "feat: x"' '[main 9f8e7d6] feat: x' | bash "$hooks/commit.sh")
assert_eq "commit: hookEventName" "$(printf '%s' "$out" | jq -r .hookSpecificOutput.hookEventName)" "PostToolUse"
assert_contains "commit: context names commit line" "$(ctx "$out")" "[main 9f8e7d6]"
assert_contains "commit: context carries nudge" "$(ctx "$out")" "Invoke the roam-notes skill now"

out=$(post_json c1 'git commit -m again' '[main 1111111] again' | bash "$hooks/commit.sh"); assert_empty "commit: within cool-down → silent" "$out"
printf '%s' "$(( $(date +%s) - 700 ))" > "$XDG_STATE_HOME/roam-notes/markers/c1.commit-last"
out=$(post_json c1 'git commit -m later' '[main 2222222] later' | bash "$hooks/commit.sh"); assert_contains "commit: after cool-down fires again" "$(ctx "$out")" "[main 2222222]"

printf '%s' 'garbage-not-a-number' > "$XDG_STATE_HOME/roam-notes/markers/c4.commit-last"
out=$(post_json c4 'git commit -m heal' '[main 4444444] heal' | bash "$hooks/commit.sh"); assert_contains "commit: corrupt marker self-heals" "$(ctx "$out")" "[main 4444444]"

out=$(post_json c2 'git commit -q -m quiet' '' | bash "$hooks/commit.sh"); assert_contains "commit: quiet commit (no stdout) still fires" "$(ctx "$out")" "Milestone: commit landed"
out=$(post_json c3 'git commit --amend --no-edit' '[main 3333333] amended' | bash "$hooks/commit.sh"); assert_contains "commit: amend counts" "$(ctx "$out")" "[main 3333333]"

report
