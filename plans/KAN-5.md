# KAN-5 — Add /api/v1 API namespace with health and endpoint-discovery endpoints

# Implementation Plan

## Plan Status

**Status:** APPROVED

**Approval:** Approved

**Approved By:** ambro69

**Approved At:** 2026-09-20T06:47:04Z

## Source

- Jira Issue: [KAN-5](https://randevu.atlassian.net/browse/KAN-5)
- Jira Status: To Do (status category: new), issue type Story, priority Medium, labels `api`, `backend`, `spec-driven`
- Specification Snapshot: `ecc232bcecfc628544fca31c352d7d8c3058002feab6e3758529d6b1c15ccfc6` (SHA-256 over the normalized specification text — summary, context, goal, requirements, acceptance criteria, technical constraints, out-of-scope, technical notes, testing requirements — extracted from the Jira description on 2026-09-20)
- Recommended Branch: feature/KAN-5 (created by a human, not by agents; agents work in the current working tree until Phase 4)
- Planned At: 2026-09-20T06:39:56Z

> If the Jira issue KAN-5 materially changes after this snapshot, this plan is stale and must be re-planned rather than silently adapted.

## 1. Specification

### Summary

Introduce a versioned API namespace at `/api/v1` with an unauthenticated health check (`/api/v1/health`) and an endpoint-discovery endpoint (`/api/v1/endpoints`) that lists every API endpoint in the namespace (method + path).

### Context

The application currently exposes JSON endpoints flat at the root (`/up`, `/health`). A namespaced, versioned API is being introduced so clients can rely on stable, predictable paths. The first API endpoint is a health check mirroring the established `/health` semantics; an endpoint listing (`/api/v1/endpoints`) gives developers and tooling a self-describing view of what the namespace offers.

### Goal

Provide `/api/v1/health` returning `{"status":"ok"}` and `/api/v1/endpoints` returning the method and path of every API route under `/api/v1` — both unauthenticated, JSON-only, and dynamic.

### Requirements

| ID | Requirement |
|---|---|
| REQ-001 | The application shall expose GET `/api/v1/health`. |
| REQ-002 | GET `/api/v1/health` shall return HTTP 200. |
| REQ-003 | GET `/api/v1/health` shall return JSON body `{"status":"ok"}` (Content-Type `application/json`). |
| REQ-004 | GET `/api/v1/health` shall not require authentication. |
| REQ-005 | The application shall expose GET `/api/v1/endpoints`. |
| REQ-006 | GET `/api/v1/endpoints` shall return HTTP 200 with JSON Content-Type. |
| REQ-007 | GET `/api/v1/endpoints` shall list every route under `/api/v1`, each entry with an HTTP method and a path. |
| REQ-008 | The listing shall be dynamic — derived from the live route table, so future `/api/v1` endpoints appear automatically. |
| REQ-009 | Existing root-level `/up` and `/health` shall remain unchanged. |
| REQ-010 | No namespaced API endpoint shall access the business database or modify application state. |

### Acceptance Criteria

| ID | Given | When | Then |
|---|---|---|---|
| AC-001 | the Rails application is running | a client sends GET `/api/v1/health` | the application returns HTTP 200 |
| AC-002 | the Rails application is running | a client sends GET `/api/v1/health` | the response body is `{"status":"ok"}` with Content-Type `application/json` |
| AC-003 | a client is not authenticated | it sends GET `/api/v1/health` | the request succeeds with HTTP 200 |
| AC-004 | `/api/v1/health` and `/api/v1/endpoints` are defined | a client sends GET `/api/v1/endpoints` | it returns HTTP 200 with JSON Content-Type |
| AC-005 | those two routes exist | a client sends GET `/api/v1/endpoints` | the body lists both with method + path, e.g. `[{"method":"GET","path":"/api/v1/health"},{"method":"GET","path":"/api/v1/endpoints"}]` |
| AC-006 | a new route is later added under `/api/v1` | GET `/api/v1/endpoints` is called | the new route appears without code changes to the listing |
| AC-007 | the new namespace is deployed | the root endpoints are called | `/up` and `/health` behave exactly as before |
| AC-008 | `/api/v1/endpoints` is called | the request is processed | no business data is created, modified, or deleted |

### Technical Constraints

- No new dependency; follow existing Rails conventions.
- API controllers use a shared base API controller inheriting `ActionController::Base` (the `/health` precedent) so browser-gating filters never block non-browser clients; all endpoints remain unauthenticated.
- Listing is derived from `Rails.application.routes`, not a hand-maintained list; one entry per route = method + path, sorted.
- `/up` and `/health` behavior untouched.

### Out of Scope

- Moving, renaming, or deprecating root `/up` and `/health`, or aliasing `/health → /api/v1/health`.
- Authentication/authorization on API endpoints.
- Versioning beyond v1.
- Swagger/OpenAPI generation.
- Response-envelope conventions, caching, rate-limiting.

### Technical Notes (from Jira)

- Routes: `namespace :api { namespace :v1 { get "health" → health#show; get "endpoints" → endpoints#index } }` under `config/routes.rb`.
- New files: `app/controllers/api/v1/base_controller.rb` (inherits `ActionController::Base`), `health_controller.rb`, `endpoints_controller.rb`; spec at `spec/requests/api/v1/`.
- Listing: filter `Rails.application.routes` to paths starting `/api/v1/`, normalize (strip `(.:format)`), extract verb(s), sort by path; includes `/api/v1/endpoints` itself.

### Testing Requirements

Automated tests shall verify:
- GET `/api/v1/health` returns 200 and `{"status":"ok"}`.
- GET `/api/v1/endpoints` returns 200 with `application/json` and lists every `/api/v1` route with method and path.
- Accessible without authentication; `/up` and `/health` unchanged.

### Definition of Done

- All requirements implemented.
- All acceptance criteria satisfied.
- Automated tests added/updated.
- Existing tests pass.
- No unrelated changes.
- Code reviewed.

---

## 2. Repository Analysis

### Application Architecture

- Rails 8.1.3.1 (Ruby 3.4.8, PostgreSQL via `pg`, importmap + Turbo/Stimulus, no Node build step). Bare scaffold plus the KAN-4 health endpoint; still no domain code.
- The KAN-4 implementation is committed and the working tree is clean (on `main`, no uncommitted changes): `app/controllers/health_controller.rb` (`class HealthController < ActionController::Base; def show; render json: { status: "ok" }; end; end`), route `get "health" => "health#show"`, and `spec/requests/health_spec.rb` (4 request examples, all green in the container).
- Current routes in `config/routes.rb`: `get "up" => "rails/health#show", as: :rails_health_check` (built-in) and `get "health" => "health#show"` — both flat at the root.
- `ApplicationController` runs `allow_browser versions: :modern` and `stale_when_importmap_changes`. The `HealthController` deliberately inherits `ActionController::Base` directly (mirroring `Rails::HealthController`), placing health endpoints outside browser gating. The KAN-5 shared API base must follow the same precedent.
- No authentication or authorization mechanism exists (no auth gems, no filters), so "unauthenticated" requires no new code — endpoints are simply unguarded.
- Testing: RSpec 8 (`rspec-rails`), smoke spec + request specs. `spec/rails_helper.rb` uses transactional fixtures, `fixture_paths` → `spec/fixtures` (directory still absent), and `maintain_test_schema!`. No `db/schema.rb` (no app migrations).

### Relevant Existing Components

- `config/routes.rb` — the only route declaration point. Existing style: `get "path" => "controller#action"`. The added namespace block must leave the existing `up` and `health` lines byte-for-byte unchanged (REQ-009/AC-007).
- `app/controllers/health_controller.rb` — the established pattern for an unauthenticated, JSON-rendering, DB-free endpoint inheriting `ActionController::Base` (KAN-4). With `namespace :api`/`:v1`, controllers resolve to `Api::V1::*` and must be added under `app/controllers/api/v1/` (Zeitwerk autoloading).
- `spec/requests/health_spec.rb` — the suite's only request spec. Establishes the required pattern `before { host! "example.test" }`: Rails 8.1 test-environment `ActionDispatch::HostAuthorization` (allowlist `.localhost`, `.test`, IP literals) rejects the request-spec default host `www.example.com` with 403 before routing. New `/api/v1` request specs must replicate this.
- Route-table facts verified in the running dev container (`bin/rails runner`): `Rails.application.routes.routes` currently returns 37 route objects, all with single-verb `String` verbs (no Regexp/multi-verb entries yet); `route.path.spec.to_s` yields e.g. `/api/v1/health(.:format)` (needs the `(.:format)` suffix stripped); the table contains engine routes (`/rails/action_mailbox/...`, `/rails/active_storage/...`) and Turbo routes (`/resume_historical_location`, `/refresh_historical_location`) that must be excluded by filtering on the `/api/v1/` prefix.
- Dev/test runbook (per `AGENTS.md`): DB-touching/test commands run inside the Docker dev container (`docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rails <cmd>`); `bin/rubocop` runs on the host. GitHub Actions CI `test` job runs `bin/rails db:test:prepare && bin/rspec` with a Postgres service container.

### Existing Conventions

- Routes declared in `config/routes.rb` with the `get "path" => "controller#action"` style; `namespace` DSL for namespaced modules.
- Non-browser-facing endpoints do not inherit `ApplicationController`'s browser gating — `Rails::HealthController` and the KAN-4 `HealthController` are the precedents (`ActionController::Base`).
- JSON responses via `render json:` (yields 200, `application/json` Content-Type).
- Request specs declare `type: :request` explicitly (spec type inference is commented out in `rails_helper.rb`).
- No new dependency allowed (constraint); feature is implementable with the framework only.

### Existing Tests

- `spec/smoke_spec.rb` (DB-free) — must keep passing.
- `spec/requests/health_spec.rb` — 4 examples (HTTP 200, JSON media type, body `{ "status" => "ok" }`, no-auth success) against `/health`; uses `host! "example.test"`. Remains untouched (regression evidence for REQ-009/AC-007).
- Known harness condition (observed during KAN-4): `bin/rails db:test:prepare` aborts (exit 1) because `db/schema.rb` does not exist (no app migrations — pre-existing state). The test DB is still created before the abort, and the request specs touch no tables, so they run green in the container against the empty `randevu_test`. CI's `test` job (`db:test:prepare && bin/rspec`) is affected by the same pre-existing condition. Out of scope for KAN-5 (would require changing `db/*`).

---

## 3. Implementation Strategy

Add a versioned `/api/v1` namespace containing an unauthenticated health endpoint (mirroring the established `/health` semantics) and a self-describing endpoint listing derived from the live route table.

**Where the change lives:**

1. **Routes** (`config/routes.rb`): add a `namespace :api { namespace :v1 { ... } }` block declaring `get "health"` → `health#show` and `get "endpoints"` → `endpoints#index`, per the Jira technical notes. With `namespace`, controllers resolve to `Api::V1::*` under `app/controllers/api/v1/`. The existing `up` and `health` lines remain byte-for-byte unchanged (REQ-009/AC-007).

2. **Shared base controller** `app/controllers/api/v1/base_controller.rb`: `Api::V1::BaseController < ActionController::Base` (the `/health` precedent, per the technical constraint), so `allow_browser`/`stale_when_importmap_changes` never gate non-browser API clients. All namespaced controllers inherit it. No authentication guard — nothing in the app authenticates requests (REQ-004/AC-003).

3. **Health endpoint** `app/controllers/api/v1/health_controller.rb`: `Api::V1::HealthController < Api::V1::BaseController` with `show` rendering the static JSON literal `{ status: "ok" }` (`render json:` ⇒ HTTP 200, `application/json`, compact body — REQ-001..003, AC-001..002). No model/DB access, no writes (REQ-010/AC-008 by construction). A dedicated namespaced controller is added rather than reusing the root `HealthController`, keeping the namespace self-contained per the technical notes.

4. **Endpoint listing** `app/controllers/api/v1/endpoints_controller.rb`: `Api::V1::EndpointsController < Api::V1::BaseController` with `index` deriving the listing at request time from `Rails.application.routes.routes`:
   - Filter to route paths starting with `/api/v1/` (excludes `/up`, `/health`, and all engine/Turbo routes verified in the route table);
   - Normalize each path by stripping the `(.:format)` suffix (e.g. `/api/v1/health(.:format)` → `/api/v1/health`);
   - Extract the HTTP verb(s) from `route.verb` (currently a plain `String`, e.g. `"GET"`; handle a `Regexp` generically for future multi-verb routes — match against the standard HTTP methods);
   - Emit one entry per route as `{ "method" => ..., "path" => ... }`, sorted by path (tie-break deterministically, e.g. by method), including `/api/v1/endpoints` itself;
   - `render json:` the array (top-level array — the spec example shows an unwrapped array; response-envelope conventions are explicitly out of scope).
   The logic reads only the in-memory route table — no DB, no writes (REQ-010/AC-008). It may live in the controller; extracting the pure filter/normalize/sort logic into a plain-Ruby helper (no new gem) is acceptable and improves direct unit-testability of the AC-006 dynamic behavior (that route draw-and-reload inside a request spec is fragile — see Risks/Ambiguities). This is an implementation-level choice.

5. **Tests** (request specs under `spec/requests/api/v1/`): cover health (200, JSON body, no auth) and endpoints (200 + JSON CT, exact listing of both routes, dynamic behavior, regressions), replicating the `host! "example.test"` pattern from the existing health spec.

**Why this fits the architecture:** it is the Rails-native `namespace` mechanism plus two plain controllers reusing the established KAN-4 `/health` pattern (base `ActionController::Base`, `render json:`, no auth, no DB). Zero new dependencies; no config, gem, CI, or deployment changes; the existing root endpoints are untouched.

**What the implementer must NOT do:** modify `/up` or `/health` (routes, controller, or specs), `ApplicationController`, `Gemfile`/`Gemfile.lock`, `config/application.rb`, environment configs, CI config, deploy config, or `db/*` (including creating `db/schema.rb` — the pre-existing `db:test:prepare` abort is out of scope and needs a separate decision).

---

## 4. Implementation Tasks

### TASK-001 — Namespace routes and shared API base controller

**Description**

Add the versioned namespace scaffolding: `namespace :api { namespace :v1 { ... } }` in `config/routes.rb` declaring `GET /api/v1/health` → `health#show` and `GET /api/v1/endpoints` → `endpoints#index` (per the Jira technical notes), plus `Api::V1::BaseController` inheriting `ActionController::Base` as the shared base for all namespaced controllers. The existing `up` and `health` route lines stay unchanged.

**Requirements**

- REQ-001, REQ-005 (route exposure), REQ-009 (root endpoints unchanged)

**Acceptance Criteria**

- AC-001, AC-004 (routes exist and routeable), AC-007 (root behavior unchanged)

**Expected Changes**

- Add the `namespace :api / :v1` route block to `config/routes.rb`; do not alter the existing `up` or `health` lines.
- Add `app/controllers/api/v1/base_controller.rb` — `Api::V1::BaseController < ActionController::Base`. No filters, no auth. (If the controller actions require it, nothing beyond the base class is expected here.)
- Run `bin/rubocop` — must pass.

### TASK-002 — `/api/v1/health` endpoint

**Description**

Add `Api::V1::HealthController` with a single `show` action rendering the static JSON literal `{ status: "ok" }`, mirroring the KAN-4 `/health` semantics inside the namespace.

**Requirements**

- REQ-001, REQ-002, REQ-003, REQ-004, REQ-010

**Acceptance Criteria**

- AC-001, AC-002, AC-003, AC-008 (no DB/state access — by construction)

**Expected Changes**

- Add `app/controllers/api/v1/health_controller.rb` inheriting `Api::V1::BaseController`; `show` renders `render json: { status: "ok" }` (HTTP 200, `application/json`, compact body `{"status":"ok"}`).
- No model calls, no writes, no DB access; no authentication guard.

### TASK-003 — `/api/v1/endpoints` dynamic listing

**Description**

Add `Api::V1::EndpointsController` whose `index` action derives the listing at request time from the live route table: every `/api/v1` route as `{ "method" => ..., "path" => ... }`, paths normalized (strip `(.:format)`), sorted by path, including `/api/v1/endpoints` itself. Must behave dynamically — newly added `/api/v1` routes appear without changes to the listing code.

**Requirements**

- REQ-005, REQ-006, REQ-007, REQ-008, REQ-010

**Acceptance Criteria**

- AC-004, AC-005, AC-006, AC-008

**Expected Changes**

- Add `app/controllers/api/v1/endpoints_controller.rb` inheriting `Api::V1::BaseController`; `index` filters `Rails.application.routes.routes` to paths starting with `/api/v1/`, normalizes each path (strip `(.:format)`), extracts verb(s) (`route.verb`; handle `String` and future `Regexp` forms), emits one `{ method, path }` entry per route, sorts by path (deterministic tie-break), renders the array as JSON.
- Optionally extract the filter/normalize/sort logic into a plain-Ruby helper (no new dependency) for direct unit-testability of the dynamic behavior — implementation-level choice.
- No DB access, no writes (reads only the in-memory route table).

### TASK-004 — Request specs for the API namespace

**Description**

Add request specs under `spec/requests/api/v1/` covering both endpoints: health returns 200 with `{"status":"ok"}` JSON and works unauthenticated; endpoints returns 200 with `application/json` and lists every `/api/v1` route with method + path; the listing is dynamic; root `/up` and `/health` regress unchanged. Replicate the `host! "example.test"` pattern from the existing `spec/requests/health_spec.rb` (test-env host authorization rejects `www.example.com`).

**Requirements**

- REQ-002, REQ-003, REQ-004, REQ-006, REQ-007, REQ-008, REQ-009

**Acceptance Criteria**

- AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007

**Expected Changes**

- Add `spec/requests/api/v1/health_spec.rb` (type `:request`): 200; `response.media_type` is `application/json`; `JSON.parse(response.body)` equals `{ "status" => "ok" }`; success with no credentials.
- Add `spec/requests/api/v1/endpoints_spec.rb` (type `:request`): 200 + JSON CT; body equals the expected array `[{"method":"GET","path":"/api/v1/health"},{"method":"GET","path":"/api/v1/endpoints"}]`; dynamic behavior (see TEST-006 strategy); optionally a `/up`-and-`/health`-unchanged regression example.
- Prefer unit-level verification of the sort/filter/extract logic (synthetic route objects) for AC-006; a route draw-and-reload request-spec mutation is acceptable only if proven reliable in the harness (see Risks).
- Run in the dev container per the runbook: `bin/rails db:test:prepare` (note the pre-existing abort — see Risks), then `bin/rspec spec/requests/api/v1/`; full suite and `bin/rubocop` must stay green.

---

## 5. Test Plan

### TEST-001 — `/api/v1/health` returns HTTP 200

**Purpose**

Prove `GET /api/v1/health` succeeds when the app is running.

**Validates**

- REQ-002, AC-001

**Expected Evidence**

- RSpec example: `get "/api/v1/health"`; `expect(response).to have_http_status(:ok)`.

### TEST-002 — `/api/v1/health` returns JSON `{"status":"ok"}`

**Purpose**

Prove the payload and Content-Type match the spec.

**Validates**

- REQ-003, AC-002

**Expected Evidence**

- RSpec example asserts `response.media_type` is `application/json` and `JSON.parse(response.body)` equals `{ "status" => "ok" }`. (Compare parsed JSON, not raw whitespace — `render json:` emits compact body `{"status":"ok"}`.)

### TEST-003 — `/api/v1/health` requires no authentication

**Purpose**

Prove an unauthenticated client is served HTTP 200.

**Validates**

- REQ-004, AC-003

**Expected Evidence**

- RSpec example performs `get "/api/v1/health"` with no credentials and asserts 200 and the expected body (the app has no auth guard; passes by design).

### TEST-004 — `/api/v1/endpoints` returns HTTP 200 with JSON Content-Type

**Purpose**

Prove the discovery endpoint responds successfully with JSON.

**Validates**

- REQ-006, AC-004

**Expected Evidence**

- RSpec example: `get "/api/v1/endpoints"`; asserts HTTP 200 and `response.media_type` `application/json`.

### TEST-005 — `/api/v1/endpoints` lists every `/api/v1` route with method + path

**Purpose**

Prove the body contains one entry per `/api/v1` route, each with an HTTP method and a path.

**Validates**

- REQ-007, AC-005

**Expected Evidence**

- RSpec example parses the body and asserts it equals `[{"method"=>"GET", "path"=>"/api/v1/health"}, {"method"=>"GET", "path"=>"/api/v1/endpoints"}]` (sorted by path, self-inclusive).
- Unit-level checks of the filter/normalize/sort logic with synthetic route objects (e.g., non-`/api/v1` routes excluded, `(.:format)` stripped, sorted deterministically) if the logic is extracted to a helper.

### TEST-006 — Listing is dynamic

**Purpose**

Prove a newly added `/api/v1` route appears without code changes to the listing.

**Validates**

- REQ-008, AC-006

**Expected Evidence**

- Preferred: unit spec of the extraction logic fed a synthetic route set that includes an extra `/api/v1` route (e.g. `/api/v1/ping`) → the listing includes it without touching the listing code. This verifies "derived from the route table, not hardcoded".
- Alternative (stronger, if reliable in the harness): request-spec route mutation — draw a throwaway `/api/v1` route inside the example (`Rails.application.routes.draw` with `disable_clear_and_finalize` as needed), assert it appears in `GET /api/v1/endpoints`, then reload routes (`Rails.application.routes_reloader.reload!`); must not leak routes into other examples. If this proves fragile, fall back to the unit-spec evidence and record it.

### TEST-007 — Root `/up` and `/health` unchanged

**Purpose**

Regression per REQ-009/AC-007 and Definition of Done ("No unrelated changes").

**Validates**

- REQ-009, AC-007

**Expected Evidence**

- Existing `spec/requests/health_spec.rb` remains untouched and green (4 examples).
- One example asserts `get "/up"` still returns 200 (built-in `Rails::HealthController`), and `/health` still returns `{"status":"ok"}` — either as a small regression example in the new spec or design-level evidence recorded at review (routes byte-for-byte unchanged).
- Manual check in the dev container: `curl -si localhost:3000/up` and `curl -si localhost:3000/health` unchanged; `curl -si localhost:3000/api/v1/health` → 200 `{"status":"ok"}`; `curl -si localhost:3000/api/v1/endpoints` → 200 with the two-entry listing.

### TEST-008 — No business data accessed or modified

**Purpose**

Prove the namespaced endpoints do not touch business data or modify application state.

**Validates**

- REQ-010, AC-008

**Expected Evidence**

- Design-level evidence: both actions render from static literals / the in-memory route table only — no model/DB calls, nothing writable. The request specs create/read/write no records and bodies are constant across repeated calls. Record as validation evidence in the implementation review (as for KAN-4 AC-005); no record-count assertions.

### TEST-009 — Existing suite remains green

**Purpose**

Regression per Definition of Done.

**Validates**

- Definition of Done ("Existing tests pass", "No unrelated changes")

**Expected Evidence**

- `bin/rubocop` passes (host).
- In the dev container: `bin/rspec` passes — smoke spec, existing health spec, and the new `/api/v1` specs (after `db:test:prepare`; see Risks for the pre-existing abort).

---

## 6. Traceability Matrix

| Requirement | Acceptance Criteria | Task | Test |
|---|---|---|---|
| REQ-001 (GET `/api/v1/health`) | AC-001 | TASK-001, TASK-002 | TEST-001 |
| REQ-002 (HTTP 200) | AC-001 | TASK-002 | TEST-001 |
| REQ-003 (JSON `{"status":"ok"}`) | AC-002 | TASK-002 | TEST-002 |
| REQ-004 (no authentication) | AC-003 | TASK-002 | TEST-003 |
| REQ-005 (GET `/api/v1/endpoints`) | AC-004 | TASK-001, TASK-003 | TEST-004 |
| REQ-006 (HTTP 200 + JSON CT) | AC-004 | TASK-003 | TEST-004 |
| REQ-007 (lists every `/api/v1` route: method + path) | AC-005 | TASK-003 | TEST-005 |
| REQ-008 (dynamic listing) | AC-006 | TASK-003 | TEST-006 |
| REQ-009 (root `/up`, `/health` unchanged) | AC-007 | TASK-001 (leave untouched), TASK-004 | TEST-007 |
| REQ-010 (no DB access / no state change) | AC-008 | TASK-002, TASK-003 | TEST-008 |
| Definition of Done (existing tests pass, no unrelated changes) | — | all tasks | TEST-009 |

---

## 7. Files Expected To Change

- `config/routes.rb` — add the `namespace :api { namespace :v1 { get "health" → health#show; get "endpoints" → endpoints#index } }` block (per Jira technical notes); the existing `up` and `health` lines remain byte-for-byte unchanged.

## 8. Files Expected To Be Added

- `app/controllers/api/v1/base_controller.rb` — `Api::V1::BaseController < ActionController::Base` (shared namespaced base; no browser gating).
- `app/controllers/api/v1/health_controller.rb` — `show` → `render json: { status: "ok" }`.
- `app/controllers/api/v1/endpoints_controller.rb` — `index` deriving the sorted method+path listing from `Rails.application.routes` filtered to `/api/v1/` (optionally delegating to a plain-Ruby helper for testability).
- `spec/requests/api/v1/health_spec.rb` — request specs (200, JSON body, no-auth).
- `spec/requests/api/v1/endpoints_spec.rb` — request specs (200 + JSON CT, exact listing, dynamic behavior, optional root regressions).
- (Optional, only if the extraction logic is split out: a plain-Ruby helper file, e.g. under `app/...` following Rails autoloading, no new gem.)

## 9. Files Explicitly Not Expected To Change

- `app/controllers/health_controller.rb` (root `/health` — REQ-009).
- `app/controllers/application_controller.rb`.
- Existing route line `get "up" => "rails/health#show", as: :rails_health_check` and built-in `Rails::HealthController` behavior.
- `Gemfile`, `Gemfile.lock` (no new dependency — constraint).
- `db/*` — no migrations, no `db/schema.rb` creation (pre-existing `db:test:prepare` condition is out of scope; a separate decision would be needed to touch this).
- `config/application.rb`, `config/environments/*`, `config/initializers/*`.
- `.github/workflows/ci.yml`, `randevu-deploy/*`, `Dockerfile`, `config/deploy.yml`, `.kamal/*` (deployment config out of scope).
- `spec/smoke_spec.rb`, `spec/requests/health_spec.rb`, `spec/spec_helper.rb`, `spec/rails_helper.rb`.
- `public/*`, `app/views/*`, `app/javascript/*`, `app/assets/*`.

---

## 10. Risks

- **Request-spec host authorization (medium, known):** Rails 8.1 test-env `HostAuthorization` rejects the default host `www.example.com` with 403 before routing. The existing health spec mitigates with `before { host! "example.test" }`; the new `/api/v1` specs must do the same or they will fail on every example despite correct routing. Established pattern already exists in `spec/requests/health_spec.rb`.
- **Verb extraction from live routes (low):** all 37 routes currently have `String` verbs (`"GET"`), verified via `bin/rails runner`. Future multi-verb routes yield a `Regexp` verb. Extract robustly but don't over-engineer; current scope is GET-only.
- **Route table noise (low):** the live table includes engine and Turbo routes (`/rails/action_mailbox/...`, `/rails/active_storage/...`, `/resume_historical_location`, `/refresh_historical_location`); the `/api/v1/` prefix filter excludes all of them. If the filter were omitted, `REQ-007`/`AC-005` would fail.
- **AC-006 verification fragility (medium):** mutating `Rails.application.routes` inside a request spec (draw + reload) can leak routes across examples or leave a corrupted route set; the `disable_clear_and_finalize`/`routes_reloader` mechanics are fiddly. Preferred mitigation: unit-test the extraction logic with a synthetic route set (verifies table-driven behavior without touching the real route table), with the request-level mutation as a stronger optional check only if reliable.
- **Pre-existing `db:test:prepare` abort (medium, pre-existing from KAN-4, out of scope):** no `db/schema.rb` (no app migrations) ⇒ `db:test:prepare` exits 1. Request specs run green in the container against the empty `randevu_test`; CI's `test` job (`db:test:prepare && bin/rspec`) is affected identically. Fixing would change `db/*`, which is explicitly out of scope — needs a separate human/planner decision (e.g. an empty migration to generate `db/schema.rb`), not an implementer change.
- **Sorting/determinism (low):** the constraint says "sorted"; AC-005's example order is alphabetical by path (`health` before `endpoints`). Sort by path with a deterministic tie-break (e.g. method) so the listing is reproducible and the exact-array assertion in TEST-005 is stable.
- **Scope creep on root endpoints (low):** must add a new namespaced pair rather than touching/moving `/up` or `/health`; modifying them violates REQ-009 and the "no unrelated changes" DoD item.
- **Payload format (low):** AC-005 shows a compact single-line JSON array; `render json:` of an array produces exactly that. Tests must compare parsed JSON, not raw formatting.
- **Module naming (low):** `namespace :api`/`:v1` requires controllers at `Api::V1::*` in `app/controllers/api/v1/`; a mismatch between directory, module names, and route DSL breaks routing (Zeitwerk/routes coupling). Follow the Jira technical notes exactly.

---

## 11. Ambiguities

- **AC-006 verification strategy:** the strongest evidence (inject a real route and re-request) is harness-fragile; unit-level verification of the route-table-derived logic with a synthetic route set is the reliable baseline. The plan prefers the unit approach and allows the request-level mutation only if the implementer proves it doesn't leak across examples; either way the evidence must be recorded.
- **Response shape details:** AC-005 shows a top-level JSON array of `{method, path}` objects and response-envelope conventions are out of scope — implemented as a bare array. Shape beyond that (e.g. `HEAD`/`OPTIONS` entries, route `format` requirements) is unspecified; current scope has exactly two GET routes, so extra cases are handled generically but not specially.
- **Tie-break ordering:** "sort by path" is specified; ordering for identical paths with multiple verbs is unspecified. Plan: deterministic tie-break (method) — an implementation-level choice.
- **Controller action naming:** the Jira technical notes specify `health#show` and `endpoints#index`, so this is resolved by the ticket. Where the extraction logic lives (controller method vs. plain-Ruby helper) is left to the implementer.
- **Failure behavior:** like KAN-4, the spec defines only success responses; no error/fallback payloads are specified and none are added.
- **Pre-existing `db:test:prepare`/CI abort:** unresolved from KAN-4 and out of KAN-5 scope. If the human wants it fixed, that is a separate ticket/plan (a zero-migration `db/schema.rb` generation changes `db/*`, which this plan explicitly excludes).

---

## 12. Planner Verification

- [x] Jira issue KAN-5 retrieved via jira-spec skill; no Jira modification performed
- [x] All requirements (REQ-001..REQ-010) mapped to implementation tasks
- [x] All acceptance criteria (AC-001..AC-008) mapped to tests
- [x] Technical constraints accounted for (no new dependency, shared `ActionController::Base` base, route-table-derived sorted listing, root endpoints untouched)
- [x] Out-of-scope items explicitly excluded (root endpoint changes, auth, versioning beyond v1, OpenAPI, envelopes/caching/rate-limiting)
- [x] Existing Rails conventions considered (route DSL style, `namespace` mechanism, KAN-4 `/health` pattern, `host! "example.test"` request-spec pattern)
- [x] Testing requirements covered (health 200 + `{"status":"ok"}`; endpoints 200 + `application/json` + full method/path listing; no-auth; `/up` + `/health` unchanged)
- [x] Live route-table facts verified read-only in the dev container (37 routes, String verbs, `(.:format)` suffix, engine/Turbo noise filtered by `/api/v1/` prefix)
- [x] No implementation code written
- [x] No Jira changes made; no branch, commit, or push
