# KAN-4 — Add application health check endpoint

# Implementation Plan

## Plan Status

**Status:** DRAFT

**Approval:** Pending human approval

**Approved By:** —

**Approved At:** —

## Source

- Jira Issue: [KAN-4](https://randevu.atlassian.net/browse/KAN-4)
- Jira Status: To Do (status category: new), issue type Story, priority Medium, labels `backend`, `spec-driven`
- Specification Snapshot: `ca05cae2e50e62cff20ded1a79585fea6d4208a4dfb60d4a3a1d897fdcc33af9` (SHA-256 over the normalized specification text — summary, requirements, acceptance criteria, constraints, out-of-scope, testing requirements — extracted from the Jira description on 2026-09-19)
- Planned At: 2026-09-19T13:33:29Z

> If the Jira issue KAN-4 materially changes after this snapshot, this plan is stale and must be re-planned rather than silently adapted.

## 1. Specification

### Summary

Add application health check endpoint.

### Context

The application needs a simple endpoint that can be used by load balancers, monitoring systems, and deployment infrastructure to determine whether the Rails application is running.

### Goal

Provide a lightweight HTTP endpoint that confirms that the application process is running and able to handle requests.

### Requirements

| ID | Requirement |
|---|---|
| REQ-001 | The application shall expose a GET endpoint at `/health`. |
| REQ-002 | A successful health check shall return HTTP status 200. |
| REQ-003 | The response shall be JSON. |
| REQ-004 | The JSON response shall contain a top-level `status` property whose value is `"ok"`. |
| REQ-005 | The endpoint shall not require authentication. |
| REQ-006 | The endpoint shall not access the application's business database records or modify application state. |

### Acceptance Criteria

| ID | Given | When | Then |
|---|---|---|---|
| AC-001 | The Rails application is running | a client sends GET `/health` | the application returns HTTP 200 |
| AC-002 | The Rails application is running | a client sends GET `/health` | the Content-Type response header indicates JSON |
| AC-003 | The Rails application is running | a client sends GET `/health` | the response body contains `{"status": "ok"}` |
| AC-004 | a client is not authenticated | the client sends GET `/health` | the request is still successful with HTTP 200 |
| AC-005 | the health endpoint is called | the request is processed | no application business data is created, modified, or deleted |

### Technical Constraints

- Follow the existing Rails application architecture and conventions.
- Do not introduce a new dependency for this feature.
- Keep the endpoint lightweight.
- Do not implement authentication for this endpoint.
- Do not modify unrelated application behavior.

### Out of Scope

- Detailed dependency health checks.
- Database health monitoring.
- Redis health monitoring.
- External service health checks.
- Authentication or authorization.
- Metrics or tracing changes.
- Deployment configuration changes.

### Testing Requirements

Automated tests shall verify:
- GET `/health` returns HTTP 200.
- The response is JSON.
- The response contains `status: "ok"`.
- The endpoint is accessible without authentication.

### Definition of Done

- All requirements are implemented.
- All acceptance criteria are satisfied.
- Automated tests are added.
- Relevant existing tests continue to pass.
- No unrelated application behavior is changed.
- The implementation is reviewed.
- Validation evidence is available for every acceptance criterion.

---

## 2. Repository Analysis

### Application Architecture

- Bare Rails 8.1.3.1 scaffold (Ruby 3.4.8, PostgreSQL via `pg`, importmap + Turbo/Stimulus, no Node build step, no domain code yet).
- Only two routes exist: `GET /up` (built-in health) and commented-out PWA routes. No controllers beyond `ApplicationController`; no models beyond `ApplicationRecord`.
- `ApplicationController` (`app/controllers/application_controller.rb`) is a plain `ActionController::Base` subclass with `allow_browser versions: :modern` and `stale_when_importmap_changes`. It is the only controller in the app.
- No authentication or authorization mechanism exists anywhere (no auth gems in `Gemfile`, no auth filters in initializers/controllers). Therefore "not requiring authentication" needs no new code — the endpoint is simply unguarded.
- Testing: RSpec 8 (`rspec-rails`), one DB-free smoke spec (`spec/smoke_spec.rb`). `spec/rails_helper.rb` is the standard rspec-rails config: `maintain_test_schema!` active, transactional fixtures on, `fixture_paths` pointing at `spec/fixtures` (directory does not exist yet — no spec currently uses fixtures). No `db/schema.rb` yet (no app migrations).

### Relevant Existing Components

- `config/routes.rb` — the only place routes are declared; existing style: `get "up" => "rails/health#show", as: :rails_health_check`.
- Built-in `Rails::HealthController` (from the `railties` gem, mounted at `/up`): inherits `ActionController::Base` directly (bypassing `ApplicationController`'s browser filter), and for JSON returns `{ "status": "up", "timestamp": ... }`. It does not touch the DB by default. **This is the framework precedent for health endpoints in this app.**
- `ApplicationController` — app base controller; inheriting it would drag in `allow_browser` (see Risks) and `stale_when_importmap_changes`.
- `spec/smoke_spec.rb` — host-runnable, DB-free smoke test proving the suite runs. Remains untouched.
- Dev/test runbook (per `AGENTS.md`): DB-touching/test commands run inside the Docker app container (`docker compose -f randevu-deploy/docker-compose.yml run --rm app ...`); `bin/rails db:test:prepare` is a manual prerequisite for DB-backed specs; GitHub Actions CI already runs `db:test:prepare && bin/rspec` with a Postgres service container. Host can only run DB-free specs.

### Existing Conventions

- Routes declared in `config/routes.rb` using the `get "path" => "controller#action"` style.
- Rails 8 omakase style (`rubocop-rails-omakase`); `bin/rubocop` must pass.
- Health-related, non-browser endpoints should not inherit app-level browser gating — the framework's own `Rails::HealthController` sets the precedent (base `ActionController::Base`, not `ApplicationController`).
- No new dependency allowed for this ticket (constraint) — the feature is implementable with the framework's `render json:`.

### Existing Tests

- `spec/smoke_spec.rb` (DB-free) — only existing spec; must keep passing.
- No request/controller specs exist yet; `spec/requests/` does not exist. `spec/requests/health_spec.rb` will be the first request spec — the first DB-backed spec of the suite, so the documented container/`db:test:prepare` workflow applies (CI already handles it).

---

## 3. Implementation Strategy

Add a dedicated, lightweight, application-owned health endpoint at `/health` that returns `{"status":"ok"}` as JSON. The built-in `/up` endpoint stays untouched (it answers `{"status":"up",...}` — different path, different playload; modifying it would be "unrelated application behavior").

**Where the change lives:**

1. **New controller** `app/controllers/health_controller.rb` with a single action that renders the static JSON payload `{ status: "ok" }` via `render json:`.
   - `render json:` yields HTTP 200, `Content-Type: application/json; charset=utf-8`, and a compact body `{"status":"ok"}` — satisfying REQ-002/003/004 and AC-001/002/003.
   - No model calls, no writes, no DB access — satisfying REQ-006/AC-005 by construction.
   - No authentication guard — satisfying REQ-005/AC-004 (nothing in the app authenticates requests).
   - **Base class (recommended):** inherit `ActionController::Base` directly, mirroring the framework's `Rails::HealthController`, so the endpoint is outside `ApplicationController`'s `allow_browser` gating and `stale_when_importmap_changes`. This matters because some health-check clients send browser-spoofed User-Agents that `allow_browser` (in its `:modern` set) could block with HTTP 406, violating AC-001/AC-004. `allow_browser` does *not* block clients with no UA or non-browser UAs (curl, load balancers), so the risk is limited to spoofed-browser UAs; subclassing `ActionController::Base` eliminates it entirely and matches the framework precedent. If the implementer prefers inheriting `ApplicationController`, the `allow_browser`/`stale_when_importmap_changes` filters must be explicitly skipped for this controller and the decision documented.
   - No error/`rescue_from` handling is required: the action renders a static literal and cannot fail; the spec does not ask for failure behavior.

2. **Route** in `config/routes.rb`: register `GET /health` to the new controller action, following the existing route style (`get "health" => "health#show"`, optionally with an `as:` name). The existing `up` route line remains unchanged.

3. **Tests:** add an RSpec request spec `spec/requests/health_spec.rb` (first request spec; requires the documented container setup: `bin/rails db:test:prepare` in the dev container, or CI's existing Postgres service). Examples assert:
   - `GET /health` → 200 (AC-001, REQ-002)
   - `Content-Type` includes `application/json` (AC-002, REQ-003)
   - `JSON.parse(response.body)` equals `{ "status" => "ok" }` (AC-003, REQ-004)
   - Request with no auth credentials succeeds with 200 and the same body (AC-004, REQ-005)
   - No data written: the endpoint performs no writes; evidence is the static-render design plus a passing spec that never creates records and a body that stays constant across calls (AC-005, REQ-006). A request spec asserting "no record counts changed" is not meaningful for an endpoint that cannot write; the design-level guarantee (no DB access in the action) is the validation evidence, recorded at implementation review.

**Why this fits the architecture:** it is a plain Rails controller + route using only the framework; zero new dependencies (constraint); no configuration, gem, CI, or deployment changes; the framework's own health controller validates the pattern of a non-browser-facing health endpoint.

**What the implementer must NOT do:** touch `/up` / `rails/health#show`, `ApplicationController`, `Gemfile`/`Gemfile.lock`, `config/application.rb`, CI config, deploy config, or any migrations.

---

## 4. Implementation Tasks

### TASK-001 — Implement the `/health` endpoint (controller + route)

**Description**

Add a new application-owned health endpoint at `/health` that responds `200 OK` with JSON body `{"status":"ok"}`, requires no authentication, and performs no database or business-data access. This is a route + one controller action; no new dependency.

**Requirements**

- REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006

**Acceptance Criteria**

- AC-001, AC-002, AC-003, AC-004, AC-005

**Expected Changes**

- Add `app/controllers/health_controller.rb`: single action rendering `render json: { status: "ok" }`; base class `ActionController::Base` recommended (framework precedent), or `ApplicationController` with the browser/importmap filters explicitly skipped and the choice documented.
- Add route `get "health" => "health#show"` (or equivalent `health#<action>` mapping) to `config/routes.rb`, leaving the `up` route line unchanged.
- Run `bin/rubocop` — must pass; then verify manually in the dev container that `curl -i http://localhost:3000/health` returns `200`, `Content-Type: application/json`, body `{"status":"ok"}`. (`curl`/load-balancer UAs are not blocked by `allow_browser`; see Risks.)

### TASK-002 — Add automated request specs

**Description**

Add the first RSpec request spec covering the endpoint behavior defined by the Jira testing requirements.

**Requirements**

- REQ-002, REQ-003, REQ-004, REQ-005 (exercised via AC-001..AC-004)

**Acceptance Criteria**

- AC-001, AC-002, AC-003, AC-004

**Expected Changes**

- Add `spec/requests/health_spec.rb` (type `:request`) with examples asserting: HTTP 200; `Content-Type` JSON; parsed body `{ "status" => "ok" }`; success with no authentication.
- This is the first DB-backed spec — run it per the repo runbook: in the Docker app container, `bin/rails db:test:prepare` then `bin/rspec spec/requests/health_spec.rb` (CI already runs `db:test:prepare && bin/rspec` with Postgres).
- If the rspec-rails harness errors on the missing `spec/fixtures` directory (currently referenced by `rails_helper.rb` but absent) or on transactional fixtures against the unprepared DB, resolve minimally and document it (e.g., create empty `spec/fixtures/.keep`, or prepare the test DB as documented). Do not redesign the test harness.
- Ensure the existing smoke spec still passes and the full suite is green in the container.

---

## 5. Test Plan

### TEST-001 — Request returns HTTP 200

**Purpose**

Prove `GET /health` succeeds when the app is running.

**Validates**

- REQ-002, AC-001

**Expected Evidence**

- RSpec example: `get "/health"`; `expect(response).to have_http_status(:ok)`.

### TEST-002 — Response Content-Type is JSON

**Purpose**

Prove the endpoint responds with a JSON content type.

**Validates**

- REQ-003, AC-002

**Expected Evidence**

- RSpec example asserts `response.media_type` is `application/json` (or Content-Type header includes `application/json`).

### TEST-003 — Response body contains status: ok

**Purpose**

Prove the payload is `{"status":"ok"}`.

**Validates**

- REQ-004, AC-003

**Expected Evidence**

- RSpec example parses the body: `expect(JSON.parse(response.body)).to eq("status" => "ok")`.
- Note: `render json:` produces the compact body `{"status":"ok"}`; compare parsed JSON, not byte-for-byte whitespace.

### TEST-004 — No authentication required

**Purpose**

Prove an unauthenticated client is served HTTP 200.

**Validates**

- REQ-005, AC-004

**Expected Evidence**

- RSpec example performs `get "/health"` with no credentials and asserts 200 and the expected body (the app has no auth guard, so this passes by design).

### TEST-005 — No business data accessed or modified

**Purpose**

Prove the endpoint does not touch business data or modify application state.

**Validates**

- REQ-006, AC-005

**Expected Evidence**

- Design-level evidence: the action renders a static JSON literal with no model/DB calls; the request spec creates/reads/writes no records and the body is constant across repeated calls. Record this as validation evidence in the implementation review. (A record-count assertion is not meaningful here since the action cannot write; do not add DB-coupled assertions.)

### TEST-006 — Existing suite remains green

**Purpose**

Regression check per Definition of Done.

**Validates**

- Definition of Done ("Relevant existing tests continue to pass", "No unrelated application behavior is changed")

**Expected Evidence**

- `bin/rubocop` passes; `bin/rspec` (in container, after `db:test:prepare`) passes including the smoke spec and the new request spec; `GET /up` behavior unchanged.

---

## 6. Traceability Matrix

| Requirement | Acceptance Criteria | Task | Test |
|---|---|---|---|
| REQ-001 (GET `/health`) | AC-001 | TASK-001 | TEST-001 |
| REQ-002 (HTTP 200) | AC-001 | TASK-001 | TEST-001 |
| REQ-003 (JSON response) | AC-002 | TASK-001 | TEST-002 |
| REQ-004 (`status: "ok"`) | AC-003 | TASK-001 | TEST-003 |
| REQ-005 (no authentication) | AC-004 | TASK-001 | TEST-004 |
| REQ-006 (no business DB access / no state change) | AC-005 | TASK-001 | TEST-005 |
| Definition of Done (existing tests pass, no unrelated changes) | — | TASK-001, TASK-002 | TEST-006 |

---

## 7. Files Expected To Change

- `config/routes.rb` — add the `GET /health` route; the existing `up` line stays as-is.

## 8. Files Expected To Be Added

- `app/controllers/health_controller.rb` — health endpoint action rendering `{ status: "ok" }` as JSON.
- `spec/requests/health_spec.rb` — request specs for AC-001..AC-004 (and design-level evidence for AC-005).
- (Conditional, only if the rspec-rails harness requires it: `spec/fixtures/` directory placeholder — currently referenced by `rails_helper.rb` but absent.)

## 9. Files Explicitly Not Expected To Change

- `app/controllers/application_controller.rb`
- `config/application.rb`, `config/environments/*`, `config/initializers/*`
- `Gemfile`, `Gemfile.lock` (no new dependency — constraint)
- `db/*` (no migrations — endpoint never touches the DB)
- `config/routes.rb`'s existing `up` route line and built-in `Rails::HealthController` behavior
- `spec/smoke_spec.rb`, `spec/spec_helper.rb`, `spec/rails_helper.rb` (unless a minimal documented fixture-dir fix is required)
- `.github/workflows/ci.yml`, `randevu-deploy/*`, `Dockerfile`, `config/deploy.yml`, `.kamal/*` (deployment config out of scope)
- `public/*`, `app/views/*`, `app/javascript/*`, `app/assets/*`

---

## 10. Risks

- **`allow_browser` interaction (medium):** `ApplicationController` runs `allow_browser versions: :modern`, which blocks requests from recognized-but-outdated browser UAs with 406. `curl`/load balancers/agents without a browser UA (or with no UA) are **not** blocked, so the common health-check case is fine. But a health/uptime client that sends a browser-spoofed UA (e.g., an old Chrome UA) would receive 406, violating AC-001/AC-004. Mitigation: inherit `ActionController::Base` for `HealthController` (framework precedent — `Rails::HealthController` does exactly this), or explicitly skip the browser filter if inheriting `ApplicationController`; verify with a curl-like request in the container.
- **First DB-backed spec / test DB (medium):** this feature introduces the suite's first request spec. RSpec/rails_helper are configured with transactional fixtures and `maintain_test_schema!`, and there is no `db/schema.rb` yet (no app migrations). The request spec therefore requires a prepared test DB, which exists only in the Docker container — `bin/rails db:test:prepare` first (documented runbook; CI already performs it). If the harness surfaces fixture-directory or schema issues, a minimal documented fix is acceptable; a larger harness rewrite is out of scope and would need a plan update.
- **Scope creep on `/up` (low):** the built-in `/up` health route also returns JSON but with `{"status":"up",...}` and no DB access guarantee in the spec's terms; it is a different path and payload. The implementer must add a new endpoint rather than repurposing/relocating `/up` — modifying `/up` would violate the "no unrelated behavior" constraint.
- **Exact-body brittleness (low):** AC-003's literal shows spaces (`{  "status": "ok"  }`); `render json:` emits compact JSON (`{"status":"ok"}`). Tests must compare `JSON.parse(response.body)` to a hash, not the raw literal string.
- **Content negotiation (low):** AC-002 requires JSON; `render json:` fixes the Content-Type regardless of `Accept` header, so this holds even for clients sending no `Accept: application/json`.

---

## 11. Ambiguities

- **Failure behavior unspecified:** the spec defines only the success response (200 + `{"status":"ok"}`). No requirement exists for a 500/down payload when the app is unhealthy. The plan deliberately implements only the required success path; no `rescue_from`/error payload is added. If a failure contract is wanted, it must be specified in Jira and the plan re-approved.
- **Action/route naming:** the spec does not name the controller action; `health#show` (or an equally conventional action) is an implementation-level choice left to the Implementer.
- **Base class choice:** inheriting `ActionController::Base` vs `ApplicationController` (with skipped filters) is a documented recommendation, not a hard requirement; either is acceptable if the `allow_browser` interaction above is handled and the choice is recorded.
- **AC-005 validation evidence:** "no business data created/modified/deleted" cannot be asserted by a meaningful record-count test for a static endpoint; evidence is design-level (no DB access in the action) plus review. Recorded as TEST-005 rather than assumed as a literal test.

---

## 12. Planner Verification

- [x] Jira issue KAN-4 retrieved via jira-spec skill; no Jira modification performed
- [x] All requirements (REQ-001..REQ-006) mapped to implementation tasks
- [x] All acceptance criteria (AC-001..AC-005) mapped to tests
- [x] Technical constraints accounted for (no new dependency, lightweight, no auth, no unrelated changes)
- [x] Out-of-scope items explicitly excluded (deps/DB/Redis/external health, auth, metrics, deployment config)
- [x] Existing Rails conventions considered (route style, controller layout, framework health-controller precedent)
- [x] Testing requirements covered (HTTP 200, JSON, `status: "ok"`, no auth)
- [x] No implementation code written
- [x] No Jira changes made; no branch, commit, or push
