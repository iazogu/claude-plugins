#!/bin/bash
# resolve.sh [cwd] — print the Roam target for a working directory as JSON.
#   {"graph": string|null, "page", "section", "tag", "repoRoot", "pageSource"}
# Precedence: ROAM_NOTES_GRAPH env > <repo>/.claude/roam-notes.json > machine config > defaults.
# Machine config: ${XDG_CONFIG_HOME:-~/.config}/roam-notes/config.json
# Never fails on missing/malformed config; only on a missing jq.
set -u
command -v jq >/dev/null 2>&1 || { echo '{"error":"jq not found"}'; exit 1; }

cwd="${1:-$PWD}"
cwd=$(cd "$cwd" 2>/dev/null && pwd -P) || { echo '{"error":"cwd not found"}'; exit 1; }
machine_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/roam-notes/config.json"

# Main repo root = parent of the common git dir, so a worktree resolves to its primary checkout.
# Paths are physical (pwd -P): git reports a worktree's common dir as a physical path, so a repo
# and its own worktree would otherwise disagree whenever a parent directory is a symlink.
repo_root=""
common=$(cd "$cwd" && git rev-parse --git-common-dir 2>/dev/null)
if [ -n "$common" ]; then
  common_abs=$(cd "$cwd" && cd "$common" 2>/dev/null && pwd -P)
  [ -n "$common_abs" ] && repo_root=$(dirname "$common_abs")
fi
[ -n "$repo_root" ] || repo_root="$cwd"
project_cfg="$repo_root/.claude/roam-notes.json"

# cfg FILE FILTER [--arg k v] → value or empty; tolerates missing/malformed files
cfg() { f="$1"; shift; [ -f "$f" ] || return 0; jq -r "$@" "$f" 2>/dev/null | grep -v '^null$' || true; }

graph="${ROAM_NOTES_GRAPH:-}"
[ -n "$graph" ] || graph=$(cfg "$project_cfg" '.graph // empty')
[ -n "$graph" ] || graph=$(cfg "$machine_cfg" '.graph // empty')

section=$(cfg "$machine_cfg" '.section // empty'); [ -n "$section" ] || section="Claude Code"
tag=$(cfg "$machine_cfg" '.tag // empty');         [ -n "$tag" ]     || tag="#claude-notes"

titlecase() { printf '%s' "$1" | tr '_-' '  ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}; print}'; }

page_source="project-config"
page=$(cfg "$project_cfg" '.page // empty')
if [ -z "$page" ]; then
  page_source="machine-config"
  page=$(cfg "$machine_cfg" --arg r "$repo_root" '.projects[$r] // empty')
fi
if [ -z "$page" ]; then
  page_source="derived"
  page=$(titlecase "$(basename "$repo_root")")
fi

jq -n --arg graph "$graph" --arg page "$page" --arg section "$section" --arg tag "$tag" \
      --arg root "$repo_root" --arg src "$page_source" \
  '{graph: (if $graph == "" then null else $graph end), page: $page, section: $section, tag: $tag, repoRoot: $root, pageSource: $src}'
