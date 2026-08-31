# roam-notes model eval — dry-run results

Run on 2026-08-30, macOS, plugin installed at user scope from the local directory
marketplace (`roam-notes@<marketplace>`, refreshed from this repo before each batch).
Model: `sonnet`. All commands run from the repo root. No Roam write occurred in any run.
The two debugging-session arms were re-run on 2026-08-30 after the final whole-branch
review found that `template.md`'s worked example shared its scenario and several verbatim
strings with the `debugging-session` fixture, which contaminated the original arm.

## Procedure actually used

`evals/README.md` documents this command, and it is what these runs used:

    ALLOW="Bash,Read,Glob,Write,Task,ToolSearch,\
    mcp__roam-mcp__list_graphs,mcp__roam-mcp__get_graph_guidelines,\
    mcp__roam-mcp__get_page,mcp__roam-mcp__get_block,mcp__roam-mcp__suggest_links"

    f=plugins/roam-notes/evals/fixtures/<fixture>.md
    sed '/<!-- MUST-/,/-->/d' "$f" > /tmp/narrative.md
    claude -p --allowedTools "$ALLOW" --model sonnet \
      "Here is a summary of a work session I just finished:\n\n$(cat /tmp/narrative.md)\n\nNote this to Roam as a dry run (do not write)." < /dev/null

The plugin is installed at user scope, so no `--plugin-dir` is needed. The allowlist, the
flag order and the `< /dev/null` were added to the README after the first attempt hit the
harness limits recorded under *Deviations* below. The baseline arm is the same command with
the plugin disabled (`claude plugin disable roam-notes`).

## Scores

Checks are the eight in `rubric.md`, in order:
1 anchor · 2 caps · 3 sentences with referents · 4 sparks generative · 5 links pre-exist ·
6 Roam syntax · 7 no log · 8 fixture contract.

| Run | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | Score |
|---|---|---|---|---|---|---|---|---|---|
| debugging-session — with plugin (re-run, decontaminated template) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 8/8 |
| feature-build — with plugin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 8/8 |
| config-session — with plugin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 8/8 |
| debugging-session — baseline (plugin disabled), re-run | — | — | — | — | — | — | — | — | not scored |

Plan expectation: with-plugin ≥ 7/8 on every fixture — **met** (8/8 × 3), and the
debugging-session arm holds at 8/8 with the template's worked example moved to an unrelated
domain, so the original score was not an artefact of the shared scenario.

Baseline fails check 2, 7 or 8 on at least one — **no longer demonstrated by this re-run**.
Both baseline attempts were invalid (below); the last uncontaminated baseline measurement is
the original batch's 4/8, which is superseded rather than reproduced.

### Why the re-run baseline is not scored

The baseline arm runs from the repo root with the plugin *disabled* — but the plugin's own
source is still sitting in that working directory, and `--allowedTools` grants `Read`, `Glob`
and `Bash`. Both attempts read it:

- **Attempt 1** said so outright: *"I ran the roam-notes dry-run pipeline by hand (its
  `note-companion` agent isn't registered as a callable type in this session, so I executed
  its documented steps directly)"*, then reproduced `resolve.sh`'s page derivation and
  `nestUnder: "Claude Code"`. Its note would score 8/8 on the rubric — which is precisely why
  it cannot be recorded as a baseline: it measures "the plugin's instructions read off disk",
  not "no plugin".
- **Attempt 2** read `evals/results.md` itself and answered by comparing against Run 1 rather
  than composing a note at all, so there is nothing to score.

Two attempts is the cap, so the arm is left unscored. Re-establishing a valid baseline needs a
working directory that does not contain the plugin's source (and no recorded results to read);
that is a change to the documented procedure, so it is left for the orchestrator. The original
batch's baseline happened to avoid this exposure, which is why it scored 4/8.

### Borderline calls on the with-plugin rows (scored ✓, flagged for spot-check)

- **debugging-session (re-run), check 8** — MUST-EXCLUDE forbids "the timezone red herring presented as a learning rather than as a ruled-out cause". The third learning occupies a learning slot but is framed explicitly as a ruled-out cause ("looked like a DST/timezone bug but was a red herring — the cron fired exactly once"), which is the framing the exclusion permits. Scored ✓ on that reading, the same reading used in the original batch.
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

