# KAN-5 — TASK-004 — Request specs for the API namespace

Status: implemented

## Requirements

- REQ-002, REQ-003, REQ-004, REQ-006, REQ-007, REQ-008, REQ-009

## Acceptance Criteria

- AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007

## Implementation Notes

- Added `spec/requests/api/v1/health_spec.rb` (type `:request`, `before { host! "example.test" }`) — 4 examples: HTTP 200; `response.media_type` == `application/json`; `JSON.parse(response.body)` == `{ "status" => "ok" }`; success without authentication. Mirrors the existing `spec/requests/health_spec.rb` pattern (Rails 8.1 host authorization rejects `www.example.com`).
- Added `spec/requests/api/v1/endpoints_spec.rb` (type `:request`, same `host!`) — 5 examples: 200 + JSON CT; body equals `[{"method"=>"GET","path"=>"/api/v1/health"},{"method"=>"GET","path"=>"/api/v1/endpoints"}]` (self-inclusive); no-auth; plus root `/up` (200) and `/health` (200 + `{"status":"ok"}`) regression examples for REQ-009/AC-007.
- Added `spec/units/api/v1/endpoint_listing_spec.rb` — 7 unit examples of the `EndpointListing` extraction logic with synthetic route doubles (suffix stripping, non-namespace exclusion, dynamic `/api/v1/ping` inclusion for AC-006, deterministic sort + tie-break, Regexp verbs, empty set).

## Tests

- `spec/requests/api/v1/health_spec.rb` (4), `spec/requests/api/v1/endpoints_spec.rb` (5), `spec/units/api/v1/endpoint_listing_spec.rb` (7) — 16 examples total, all green in the container.
- Angular strategy for AC-006: unit-level synthetic-route verification (the plan's preferred approach); no in-spec route-table mutation was attempted (harness-fragile per Risks).

## Verification

- `bin/rubocop` (host): 16 offenses initially (missing final newlines, bracket spacing) — autocorrected with `bin/rubocop -A`; rerun confirms `35 files inspected, no offenses`.
- In container: `bin/rails db:test:prepare` aborts with the pre-existing "db/schema.rb doesn't exist" error (documented in plan Risks — out of scope); after that the pre-existing empty `randevu_test` serves the request specs. `bin/rspec spec/requests/api/v1/ spec/units/api/v1/` → 16 examples, 0 failures. Full `bin/rspec` → 21 examples, 0 failures (smoke + root health regressions stay green).
- Manual curl against the running dev app (`localhost:3000`): `/api/v1/health` → 200 `{"status":"ok"}` (application/json); `/api/v1/endpoints` → 200 two-entry listing; `/up` → 200; `/health` → 200 `{"status":"ok"}`.

## Blockers / Notes for Human

- none — all green. (Same pre-existing `db:test:prepare`/CI condition from KAN-4 remains, out of scope for KAN-5; a follow-up decision would be needed to generate `db/schema.rb`.)