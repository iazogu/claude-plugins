# roam-notes

Memory-trigger notes to Roam at milestones. After a plan completes or a commit lands (or
when you say "note this"), the session writes an entry to today's daily note — one anchor
sentence, up to five learnings, up to two sparks — under a `Claude Code` section, tagged
`#claude-notes`, linked to pages that already exist in your graph.

## Install (any machine)

    claude mcp add --scope user roam-mcp -- npx -y @roam-research/roam-mcp
    claude plugin marketplace add iazogu/claude-plugins
    claude plugin install roam-notes@iazogu-plugins

Then inside Claude Code: "connect my Roam graph" — the `setup_new_graph` tool walks you
through approving a Local API token in the Roam desktop app. The token is per machine.

Requirements: Roam desktop app signed in to the graph, `jq`, Node (for `npx`).

## Configure (optional)

`~/.config/roam-notes/config.json` — see `config.example.json`. Needed only when the
machine has more than one graph, or you want a page title other than the derived one
(`manhood-u` → `Manhood U`). Per-repo override: `<repo>/.claude/roam-notes.json` with
`{"page": "…", "graph": "…"}`. `ROAM_NOTES_GRAPH` overrides the graph for one shell.
Each `projects` key must be the repo's physical path — what `pwd -P` prints, symlinks
resolved — because the resolver normalizes worktrees and symlinked parents to that one
canonical path.

## How it works

- `hooks/milestone.sh` (Stop) and `hooks/commit.sh` (PostToolUse on Bash) nudge the
  session once per milestone.
- `skills/roam-notes` has the session compose the hand-off (the judgement).
- `agents/note-companion` links, dedupes and writes (the execution). It cannot delete,
  move or edit existing blocks.
- Failed writes land in `~/.local/state/roam-notes/outbox/` and replay on the next run.

## Test

    bash plugins/roam-notes/evals/run-all.sh

See `evals/README.md` for the model eval.