`evals/README.md` documents this invocation, so the command above and the README agree.

## Findings worth the orchestrator's attention

- **`suggest_links` is unavailable on this graph/server** — every run reported it failing
  (`UNKNOWN_ACTION` / not implemented). The agent degraded correctly: it added no links
  beyond the project link rather than inventing pages, so check 5 passes, but it passes
  *vacuously* in all four runs. Check 5's real behaviour ("links were applied
  `suggest_links` suggestions") is therefore **untested** by this eval.
- **Project-page derivation is inconsistent across runs.** The resolver derives the page
  from the cwd, which is this repo, so `feature-build` was filed under `[[Claude Plugins]]`
  while its narrative describes `trail-maps`; that run flagged the mismatch to the user
  unprompted, which is good behaviour. `config-session` instead used `[[Home Lab]]` and the
  debugging-session re-run `[[Acme Billing]]`, both matching the narrative rather than the
  cwd and both saying so. Same prompt shape, same cwd, different page-selection policy.
- **Harness limitation.** Because `README.md` specifies running from the repo root, no
  fixture whose narrative names a different project can exercise the project-link half of
  check 1 faithfully. Check 1 was scored on anchor *shape* (link present + what the project
  is + what the session was about, in one line), not on whether the link names the
  fixture's project.

## Full run outputs (verbatim)

### Run 0 — debugging-session, with plugin, original batch, README command verbatim (no scoreable output)

`claude -p --model sonnet "…"` — MCP tools denied in `-p` mode; not scored.

````
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
The dry run couldn't complete — the `roam-mcp` tools are blocked for this session's permission grant, so the agent was denied on both `list_graphs` and `get_graph_guidelines` before it could even orient itself. It correctly stopped rather than working around the denial, and confirmed nothing was read or written.

To actually run this (even as a dry run), the `mcp__roam-mcp__*` tools need to be allowed for this session — either grant them when prompted, or run `/mcp` interactively to authorize the Roam server.

The composed note itself (shown above) is ready whenever you want to try again — nothing about the content is blocked, just the Roam-side access.
````

### Run 1 — debugging-session, with plugin, re-run after the template rewrite (scored, 8/8)

`claude -p --allowedTools "$ALLOW" --model sonnet "…" < /dev/null`

The repo's own `docs/superpowers/plans` directory was moved aside for the duration of each
re-run: with the milestone hook now watching that directory, a first attempt had its Stop
hook fire mid-run on this repo's completed plan and the session composed a *second*, unrelated
note about building the plugin, leaving no scoreable final message. Moving the directory back
afterwards leaves the plan file's content and mtime untouched.

````
Dry run complete — nothing written to Roam. Preview:

```
- **[[Acme Billing]]** — Acme Billing is a Django + Celery invoicing service. This session tracked down why the nightly invoice job double-charged about 3% of customers. #claude-notes
  - **Learnings**
    - The double charges came from Celery's `acks_late=True` re-delivering `charge_invoice` after the first run blew past its 30s soft time limit, so the redelivered task fired `stripe.Charge.create` again about 31 seconds later with no idempotency key to stop it.
    - Stripe idempotency keys expire after 24 hours, so keying charges on the invoice id alone would not prevent a repeat double-charge on a retry the following night — the fix also had to gate on `invoice.charged_at` before ever calling Stripe.
    - The duplicates clustering around 02:00 looked like a DST/timezone bug but was a red herring — the cron fired exactly once; the real cause was task duration relative to the soft time limit, unrelated to the hour.
  - **Sparks**
    - Are there other Celery tasks with `acks_late=True` calling non-idempotent external APIs (email sends, webhook posts) that could double-fire the same way?
    - Could the soft time limit be raised, or the Stripe call moved earlier in the task, so slow runs never approach the limit in the first place?
```

It would append this under a new "Claude Code" section on today's daily note (Aug 30, 2026) in the `<graph>` graph, under `[[Acme Billing]]` — that page override was mine, not the resolver's default (`Claude Plugins`). Say the word if you want me to actually write it.
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

