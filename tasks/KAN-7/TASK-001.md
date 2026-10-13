# KAN-7 — TASK-001 — Add the root route and `PagesController#home`

Status: implemented

## Requirements

- REQ-001
- REQ-002 (routing half)
- Technical Constraint: browser-facing controllers inherit `ApplicationController`; API/health controllers keep `ActionController::Base`.

## Acceptance Criteria

- AC-001
- AC-006

## Implementation Notes

- `config/routes.rb` — replaced the commented `# root "posts#index"` line with `root "pages#home"` (comment updated to describe the landing page). All other routes (`/up`, `/health`, `namespace :api { namespace :v1 { ... } }`, PWA comments) are byte-for-byte unchanged.
- `app/controllers/pages_controller.rb` (new) — `class PagesController < ApplicationController` with an empty `def home`; implicit render serves `app/views/pages/home.html.erb`. Inheriting `ApplicationController` (not `ActionController::Base`) keeps the page browser-facing with the existing `allow_browser versions: :modern` gating, per the plan.

## Tests

- `spec/requests/pages_spec.rb` covers routing (TEST-005) and the rendered response (TEST-001).

## Verification

- `bin/rubocop` — 38 files inspected, no offenses.
- RSpec (Docker container): `spec/requests/pages_spec.rb` 9 examples, 0 failures.

## Blockers / Notes for Human

- none
