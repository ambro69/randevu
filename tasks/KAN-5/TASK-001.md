# KAN-5 — TASK-001 — Namespace routes and shared API base controller

Status: implemented

## Requirements

- REQ-001 (route exposure: GET /api/v1/health)
- REQ-005 (route exposure: GET /api/v1/endpoints)
- REQ-009 (root /up and /health unchanged)

## Acceptance Criteria

- AC-001 (routes exist and are routeable)
- AC-004 (routes exist and are routeable)
- AC-007 (root behavior unchanged)

## Implementation Notes

- Added `namespace :api { namespace :v1 { get "health" => "health#show"; get "endpoints" => "endpoints#index" } }` to `config/routes.rb` (per the Jira technical notes). The existing `up` and `health` route lines are byte-for-byte unchanged (REQ-009/AC-007).
- Added `app/controllers/api/v1/base_controller.rb` — `Api::V1::BaseController < ActionController::Base`, the shared base for all namespaced controllers. Inheriting `ActionController::Base` directly (the KAN-4 `/health` precedent) keeps the namespace outside `ApplicationController`'s `allow_browser`/`stale_when_importmap_changes` gating. No filters, no auth guards.

## Tests

- request specs in TASK-004 (`spec/requests/api/v1/`)

## Verification

- `bin/rubocop` — full run in TASK-004 verification (host); routes confirmed routeable by TASK-004 request specs and `bin/rails runner` route inspection.

## Blockers / Notes for Human

- none