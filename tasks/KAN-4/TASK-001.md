# KAN-4 — TASK-001 — Implement the `/health` endpoint (controller + route)

Status: implemented

## Requirements

- REQ-001 (GET /health)
- REQ-002 (HTTP 200)
- REQ-003 (JSON response)
- REQ-004 (`status: "ok"`)
- REQ-005 (no authentication)
- REQ-006 (no business DB access / no state change)

## Acceptance Criteria

- AC-001 (HTTP 200)
- AC-002 (Content-Type JSON)
- AC-003 (body `{"status":"ok"}`)
- AC-004 (no auth required)
- AC-005 (no business data accessed/modified)

## Implementation Notes

- Added `app/controllers/health_controller.rb` with a single `show` action rendering
  `render json: { status: "ok" }`.
- Base class: `ActionController::Base` (per plan recommendation, mirroring the
  framework's `Rails::HealthController`) — keeps the endpoint outside
  `ApplicationController`'s `allow_browser` gating (which could 406 browser-spoofed
  health-check UAs) and outside `stale_when_importmap_changes`.
- Added route `get "health" => "health#show"` to `config/routes.rb` with a comment;
  the existing `up` route line is untouched.
- No new dependency; no DB/model access in the action (REQ-006 satisfied by design —
  static literal render, nothing can be created/modified/deleted).

## Tests

- Request specs covering this endpoint live in TASK-002 (`spec/requests/health_spec.rb`).

## Verification

- `bin/rubocop`: 28 files inspected, no offenses detected.
- Manual curl against the running dev app (`curl -si http://localhost:3000/health`):
  HTTP 200, `Content-Type: application/json; charset=utf-8`, body `{"status":"ok"}`.
- `curl -si http://localhost:3000/up` unchanged (HTTP 200, existing HTML payload).

## Blockers / Notes for Human

- None for this task.