Would land under **Claude Code** on today's daily note (Aug 30, 2026), on graph `<graph>` (the only one configured).

Two things flagged by the agent, worth your attention before a real write:
1. **Page mismatch** — as noted earlier, it's titled `[[Claude Plugins]]` (derived from this repo) even though the content is about trail-maps. A real run from here would misfile it; you'd want a `.claude/roam-notes.json` override or to run this from the trail-maps repo.
2. `suggest_links` failed (`UNKNOWN_ACTION` — not available on this graph/server), so no auto-linking was attempted; that's just a missing nice-to-have, not a blocker.
````

### Run 3 — config-session, with plugin (scored, 8/8)

`claude -p --allowedTools "$ALLOW" --model sonnet "…" < /dev/null`

````
Dry run complete — nothing was written to Roam. Here's what it would have added under **Claude Code** on today's daily note (August 30th, 2026), in the `<graph>` graph:

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

### Run 4 — debugging-session, BASELINE with plugin disabled, re-run (not scored)

`claude plugin disable roam-notes` then the same command; plugin re-enabled and verified with
`claude plugin list` after each attempt (`✔ enabled`). Both attempts read the plugin's source
out of the working directory, so neither is a baseline — see *Why the re-run baseline is not
scored*.

**Attempt 1** — composed a full note, but by executing the skill's documented steps read from
disk:

