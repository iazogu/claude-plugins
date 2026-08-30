# roam-notes evals

## Shell tests (deterministic)

    bash evals/run-all.sh

Covers the resolver, both hooks, manifests/frontmatter, fixtures, and the genericity grep.

## Model eval (dry run, no Roam writes)

For each fixture, strip the hidden contract, then ask a fresh session with the plugin
loaded to note it in dry-run mode, and score the output against `rubric.md`:

    f=evals/fixtures/debugging-session.md
    sed '/<!-- MUST-/,/-->/d' "$f" > /tmp/narrative.md
    claude -p --plugin-dir plugins/roam-notes --model sonnet \
      "Here is a summary of a work session I just finished:\n\n$(cat /tmp/narrative.md)\n\nNote this to Roam as a dry run (do not write)."

Baseline arm: the same prompt without `--plugin-dir`. Record scores in `results.md`.
Fixtures are held-out data: never copy their content into the skill or the template.
