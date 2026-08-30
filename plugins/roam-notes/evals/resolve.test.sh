#!/bin/bash
# resolve.sh: derived titles, worktrees, precedence, defaults.
. "$(dirname "$0")/lib.sh"
resolve="$(cd "$(dirname "$0")/../skills/roam-notes/scripts" && pwd)/resolve.sh"
# tmp is normalized to a physical path: on macOS mktemp -d sits under the /var -> /private/var
# symlink, and git reports a worktree's common dir physically. repoRoot is physical too.
tmp=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$tmp"' EXIT
export XDG_CONFIG_HOME="$tmp/xdg"; mkdir -p "$XDG_CONFIG_HOME/roam-notes"
unset ROAM_NOTES_GRAPH
G="git -c user.name=t -c user.email=t@t"

# a main repo with one commit, and a worktree of it
mkdir -p "$tmp/restaurant-delivery-pickup" && (cd "$tmp/restaurant-delivery-pickup" && git init -q && $G commit -q --allow-empty -m init && git worktree add -q "$tmp/restaurant-delivery-pickup/.claude/worktrees/agent-abc123" -b wt >/dev/null 2>&1)
mkdir -p "$tmp/restaurant-delivery-pickup/src/deep"
mkdir -p "$tmp/no_git_here"

out=$(bash "$resolve" "$tmp/restaurant-delivery-pickup")
assert_eq "derived title from repo basename" "$(printf '%s' "$out" | jq -r .page)" "Restaurant Delivery Pickup"
assert_eq "derived pageSource" "$(printf '%s' "$out" | jq -r .pageSource)" "derived"
assert_eq "graph null when unconfigured" "$(printf '%s' "$out" | jq -r .graph)" "null"
assert_eq "default section" "$(printf '%s' "$out" | jq -r .section)" "Claude Code"
assert_eq "default tag" "$(printf '%s' "$out" | jq -r .tag)" "#claude-notes"

out=$(bash "$resolve" "$tmp/restaurant-delivery-pickup/src/deep")
assert_eq "subdir resolves to repo root" "$(printf '%s' "$out" | jq -r .repoRoot)" "$tmp/restaurant-delivery-pickup"

out=$(bash "$resolve" "$tmp/restaurant-delivery-pickup/.claude/worktrees/agent-abc123")
assert_eq "worktree resolves to main repo title" "$(printf '%s' "$out" | jq -r .page)" "Restaurant Delivery Pickup"
assert_eq "worktree repoRoot is main repo" "$(printf '%s' "$out" | jq -r .repoRoot)" "$tmp/restaurant-delivery-pickup"

out=$(bash "$resolve" "$tmp/no_git_here")
assert_eq "no git: cwd basename title-cased" "$(printf '%s' "$out" | jq -r .page)" "No Git Here"
assert_eq "no git: repoRoot is cwd" "$(printf '%s' "$out" | jq -r .repoRoot)" "$tmp/no_git_here"

# machine config: graph, section, tag, projects override
cat > "$XDG_CONFIG_HOME/roam-notes/config.json" <<EOF
{"graph":"personal","section":"Sessions","tag":"#ai","projects":{"$tmp/restaurant-delivery-pickup":"RDP App"}}
EOF
out=$(bash "$resolve" "$tmp/restaurant-delivery-pickup")
assert_eq "machine projects override" "$(printf '%s' "$out" | jq -r .page)" "RDP App"
assert_eq "machine pageSource" "$(printf '%s' "$out" | jq -r .pageSource)" "machine-config"
assert_eq "machine graph" "$(printf '%s' "$out" | jq -r .graph)" "personal"
assert_eq "machine section" "$(printf '%s' "$out" | jq -r .section)" "Sessions"
assert_eq "machine tag" "$(printf '%s' "$out" | jq -r .tag)" "#ai"

# project config beats machine config
mkdir -p "$tmp/restaurant-delivery-pickup/.claude"
echo '{"page":"Delivery","graph":"work"}' > "$tmp/restaurant-delivery-pickup/.claude/roam-notes.json"
out=$(bash "$resolve" "$tmp/restaurant-delivery-pickup")
assert_eq "project page beats machine" "$(printf '%s' "$out" | jq -r .page)" "Delivery"
assert_eq "project pageSource" "$(printf '%s' "$out" | jq -r .pageSource)" "project-config"
assert_eq "project graph beats machine" "$(printf '%s' "$out" | jq -r .graph)" "work"
out=$(bash "$resolve" "$tmp/restaurant-delivery-pickup/.claude/worktrees/agent-abc123")
assert_eq "worktree sees main repo project config" "$(printf '%s' "$out" | jq -r .page)" "Delivery"

# env beats everything for graph
out=$(ROAM_NOTES_GRAPH=override bash "$resolve" "$tmp/restaurant-delivery-pickup")
assert_eq "env graph beats project" "$(printf '%s' "$out" | jq -r .graph)" "override"

# malformed machine config does not break derivation
echo '{not json' > "$XDG_CONFIG_HOME/roam-notes/config.json"
rm "$tmp/restaurant-delivery-pickup/.claude/roam-notes.json"
out=$(bash "$resolve" "$tmp/restaurant-delivery-pickup")
assert_eq "malformed config falls back to derived" "$(printf '%s' "$out" | jq -r .page)" "Restaurant Delivery Pickup"
report
