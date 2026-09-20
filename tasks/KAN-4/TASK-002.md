# KAN-4 — TASK-002 — Add automated request specs

Status: implemented

## Requirements

- REQ-002 (HTTP 200)
- REQ-003 (JSON response)
- REQ-004 (`status: "ok"`)
- REQ-005 (no authentication)

## Acceptance Criteria

- AC-001 (HTTP 200)
- AC-002 (Content-Type JSON)
- AC-003 (body `{"status":"ok"}`)
- AC-004 (no auth required)

## Implementation Notes

- Added `spec/requests/health_spec.rb` (`type: :request`), the suite's first request
  spec, with examples asserting: HTTP 200; `response.media_type` is
  `application/json`; `JSON.parse(response.body)` equals `{ "status" => "ok" }`;
  success (200 + same body) with no credentials.
- AC-005 / REQ-006 evidence is design-level (static render, no DB access in the
  action) — no record-count assertions, per plan TEST-005.
- **Harness fix (host authorization):** Rails 8.1 test-env `ActionDispatch::HostAuthorization`
  (allowlist: `.localhost`, `.test`, IP literals) rejects the request-spec default
  host `www.example.com` with 403 + HTML error page before routing, failing all
  examples. Fixed minimally in the spec with `before { host! "example.test" }`
  (an allowed `.test` host). No config/environment changes. This was not
  anticipated by the plan (first request spec in the repo) — see IMPLEMENTATION.md.
- **Test-DB note:** `bin/rails db:test:prepare` aborts (exit 1) because
  `db/schema.rb` does not exist (pre-existing repo state — no app migrations).
  It creates `randevu_test` before aborting; the request specs touch no tables and
  run green against that empty DB. CI's `test` job (`db:test:prepare && bin/rspec`)
  will abort identically until a `db/schema.rb` exists (pre-existing; CI config and
  `db/*` are out of this ticket's scope) — see IMPLEMENTATION.md for the human
  decision needed.

## Tests

- `spec/requests/health_spec.rb` (new) — 4 examples.
- Existing `spec/smoke_spec.rb` kept passing.

## Verification

- In container: `bin/rspec spec/requests/health_spec.rb` → 4 examples, 0 failures.
- Full suite in container: `bin/rspec` → 5 examples, 0 failures
  (smoke + health request specs).
- `bin/rubocop`: 28 files inspected, no offenses detected.

## Blockers / Notes for Human

- None blocking this task (suite green in container).
- Needs human/planner decision: `bin/rails db:migrate` (zero migrations → empty
  `db/schema.rb`) would make the documented `db:test:prepare` and the CI `test` job
  work; this changes `db/*`, which the plan lists as not-expected-to-change, so it
  requires a plan amendment/adjustment rather than an implementer change.