# roam-notes model eval — dry-run results

Run on 2026-08-30, macOS, plugin installed at user scope from the local directory
marketplace (`roam-notes@iazogu-plugins`, live-linked to this repo). Model: `sonnet`.
All commands run from the repo root. No Roam write occurred in any run.

## Procedure actually used

`evals/README.md` documents this command:

    claude -p --plugin-dir plugins/roam-notes --model sonnet "…"

Two deviations were forced by the harness (see *Deviations* below):

    ALLOW="Bash,Read,Glob,Write,Task,ToolSearch,\
    mcp__roam-mcp__list_graphs,mcp__roam-mcp__get_graph_guidelines,\
    mcp__roam-mcp__get_page,mcp__roam-mcp__get_block,mcp__roam-mcp__suggest_links"

    f=plugins/roam-notes/evals/fixtures/<fixture>.md
    sed '/<!-- MUST-/,/-->/d' "$f" > /tmp/narrative.md
    claude -p --allowedTools "$ALLOW" --model sonnet \
      "Here is a summary of a work session I just finished:\n\n$(cat /tmp/narrative.md)\n\nNote this to Roam as a dry run (do not write)." < /dev/null

`--plugin-dir` is omitted because the plugin is installed. The baseline arm is the same
command with the plugin disabled (`claude plugin disable roam-notes`).

## Scores

Checks are the eight in `rubric.md`, in order:
1 anchor · 2 caps · 3 sentences with referents · 4 sparks generative · 5 links pre-exist ·
6 Roam syntax · 7 no log · 8 fixture contract.

| Run | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | Score |
|---|---|---|---|---|---|---|---|---|---|
| debugging-session — with plugin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 8/8 |
| feature-build — with plugin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 8/8 |
| config-session — with plugin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 8/8 |
| debugging-session — baseline (plugin disabled) | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ | ✗ | ✗ | 4/8 |

Plan expectation: with-plugin ≥ 7/8 on every fixture — **met** (8/8 × 3). Baseline fails
check 2, 7 or 8 on at least one — **met** (baseline fails 7 and 8, plus 1 and 3).

### Justification for every ✗ (baseline row only)

- **1 anchor ✗** — the first line (`**[[acme-billing]]** — nightly invoice job double-charged ~3% of customers #postmortem`) says what the session was about but never says what the project *is*; the "Django + Celery invoicing service" half of the anchor is missing.
- **3 sentences with referents ✗** — `**Fix:**`, `**Changed:**` and `**Commit:**` are label-plus-fragment items, not complete sentences (e.g. `Idempotency key derived from invoice id (Stripe confirmed dedup)`).
- **7 no log ✗** — `**Changed:** billing/tasks.py, billing/models.py, billing/tests/test_charge.py (+3 tests, 41/41 passing)` is exactly the file list and test count the check forbids, and `**Commit:**` adds commit-log narration.
- **8 fixture contract ✗** — both MUST-INCLUDE facts are present, but the MUST-EXCLUDE item "the list of files touched or the test count" appears verbatim in the `**Changed:**` bullet.

### Borderline calls on the baseline row (scored ✓, flagged for spot-check)

- **2 caps ✓** — the note has no Learnings/Sparks structure at all, so the caps barely map; counted literally it has 5 top-level body bullets (≤ 5) and 0 sparks (≤ 2), so it passes numerically. Counting the two `**Fix:**` sub-bullets as separate learnings would make it 6 and fail.
- **4 sparks generative ✓** — vacuous: there are zero sparks.
- **6 Roam syntax ✓** — read as a syntax check: a `#tag` is present on the first line, no `- [ ]`, no `####`, no italics. Note the tag is an invented `#postmortem`, not the resolver's configured `#claude-notes`; if `#tag` in the rubric means *the configured tag*, this is a ✗ and the baseline scores 3/8.

### Borderline calls on the with-plugin rows (scored ✓, flagged for spot-check)

