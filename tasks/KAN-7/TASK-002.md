# KAN-7 — TASK-002 — Add the landing view

Status: implemented

## Requirements

- REQ-002
- REQ-003
- REQ-004

## Acceptance Criteria

- AC-001
- AC-002

## Implementation Notes

- `app/views/pages/home.html.erb` (new) — a semantic `<main class="page">` containing a `<section class="hero">` with `<h1>Randevu</h1>` (REQ-003) and the exact description `Randevu aggregates your calendars and meetings from connected mail accounts in one place.` (REQ-004). No other content, no links, no JS (out-of-scope items excluded).
- The view provides `<main>` itself; the layout (TASK-003) supplies `<header>`/`<footer>` chrome around the yield.

## Tests

- `spec/requests/pages_spec.rb` — "shows the application name" / "shows the one-line description" (TEST-002).

## Verification

- RSpec (Docker container): full suite green (35 examples, 0 failures).

## Blockers / Notes for Human

- none
