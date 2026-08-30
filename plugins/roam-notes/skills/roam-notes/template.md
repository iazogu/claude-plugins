# The note shape

One Roam bullet tree, appended under the configured top-level section (default
`Claude Code`) on today's daily note:

```
- **[[<Project>]]** — <what the project is + what this session was about — one line, at most two short full sentences>. <tag>
  - **Learnings**
    - <complete sentence with its concrete example inside it>
    - …(max 5)
  - **Sparks**
    - <question or possibility the learnings open up>
    - …(max 2; omit the block when empty)
```

## Worked example

> - **[[Acme Search]]** — the service that indexes our product catalog into OpenSearch. Today we found why a full reindex silently lost about one document in fifty. #claude-notes
>   - **Learnings**
>     - The lost documents came from the bulk API reporting per-item failures inside a `200 OK` response: the indexer checked only the HTTP status, so every `429` rejection in the `items` array was discarded as a success.
>     - An alias swap is atomic for new searches but not for in-flight scroll cursors, so a query that started before the swap keeps reading the retired index until its cursor expires.
>     - The mapping change was a red herring — the `keyword` field was identical in both indices; the whole gap was in what the bulk writer threw away.
>   - **Sparks**
>     - Which other writers in this codebase treat a `200 OK` from a bulk endpoint as success without reading the per-item results?
>     - Could the reindex job compare its document count against the catalogue database before the alias swap, so a lossy run never goes live?

## What passes the test

A line earns its place only if, having forgotten the project, reading it snaps context
back: a cause, a quirk, a constraint, a fact that cost time to discover.

Cut: file lists, timelines ("first we… then we…"), what was done rather than what was
learned, restatements of the anchor, anything obvious to a competent engineer.

Style: full sentences, one idea per bullet, the concrete example inside the sentence,
jargon glossed in a clause at first use. No "label — fragment; fragment" chains.
