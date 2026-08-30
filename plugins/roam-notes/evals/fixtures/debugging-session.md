Session summary — project: acme-billing (Django + Celery invoicing service)

The user reported that the nightly invoice job double-charged about 3% of customers last
night. I started by checking the cron schedule because the duplicates clustered around
02:00 and the user suspected a DST/timezone bug; the cron was fine and ran once. Next I
pulled the Celery worker logs and saw the `charge_invoice` task executed twice for the
affected invoices, ~31 seconds apart. The task has `acks_late=True`, so when the first run
exceeded the 30 s soft time limit the broker re-delivered it, and the task body calls
`stripe.Charge.create` without an idempotency key, so the second run charged again. I added
an idempotency key derived from the invoice id and confirmed Stripe deduplicates on it —
but Stripe's docs say idempotency keys expire after 24 hours, so a retry the following
night would still double charge; I therefore also made the task check `invoice.charged_at`
before calling Stripe. Touched `billing/tasks.py`, `billing/models.py`, added 3 tests in
`billing/tests/test_charge.py`, all 41 tests pass. Committed as "fix: make charge_invoice
idempotent".

<!-- MUST-INCLUDE:
- acks_late re-delivery after the time limit + non-idempotent charge as the cause
- Stripe idempotency keys expire after 24 hours
-->
<!-- MUST-EXCLUDE:
- the list of files touched or the test count
- a timeline ("first I checked… next I…")
- the timezone red herring presented as a learning rather than as a ruled-out cause
-->
