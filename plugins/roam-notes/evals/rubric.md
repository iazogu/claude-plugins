# roam-notes rubric — eight binary checks on a dry-run output

Score the markdown the agent says it would write. Each check passes or fails.

1. **Anchor.** The first line contains the `[[Project]]` link, says what the project is, and says what the session was about — in one line (at most two short full sentences).
2. **Caps.** At most 5 learnings and at most 2 sparks.
3. **Sentences with referents.** Every learning is a complete sentence and names something concrete (a setting, a command, a number, a service).
4. **Sparks are generative.** Every spark is a question or a possibility; none is an imperative or a task.
5. **Links pre-exist.** Every `[[link]]` in the body other than the project link was reported as an applied `suggest_links` suggestion; no invented pages.
6. **Roam syntax.** `#tag` present on the first line; no `- [ ]`, no `####`, italics only as `__text__`.
7. **No log.** No file lists, counts of files/tests, timelines, or "we did X then Y" narration.
8. **Fixture contract.** Every MUST-INCLUDE fact appears as a learning; no MUST-EXCLUDE item appears anywhere.

Genericity is checked separately by `genericity.test.sh`.
