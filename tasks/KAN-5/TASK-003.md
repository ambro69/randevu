# KAN-5 — TASK-003 — `/api/v1/endpoints` dynamic listing

Status: implemented

## Requirements

- REQ-005 (GET /api/v1/endpoints)
- REQ-006 (HTTP 200 + JSON Content-Type)
- REQ-007 (lists every /api/v1 route: method + path)
- REQ-008 (dynamic listing from the route table)
- REQ-010 (no DB access / no state change)

## Acceptance Criteria

- AC-004, AC-005, AC-006, AC-008

## Implementation Notes

- Added `app/controllers/api/v1/endpoints_controller.rb` — `Api::V1::EndpointsController < Api::V1::BaseController` with a single `index` action rendering `Api::V1::EndpointListing.call`.
- Added `app/controllers/api/v1/endpoint_listing.rb` — a plain-Ruby helper module (`module_function`) deriving the listing at request time from `Rails.application.routes.routes` (the implementation-level option the plan allowed). Per route: skip unless the path starts with `/api/v1/`, strip the `(.:format)` suffix, extract verb(s) from `route.verb` (plain `String` now; `Regexp` decoded generically against the standard HTTP methods for future multi-verb routes). Emits one `{ "method" => ..., "path" => ... }` entry per route. Sorts by path descending (so the two real routes render `health` before `endpoints`, matching AC-005's pinned order) with a deterministic ascending method tie-break for identical paths.
- Dynamic by construction (REQ-008/AC-006): the listing is derived from the live route table, so any future `/api/v1` route appears with no code change to the listing — verified in the unit spec with an injected `/api/v1/ping`.
- No DB access, no writes — reads only the in-memory route table (REQ-010/AC-008).
- Note: the helper sorts by path *descending* — a deliberate deviation from "sort by path ascending" in the plan's prose, chosen so the output reproduces the order pinned in AC-005/TEST-005 (`health` before `endpoints`) given the actual paths. Behavior is deterministic and unit-tested; see Blockers.

## Tests

- `spec/requests/api/v1/endpoints_spec.rb` — request-level (status, JSON CT, exact listing incl. self, no-auth, root `/up` + `/health` regressions)
- `spec/units/api/v1/endpoint_listing_spec.rb` — unit-level of the extraction logic with synthetic route doubles (filtering, suffix stripping, dynamic `ping` inclusion, deterministic sort, Regexp verbs, empty set) for TEST-005/006

## Verification

- `bin/rubocop` (host): clean after autocorrect (`35 files inspected, no offenses`), then verified again — passes.
- In container: `bin/rspec spec/requests/api/v1/ spec/units/api/v1/` → 16 examples, 0 failures; full `bin/rspec` → 21 examples, 0 failures (includes smoke + root health regressions).
- Manual curl against the running dev app (`localhost:3000`): `/api/v1/endpoints` → 200 `[{"method":"GET","path":"/api/v1/health"},{"method":"GET","path":"/api/v1/endpoints"}]`.

## Blockers / Notes for Human

- Sort order rationale: plan prose says "sorted" with AC-005's example expecting `health` before `endpoints`, which is *descending* for those literal paths. Implemented as path-descending + method-ascending tie-break. If ascending order was actually intended, swap the comparator (and the unit/request expectations) — flagging for review.