````
I ran the roam-notes dry-run pipeline by hand (its `note-companion` agent isn't registered as a callable type in this session, so I executed its documented steps directly). Two things surfaced worth flagging before anything real would get written:

**1. Project-page mismatch.** `resolve.sh` derives the Roam page from the *current repo's* name — here that's `Claude Plugins`, since no `.claude/roam-notes.json` override exists. But your summary is about `acme-billing`, an unrelated project. Filing a Stripe/Celery bug note under a "Claude Plugins" page would misfile it. I used judgment and targeted **`[[Acme Billing]]`** instead, since that's what the content is actually about — but you'll hit this every time you note an unrelated session from this cwd. If you do this often, worth adding a project override or running roam-notes from within the actual repo.

**2. `suggest_links` isn't implemented on your `<graph>` graph's MCP server** — it returned `UNKNOWN_ACTION`. So this preview applies zero links (none suggested, none rejected), not because none fit.

Here's what a real (non-dry) run would write — nothing has been sent to Roam:

**Target:** `append_to_daily_note` on *August 30th, 2026*, `nestUnder: "Claude Code"` (no existing entry for this project today — that section doesn't exist yet on the page either, so it'd be created).

```
- **[[Acme Billing]]** — the Django + Celery service that generates and charges nightly customer invoices. This session tracked down why the nightly invoice job double-charged about 3% of customers. #claude-notes
  - **Learnings**
    - The double charges came from Celery's `acks_late=True` combined with the task's 30-second soft time limit: when `charge_invoice` ran long, the broker treated it as lost and redelivered it, so `stripe.Charge.create` fired twice about 31 seconds apart with nothing to stop the second call.
    - A Stripe idempotency key alone doesn't fully close the hole because Stripe expires idempotency keys after 24 hours, so a redelivery on a later night would bypass the dedupe and charge again — the fix also needed an application-level guard (checking `invoice.charged_at`) before calling Stripe.
    - The 02:00 clustering of duplicates looked like a DST/timezone bug at first, but the cron schedule was fine and ran exactly once — the real cause was task redelivery, not scheduling.
  - **Sparks**
    - Are there other `acks_late` Celery tasks in this codebase that call non-idempotent external APIs (payments, email, provisioning) without a similar application-level guard?
    - Could `charge_invoice` be split or given a longer soft time limit so it rarely exceeds it in the first place, rather than relying entirely on idempotency after the fact?
```

`★ Insight ─────────────────────────────────────`
The interesting bug this note captures — `acks_late=True` plus a soft time limit — is a classic at-least-once delivery trap: Celery's "acknowledge after completion" mode exists precisely so a crashed worker doesn't silently drop work, but it means *any* task that runs slow (not just crashes) looks indistinguishable from a lost task to the broker. That's why the fix needed two layers: an idempotency key handles the broker-level redelivery, and the `charged_at` check handles the case Stripe's own dedupe window can't cover (the 24h key expiry). Neither alone is sufficient — a good pattern to recognize in any `acks_late` + external-side-effect combination.
`─────────────────────────────────────────────────`

Nothing was written — this was a dry run only. Let me know if you want me to actually write it (and to which page: `Acme Billing` as shown, or something else).
````

**Attempt 2** — read `evals/results.md` and answered by comparing against Run 1 instead of
composing a note:

````
This live run reproduces `evals/results.md` Run 1 (scored 8/8) almost verbatim — same composed note, same page-mismatch flag, same `suggest_links` degradation. That's a good consistency signal: the skill behaves the same way when run for real in this session as it did in the recorded eval, with today's daily note confirmed genuinely empty (not a canned assumption) and `suggest_links`'s failure confirmed live rather than assumed.
````


## Live write (Task 10 step 4) — 2026-08-30

From `/tmp/roam-notes-live-test` (fresh git repo, plugin installed, `--dangerously-skip-permissions` to mirror real usage):

- Relay line: `Noted to Roam: [[Roam Notes Live Test]], 2026-08-30 — 2 learnings, 1 spark.` plus the derived-page override hint, exactly per SKILL.md step 4.
- Read back via `get_page` on the daily note: entry block `KPdyd6wfk` under a new top-level `Claude Code` section (`VyNTCIejU`), anchor within the two-short-sentences rule, 2 full-sentence learnings, 1 question-form spark, `#claude-notes` tag present.
- Cleanup verified: deleted section block `VyNTCIejU` (whole tree) and the link-created page `Roam Notes Live Test` (`0mbogn067`, empty, 0 refs); daily note restored to its prior (empty) state.


## v0.2.0 re-run — revision pass added to the skill (2026-08-31)

The skill gained a mandatory "Revise before dispatching" step (distilled from the
technical-writer method: audit each line against binary checks before emitting), after the
user observed that invoking a revision skill on top of 0.1.0 improved note quality. All
three fixtures re-run against the working tree (installed 0.1.0 disabled, `--plugin-dir`):

| Run | Score | Learnings | Notes |
|---|---|---|---|
| debugging-session | 8/8 | 4 | red-herring framed as ruled-out cause, per template |
| feature-build | 8/8 | 3 | file/test counts correctly excluded |
| config-session | 8/8 | 4 | commands appear as referents, not as a step list |

**Measured effect of the revision step:** 11 learnings, avg **28.8 words** (max 38)
vs 0.1.0's 9 learnings, avg **37.4 words** (max 45) — a ~23% tightening at equal
rubric scores. `suggest_links` still errors (`UNKNOWN_ACTION`) on this graph — check 5 remains
vacuous. Page derivation still follows the resolver (cwd), with the narrative project named in
the anchor; both runs flag the mismatch unprompted, which is the designed behaviour for
narrative≠cwd eval conditions.

### Transcripts (verbatim, graph name scrubbed)

```
===== RUN: debugging-session =====
Dry-run preview came back — no write performed. Here's what it would look like:

**Would append** under a new "Claude Code" section on today's daily note (`August 31st, 2026`) in Roam.

```
- **[[Claude Plugins]]** — acme-billing is a Django + Celery invoicing service; this session tracked down why the nightly invoice job double-charged about 3% of customers. #claude-notes
  - **Learnings**
    - The double charge came from Celery's `acks_late=True` combined with a 30-second soft time limit: when `charge_invoice` ran long, the broker treated it as failed and redelivered it, so it re-ran and charged again about 31 seconds later.
    - `stripe.Charge.create` was called without an idempotency key, so the redelivered task had nothing stopping it from charging Stripe a second time.
    - Stripe idempotency keys expire after 24 hours, so relying on the key alone would still double-charge on a retry the following night — the fix also checks `invoice.charged_at` before calling Stripe.
    - The initial suspicion of a DST/timezone bug in the 02:00 cron schedule was a red herring; the cron fired exactly once and the duplication came from task-level redelivery, not scheduling.
  - **Sparks**
    - Are there other Celery tasks in this codebase with `acks_late=True` and an external side effect (charges, emails, notifications) that still lack idempotency protection?
    - Should `charge_invoice`'s soft time limit be raised, or the task split, so a normal run never gets close to the redelivery threshold?
```

Two things worth your attention before a real write:

1. **Page mismatch, confirmed real** — the resolver still filed this under `[[Claude Plugins]]` (this session's repo), not `[[acme-billing]]` (what the content is actually about). If you run this for real, tell me the project explicitly or set up an override so it lands on the right page.
2. **`suggest_links` is broken** on this graph — it returned `UNKNOWN_ACTION: data.ai.suggestLinks`, so zero link suggestions were possible (not zero found — the feature errored). Worth knowing if you rely on auto-linking elsewhere.

No files or Roam state were touched — purely a preview, as requested.

===== RUN: feature-build =====
Dry run complete — nothing was written to Roam. Preview of what *would* be appended to today's daily note (`August 31st, 2026`), under a new `Claude Code` section:

```
- **[[Claude Plugins]]** — trail-maps is a Next.js 15 / Mapbox GL app for hikers; this session added offline caching of map tiles so a downloaded region stays viewable without signal. #claude-notes
  - **Learnings**
    - Next.js App Router doesn't register a service worker for you — it must be registered via `navigator.serviceWorker.register` from a client component after mount, or it never installs in production builds.
    - On iPhone, Safari caps Cache Storage at roughly 50MB per origin, which silently stopped tile caching from growing until LRU eviction keyed by last access was added.
    - Mapbox tile URLs carry the `access_token` query parameter, so caching by full URL was persisting the token in on-device Cache Storage; stripping the query string from the cache key and re-appending the token on fetch closed that leak.
  - **Sparks**
    - How should region-size estimates account for the ~50MB Safari Cache Storage ceiling when telling users how much they can download?
    - Are other secrets riding along in query strings elsewhere in the app, at risk of the same on-device persistence leak?
```

Two things worth noting:
- Page title is **"Claude Plugins"** (derived from this repo, not "trail-maps") — as flagged earlier, since your session summary is about a different project, you'd want an override so future notes land on the right page.
- `suggest_links` errored server-side on this graph (`UNKNOWN_ACTION`), so no auto-linking was attempted — unrelated to the dry-run itself.

===== RUN: config-session =====
Dry-run preview (nothing written to Roam):

> - **[[Claude Plugins]]** — home-lab is a Raspberry Pi behind Tailscale (no git repo). Today's session turned it into a Tailscale exit node so phones can route traffic through home. #claude-notes
>   - **Learnings**
>     - `tailscale up --advertise-exit-node` succeeds silently and shows the node as up, but routes no traffic until an admin approves the exit node in the Tailscale admin console's machine route settings.
>     - Even after admin approval, exit-node routing stayed broken until IP forwarding was turned on with `sysctl -w net.ipv4.ip_forward=1`.
>     - The `ip_forward` sysctl resets on every reboot, so it has to be persisted in `/etc/sysctl.d/99-tailscale.conf` or the exit node stops routing again after a restart.
>     - Initial exit-node throughput was poor despite an idle CPU; the real bottleneck was the SD card being hammered by logging and swap, fixed by moving swap off the SD card.
>   - **Sparks**
>     - Are there other Tailscale features (like subnet routers) that silently no-op pending admin approval, worth checking for on this same Pi?
>     - Now that swap is off the SD card, would moving logs to tmpfs or an external drive squeeze out more throughput, or was the SD card contention the whole story?

Would land under **Claude Code** on today's daily note (2026-08-31) in graph `<graph>`. Two things to flag before a real write:

- **Page mismatch**: it's filed under `[[Claude Plugins]]` because the resolver derived that from this repo's directory — the content is about a separate home-lab project with no repo of its own. Worth an override (or just editing the page link) before writing for real.
- **No auto-links applied**: `suggest_links` errored on the roam-mcp server side (`UNKNOWN_ACTION`), so link suggestions weren't available this run — not a content issue, just a tool gap.
```
