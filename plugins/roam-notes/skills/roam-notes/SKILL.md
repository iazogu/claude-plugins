---
name: roam-notes
description: Capture memory-trigger learnings from the current work to today's Roam daily note. Use when the user says "note this", "capture learnings", "write this up to Roam", or runs /roam-notes; and whenever a hook message says "Invoke the roam-notes skill now". Writes learnings and sparks only — never a work log.
---

# roam-notes

Write a short entry that, read cold weeks from now, snaps this project's context back
and sparks an idea. The shape and a worked example are in `template.md` (read it now).

## Steps

1. **Resolve the target.** Run `bash "<this skill's base directory>/scripts/resolve.sh"`
   from the session's working directory (the base directory was announced when this
   skill loaded). Keep the JSON it prints.
2. **Compose the hand-off** from what happened in this session:
   - **anchor** — one line, at most two short full sentences: what the project *is*,
     then what this session was about, written for someone who has forgotten the
     project entirely.
   - **learnings** — at most 5. Each must pass: *would I have to re-discover this if I
     forgot it?* Each is one complete sentence with its concrete example inside it.
     Non-obvious facts only: causes, quirks, constraints, things that cost time.
   - **sparks** — at most 2 questions or possibilities the learnings open up. Never
     imperatives, never tasks. May be empty.
   If no learning passes the test, say **"nothing worth noting this time"** and stop.
3. **Dispatch the agent** `roam-notes:note-companion` with this exact block followed by
   the resolver JSON:
   ```
   project: <page from resolver>     graph: <graph from resolver, or auto if null>
   section: <section>                tag: <tag>
   dry_run: false
   anchor: <sentence>
   learnings:
     - <sentence>
   sparks:
     - <sentence>
   ```
   Set `dry_run: true` only when the user asked for a dry run or preview.
4. **Relay one line** from the agent's report and carry on with the session's work:
   `Noted to Roam: [[<page>]], <date> — <n> learnings, <m> sparks.` If the report says
   `already noted`, `outbox: <path>`, or an error, relay that instead — including the
   config path when several graphs are configured. If `pageSource` was `derived`,
   mention the page title so the user can add an override if it is wrong.

## Do not

- Do not write a task list, a file list, a timeline, or decisions already visible in
  the code.
- Do not exceed the caps to "be complete" — cut, do not summarise.
- Do not stop the session's work to do this; it is a side task.
