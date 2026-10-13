# KAN-7 — TASK-005 — Add request specs for the landing page and layout chrome

Status: implemented

## Requirements

- REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007

## Acceptance Criteria

- AC-001, AC-002, AC-003, AC-004, AC-005, AC-006

## Implementation Notes

- `spec/requests/pages_spec.rb` (new, 9 examples) — follows the repo request-spec convention: `require "rails_helper"`, explicit `type: :request`, `before { host! "example.test" }`. Covers TEST-001 (200 + HTML/media type + layout markers), TEST-002 (app name + exact description), TEST-003 (`<header>` landmark with "Randevu" linked to `/`), TEST-004 (`<footer>` landmark with a copyright line), TEST-005 (route recognises to `pages#home` and `root_path == "/"`), plus a check that `PagesController < ApplicationController`.
- `spec/units/pages/greyscale_stylesheet_spec.rb` (new, 5 examples) — non-DB static check for TEST-006 (AC-005), as permitted by the plan's optional `spec/units/pages/…` location.
- The plan's risk note about `allow_browser versions: :modern` was checked: request specs render `/` successfully without setting an explicit User-Agent, so no UA workaround was needed.

## Tests

- Run in the Docker app container:
  `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rspec`
  Targeted: `… bin/rspec spec/requests/pages_spec.rb spec/units/pages/greyscale_stylesheet_spec.rb`

## Verification

- Targeted: 14 examples, 0 failures.
- Full suite: 35 examples, 0 failures (was 21 before; +14 new).
- TEST-007 regression: existing `spec/requests/health_spec.rb`, `spec/requests/api/v1/*`, `spec/units/api/v1/*`, `spec/smoke_spec.rb` all pass unchanged.

## Blockers / Notes for Human

- none