- **debugging-session, check 8** — MUST-EXCLUDE forbids "the timezone red herring presented as a learning rather than as a ruled-out cause". The third learning does occupy a learning slot, but is framed explicitly as a ruled-out cause ("The cron timezone was a red herring… the cron ran correctly once"), which is the framing the exclusion permits. Scored ✓ on that reading.
- **feature-build, check 8** — MUST-EXCLUDE forbids "next week's task as a learning". The region-size estimate appears only in a **spark**, phrased as a question, not as a learning. Scored ✓ on that reading.
- **config-session, check 8** — MUST-EXCLUDE forbids "the step-by-step command sequence as a list". The learnings do quote commands, but as causal gotchas rather than an ordered recipe. Scored ✓.

## Deviations from the documented procedure

1. **`--allowedTools` added.** The first attempt used the README command verbatim. In `-p`
   mode every `mcp__roam-mcp__*` tool is denied by default, so the `note-companion` agent
   was blocked on `list_graphs` and `get_graph_guidelines` before it could compose
   anything, and the run produced no scoreable note (full output preserved below as
   *Run 0*). The allowlist grants only **read-only** Roam tools — `append_to_daily_note`,
   `create_block`, `update_block` and `create_page` are deliberately excluded, so a real
   write was structurally impossible in every run, which strengthens rather than weakens
   the dry-run guarantee.
2. **`< /dev/null` added.** Without it the CLI emits `Warning: no stdin data received in 3s`.
3. **Flag order.** `--allowedTools` takes a variadic `<tools...>` list and greedily swallows
   the positional prompt, so it must be followed by another flag (`--model`) before the
   prompt. `claude -p --model sonnet --allowedTools "…" "PROMPT"` fails with
   `Error: Input must be provided either through stdin or as a prompt argument`.

`evals/README.md` still documents the original command and was **not** updated — that is a
call for the orchestrator, since it changes a Task-8 deliverable.

## Findings worth the orchestrator's attention

- **`suggest_links` is unavailable on this graph/server** — every run reported it failing
  (`UNKNOWN_ACTION` / not implemented). The agent degraded correctly: it added no links
  beyond the project link rather than inventing pages, so check 5 passes, but it passes
  *vacuously* in all four runs. Check 5's real behaviour ("links were applied
  `suggest_links` suggestions") is therefore **untested** by this eval.
- **Project-page derivation is inconsistent across runs.** The resolver derives the page
  from the cwd, which is this repo, so `debugging-session` and `feature-build` were both
  filed under `[[Claude Plugins]]` while their narratives describe `acme-billing` and
  `trail-maps`; both runs flagged the mismatch to the user unprompted, which is good
  behaviour. But `config-session` instead used `[[Home Lab]]`, matching its narrative
  rather than the cwd. Same prompt shape, same cwd, different page-selection policy.
- **Harness limitation.** Because `README.md` specifies running from the repo root, no
  fixture whose narrative names a different project can exercise the project-link half of
  check 1 faithfully. Check 1 was scored on anchor *shape* (link present + what the project
  is + what the session was about, in one line), not on whether the link names the
  fixture's project.

## Full run outputs (verbatim)

### Run 0 — debugging-session, with plugin, README command verbatim (no scoreable output)

`claude -p --model sonnet "…"` — MCP tools denied in `-p` mode; not scored.

````
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
The dry run couldn't complete — the `roam-mcp` tools are blocked for this session's permission grant, so the agent was denied on both `list_graphs` and `get_graph_guidelines` before it could even orient itself. It correctly stopped rather than working around the denial, and confirmed nothing was read or written.

To actually run this (even as a dry run), the `mcp__roam-mcp__*` tools need to be allowed for this session — either grant them when prompted, or run `/mcp` interactively to authorize the Roam server.

The composed note itself (shown above) is ready whenever you want to try again — nothing about the content is blocked, just the Roam-side access.
````

