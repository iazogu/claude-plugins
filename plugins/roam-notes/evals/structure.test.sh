#!/bin/bash
# Manifests, hook wiring, skill and agent frontmatter are shaped as the spec requires.
. "$(dirname "$0")/lib.sh"
root="$(cd "$(dirname "$0")/.." && pwd)"

# hooks.json
h="$root/hooks/hooks.json"
assert_file "hooks.json exists" "$h"
assert_eq "hooks.json is valid JSON" "$(jq -e . "$h" >/dev/null 2>&1 && echo ok)" "ok"
assert_eq "Stop hook command" "$(jq -r '.hooks.Stop[0].hooks[0].command' "$h" 2>/dev/null)" '"${CLAUDE_PLUGIN_ROOT}"/hooks/milestone.sh'
assert_eq "PostToolUse matcher" "$(jq -r '.hooks.PostToolUse[0].matcher' "$h" 2>/dev/null)" "Bash"
assert_eq "PostToolUse command" "$(jq -r '.hooks.PostToolUse[0].hooks[0].command' "$h" 2>/dev/null)" '"${CLAUDE_PLUGIN_ROOT}"/hooks/commit.sh'
for s in milestone.sh commit.sh; do
  assert_eq "$s is executable" "$( [ -x "$root/hooks/$s" ] && echo yes )" "yes"
done
report
