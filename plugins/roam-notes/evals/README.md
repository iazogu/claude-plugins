# roam-notes evals

All commands below run from the repo root.

## Shell tests (deterministic)

    bash plugins/roam-notes/evals/run-all.sh

Covers the resolver, both hooks, manifests/frontmatter, fixtures, and the genericity grep.

## Model eval (dry run, no Roam writes)

For each fixture, strip the hidden contract, then ask a fresh session with the plugin
loaded to note it in dry-run mode, and score the output against `rubric.md`. A `-p` session
denies every MCP tool unless it is explicitly allowed, so the Roam tools have to be passed to
`--allowedTools`, and the list below is read-only, which makes a real write structurally
impossible during an eval:

    ALLOW="Bash,Read,Glob,Write,Task,ToolSearch,mcp__roam-mcp__list_graphs,mcp__roam-mcp__get_graph_guidelines,mcp__roam-mcp__get_page,mcp__roam-mcp__get_block,mcp__roam-mcp__suggest_links"

    f=plugins/roam-notes/evals/fixtures/debugging-session.md
    sed '/<!-- MUST-/,/-->/d' "$f" > /tmp/narrative.md
    claude -p --allowedTools "$ALLOW" --model sonnet \
      "Here is a summary of a work session I just finished:\n\n$(cat /tmp/narrative.md)\n\nNote this to Roam as a dry run (do not write)." < /dev/null

`--allowedTools` takes a variadic list, so it must be followed by another flag (`--model`)
or it swallows the positional prompt; `< /dev/null` suppresses the stdin warning.

Baseline arm: the same prompt with the plugin disabled (`claude plugin disable
roam-notes`, then `claude plugin enable roam-notes` afterwards). Record scores in
`results.md`.
Fixtures are held-out data: never copy their content into the skill or the template.