### Run 1 — debugging-session, with plugin (scored, 8/8)

`claude -p --allowedTools "$ALLOW" --model sonnet "…" < /dev/null`

````
Dry run finished — nothing was written to Roam. Here's what it would have written to today's daily note (Aug 30, under a new "Claude Code" section):

```
- **[[Claude Plugins]]** — The Django + Celery service that issues our monthly invoices. Today we found why the nightly job double-charged 3% of customers. #claude-notes
  - **Learnings**
    - The double charge came from Celery retrying a task that had already charged: `acks_late=True` re-queues on timeout past the 30-second soft time limit, and `stripe.Charge.create` was called without an idempotency key.
    - Stripe idempotency keys expire after 24 hours, so relying on them alone doesn't prevent a retry the following night from double-charging — we added a check on `invoice.charged_at` as a second guard.
    - The cron timezone was a red herring: the 02:00 clustering suggested a DST bug, but the cron ran correctly once; the duplicate charge happened inside the Celery worker, about 31 seconds apart.
  - **Sparks**
    - Which other Celery tasks in this codebase have `acks_late=True` paired with a non-idempotent side effect?
    - Could the idempotency key encode a longer window (e.g. invoice period) so retries across days still dedupe without needing the `charged_at` check?
```

Two things to know before a real write:
- **Wrong project page**: it's filed under `[[Claude Plugins]]` (derived from this repo's folder name) rather than `[[Acme Billing]]`, since acme-billing isn't this repo. Fix by running the skill from the acme-billing repo, or adding `.claude/roam-notes.json` there with `"page": "Acme Billing"`.
- **Link suggestions unavailable**: the graph's `suggest_links` tool errored server-side, so no `[[...]]` links beyond the project link would be added.
````

### Run 2 — feature-build, with plugin (scored, 8/8)

`claude -p --allowedTools "$ALLOW" --model sonnet "…" < /dev/null`

````
Dry run complete — nothing was written. Preview:

```
- **[[Claude Plugins]]** — Trail-maps is a Next.js 15 App Router app with Mapbox GL for hikers. This session added offline caching of map tiles so a downloaded region stays viewable without signal. #claude-notes
  - **Learnings**
    - The App Router does not register a service worker automatically — it has to be called from a client component with `navigator.serviceWorker.register` after mount, or it silently never installs in production builds.
    - Safari caps Cache Storage per origin at roughly 50MB, so an unbounded tile cache stopped growing there; LRU eviction keyed by last access was added to stay under that ceiling.
    - Mapbox tile URLs carry the access_token as a query parameter, so caching the full URL was persisting the token in Cache Storage on the device; stripping the query string from the cache key and re-appending the token on fetch fixed it.
  - **Sparks**
    - Could the ~50MB Safari Cache Storage ceiling be the basis for the region-size estimate the user wants to look at next week?
    - Now that the cache key excludes the token, could tiles be pre-seeded or shared across sessions without re-authenticating?
```

Would land under **Claude Code** on today's daily note (Aug 30, 2026), on graph `nexveil` (the only one configured).

Two things flagged by the agent, worth your attention before a real write:
1. **Page mismatch** — as noted earlier, it's titled `[[Claude Plugins]]` (derived from this repo) even though the content is about trail-maps. A real run from here would misfile it; you'd want a `.claude/roam-notes.json` override or to run this from the trail-maps repo.
2. `suggest_links` failed (`UNKNOWN_ACTION` — not available on this graph/server), so no auto-linking was attempted; that's just a missing nice-to-have, not a blocker.
````

### Run 3 — config-session, with plugin (scored, 8/8)

`claude -p --allowedTools "$ALLOW" --model sonnet "…" < /dev/null`

````
Dry run complete — nothing was written to Roam. Here's what it would have added under **Claude Code** on today's daily note (August 30th, 2026), in the `nexveil` graph:

