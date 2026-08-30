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

# agent
a="$root/agents/note-companion.md"
assert_file "agent exists" "$a"
fm=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f' "$a" 2>/dev/null)
assert_contains "agent name" "$fm" "name: note-companion"
assert_contains "agent model sonnet" "$fm" "model: sonnet"
for t in mcp__roam-mcp__get_graph_guidelines mcp__roam-mcp__list_graphs mcp__roam-mcp__get_page mcp__roam-mcp__get_block mcp__roam-mcp__suggest_links mcp__roam-mcp__append_to_daily_note mcp__roam-mcp__create_block ToolSearch Read Write Glob Bash; do
  assert_contains "agent tool $t" "$fm" "$t"
done
for t in delete_block delete_page update_block update_page move_block create_page; do
  assert_empty "agent must not list $t" "$(printf '%s' "$fm" | grep -o "mcp__roam-mcp__$t")"
done
body=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{f=0;next} !f' "$a")
for phrase in "dry_run" "outbox" "suggest_links" "already noted" "never" "todaysDailyNotePage" "nestUnder"; do
  assert_contains "agent body mentions $phrase" "$body" "$phrase"
done

# skill
s="$root/skills/roam-notes/SKILL.md"
assert_file "skill exists" "$s"
sfm=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f' "$s" 2>/dev/null)
assert_contains "skill name" "$sfm" "name: roam-notes"
for phrase in "note this" "capture learnings" "Invoke the roam-notes skill" "Roam"; do
  assert_contains "skill description triggers on '$phrase'" "$sfm" "$phrase"
done
sbody=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{f=0;next} !f' "$s")
for phrase in "scripts/resolve.sh" "roam-notes:note-companion" "would I have to re-discover" "at most 5" "at most 2" "nothing worth noting" "Noted to Roam" "dry_run" "template.md"; do
  assert_contains "skill body mentions $phrase" "$sbody" "$phrase"
done
assert_file "template exists" "$root/skills/roam-notes/template.md"
assert_contains "template has Acme example" "$(cat "$root/skills/roam-notes/template.md")" "[[Acme Billing]]"
assert_contains "template has Sparks" "$(cat "$root/skills/roam-notes/template.md")" "**Sparks**"

# fixtures + rubric
for f in debugging-session feature-build config-session; do
  p="$root/evals/fixtures/$f.md"
  assert_file "fixture $f" "$p"
  assert_contains "fixture $f has MUST-INCLUDE" "$(cat "$p" 2>/dev/null)" "<!-- MUST-INCLUDE:"
  assert_contains "fixture $f has MUST-EXCLUDE" "$(cat "$p" 2>/dev/null)" "<!-- MUST-EXCLUDE:"
  assert_empty "fixture $f strips clean" "$(sed '/<!-- MUST-/,/-->/d' "$p" 2>/dev/null | grep -c 'MUST-' | grep -v '^0$')"
done
assert_file "rubric" "$root/evals/rubric.md"
assert_eq "rubric has 8 numbered checks" "$(grep -cE '^[0-9]\. \*\*' "$root/evals/rubric.md" 2>/dev/null)" "8"
report
