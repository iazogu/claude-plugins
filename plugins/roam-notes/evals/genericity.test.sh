#!/bin/bash
# The plugin must contain no machine- or owner-specific strings outside README files.
. "$(dirname "$0")/lib.sh"
root="$(cd "$(dirname "$0")/.." && pwd)"
# This test is excluded from its own scan: it necessarily spells out the strings it forbids.
# results.md is excluded too: it records verbatim eval transcripts from a real machine and
# graph, so owner-specific strings there are the data, not a leak into plugin code.
hits=$(grep -rniE 'nexveil|manhood|ikechukwu|iazogu' "$root" \
  --exclude=README.md --exclude=results.md --exclude="$(basename "$0")" --exclude-dir=.git 2>/dev/null)
assert_empty "no owner/machine strings in plugin code" "$hits"
assert_file "plugin manifest exists" "$root/.claude-plugin/plugin.json"
assert_eq "plugin manifest name" "$(jq -r .name "$root/.claude-plugin/plugin.json" 2>/dev/null)" "roam-notes"
report