> - **[[Home Lab]]** — Home-lab is a Raspberry Pi behind Tailscale; this session turned it into a Tailscale exit node so phones can route traffic through home. #claude-notes
>   - **Learnings**
>     - Advertising an exit node with `tailscale up --advertise-exit-node` succeeds silently and shows no error, but does nothing until an admin approves the route in the Tailscale admin console's machine settings.
>     - Even after approval, exit-node traffic still won't route until IP forwarding is enabled with `sysctl -w net.ipv4.ip_forward=1`.
>     - IP forwarding resets on reboot, so it has to be persisted in `/etc/sysctl.d/99-tailscale.conf` or the exit node silently stops working again after a restart.
>     - Poor exit-node throughput was not a CPU problem (CPU stayed idle) — the real bottleneck was the SD card being hammered by logging and swap, fixed by moving swap off the card.
>   - **Sparks**
>     - Could logging also be moved off the SD card (e.g. to tmpfs) to cut wear and push throughput further?
>     - Are other Tailscale features (like subnet routers) gated behind the same silent admin-console approval step?

One note: link suggestions couldn't run (the `suggest_links` action isn't implemented on this MCP server), so no auto-linking was attempted beyond the `[[Home Lab]]` page reference. Say the word if you want this actually written.
````

### Run 4 — debugging-session, BASELINE with plugin disabled (scored, 4/8)

`claude plugin disable roam-notes` then the same command; plugin re-enabled and verified afterwards.

````
Today's daily note (`August 30th, 2026`) is empty aside from the title, and this graph has no recorded guidelines (naming conventions, structural preferences), so there's no established pattern to match. Here's the draft entry, formatted in Roam markdown, that I would append to today's daily note — **nothing has been written**, per the dry-run request:

```
- **[[acme-billing]]** — nightly invoice job double-charged ~3% of customers #postmortem
    - **Symptom:** `charge_invoice` ran twice per affected invoice, ~31s apart, clustered near 02:00. Not a DST/cron bug — cron schedule and worker logs confirmed a single trigger.
    - **Root cause:** task uses `acks_late=True`; the first run exceeded the 30s soft time limit, the broker redelivered it, and `stripe.Charge.create` had no idempotency key — so the redelivery charged again.
    - **Fix:**
        - Idempotency key derived from invoice id (Stripe confirmed dedup)
        - Since Stripe idempotency keys expire after 24h, also gated the task on `invoice.charged_at` to cover a retry the following night
    - **Changed:** `billing/tasks.py`, `billing/models.py`, `billing/tests/test_charge.py` (+3 tests, 41/41 passing)
    - **Commit:** "fix: make charge_invoice idempotent"
```

A couple of judgment calls I made drafting this, worth confirming before an actual write:
- Target: today's daily note, since that's this graph's default workspace and no project-specific page convention exists yet.
- `[[acme-billing]]` as a page link (so future incidents on this project roll up under one page) and `#postmortem` as a tag — pick different tags/links if you have a convention I'm not seeing.

Say the word if you want me to actually write this (and where), or tweak the content first.
````


## Live write (Task 10 step 4) — 2026-08-30

From `/tmp/roam-notes-live-test` (fresh git repo, plugin installed, `--dangerously-skip-permissions` to mirror real usage):

- Relay line: `Noted to Roam: [[Roam Notes Live Test]], 2026-08-30 — 2 learnings, 1 spark.` plus the derived-page override hint, exactly per SKILL.md step 4.
- Read back via `get_page` on the daily note: entry block `KPdyd6wfk` under a new top-level `Claude Code` section (`VyNTCIejU`), anchor within the two-short-sentences rule, 2 full-sentence learnings, 1 question-form spark, `#claude-notes` tag present.
- Cleanup verified: deleted section block `VyNTCIejU` (whole tree) and the link-created page `Roam Notes Live Test` (`0mbogn067`, empty, 0 refs); daily note restored to its prior (empty) state.
