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

> - **[[Acme Billing]]** — the Django service that issues our monthly invoices. Today we found why the nightly job double-charged 3% of customers. #claude-notes
>   - **Learnings**
>     - The double charge came from Celery retrying a task that had already charged: `acks_late=True` re-queues on timeout, and the charge step was not idempotent.
>     - Stripe idempotency keys expire after 24 hours, so a key reused by a retry the next night creates a second charge instead of deduplicating.
>     - The cron timezone was a red herring — the job ran at the right time; the retry happened inside the worker.
>   - **Sparks**
>     - Which other Celery tasks in this codebase have `acks_late=True` and a non-idempotent side effect?
>     - Could the idempotency key carry the invoice period so retries across days still dedupe?

## What passes the test

A line earns its place only if, having forgotten the project, reading it snaps context
back: a cause, a quirk, a constraint, a fact that cost time to discover.

Cut: file lists, timelines ("first we… then we…"), what was done rather than what was
learned, restatements of the anchor, anything obvious to a competent engineer.

Style: full sentences, one idea per bullet, the concrete example inside the sentence,
jargon glossed in a clause at first use. No "label — fragment; fragment" chains.
