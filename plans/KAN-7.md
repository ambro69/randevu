# KAN-7 — Add basic greyscale landing page at the root URL

# Implementation Plan

## Plan Status

**Status:** APPROVED

**Approval:** Approved

**Approved By:** ambro69

**Approved At:** 2026-10-13T18:05:24Z

## Source

- Jira Issue: [KAN-7](https://randevu.atlassian.net/browse/KAN-7)
- Jira Status: To Do (status category: new), issue type Story, priority Medium, labels `frontend`
- Specification Snapshot: `c43702c90aa84aefc6b688878b09ca61f877367cdd4feeabb6754f63f995957c` (SHA-256 over the normalized specification text — summary, context, goal, requirements, acceptance criteria, technical constraints, out-of-scope, technical notes, testing requirements, definition of done — extracted from the Jira description on 2026-10-13)
- Recommended Branch: feature/KAN-7 (created by a human, not by agents; agents work in the current working tree until Phase 4)
- Planned At: 2026-10-13T17:54:29Z

> If the Jira issue KAN-7 materially changes after this snapshot, this plan is stale and must be re-planned rather than silently adapted.

## 1. Specification

### Summary

Add a basic greyscale landing page served at the application root URL (`/`), with a shared header and footer.

### Context

Randevu has no browser-facing UI yet. `config/routes.rb` defines only `/up`, `/health`, and the `/api/v1` JSON namespace; the root route is still commented out (`# root "posts#index"`), and `app/views/` contains only layouts. This ticket establishes the first user-visible page so the app has a real home at `/` for future UI work.

### Goal

Visiting `/` returns an HTML landing page that names the application, states what it does, and renders within a shared header/footer chrome — using only greyscale styling and no new dependencies.

### Requirements

| ID | Requirement |
|---|---|
| REQ-001 | The root URL `/` resolves to a browser-facing `PagesController#home` (subclassing `ApplicationController`). |
| REQ-002 | `GET /` returns HTTP 200 and renders an HTML page using the application layout. |
| REQ-003 | The landing page displays the application name **"Randevu"**. |
| REQ-004 | The landing page displays the description: _"Randevu aggregates your calendars and meetings from connected mail accounts in one place."_ |
| REQ-005 | The shared application layout includes a header containing the application name linked to `/`. |
| REQ-006 | The shared application layout includes a footer containing a simple copyright line for Randevu. |
| REQ-007 | Styling is greyscale only (black/white/grey), implemented as hand-written CSS with no CSS framework or new gem/dependency. |

### Acceptance Criteria

| ID | Given | When | Then |
|---|---|---|---|
| AC-001 | the application is running | an HTTP GET request is made to `/` | the response status is 200 and the body is an HTML page rendered with the application layout |
| AC-002 | the landing page at `/` | it is rendered | it shows the application name "Randevu" and the description "Randevu aggregates your calendars and meetings from connected mail accounts in one place." |
| AC-003 | any browser page rendered with the application layout | it is rendered | a header landmark is present containing the application name "Randevu" linking to `/` |
| AC-004 | any browser page rendered with the application layout | it is rendered | a footer landmark is present containing a copyright line for Randevu |
| AC-005 | the landing page and its stylesheet | styles are applied | only greyscale values are used and no CSS framework/new dependency has been added (Gemfile/Bundle/importmap unchanged) |
| AC-006 | the application's route table | the root route is inspected | `/` maps to `pages#home` (i.e. `root_path` resolves to the landing page) |

### Technical Constraints

- Use `ApplicationController` for the landing page (browser-facing; it carries `allow_browser versions: :modern`). Do **not** subclass `ActionController::Base` — that precedent is for API/health JSON endpoints only.
- Use the existing ERB + application layout (`app/views/layouts/application.html.erb`).
- Propshaft asset pipeline; put CSS in `app/assets/stylesheets/application.css` (or an additional file picked up by the manifest). No Tailwind, no Node build step, no new gem.
- Leave all existing routes/controllers (`health`, `api/v1`) and JSON behavior unchanged.
- Keep markup semantic (`header`, `main`, `footer`) and responsive-friendly by default.

### Out of Scope

- Colors, theming, dark mode, logos/brand imagery, typography systems.
- Navigation links to other pages, sign-up/login, or any real functionality.
- JavaScript/Stimulus behavior.
- Any content beyond the app name and the one-line description.
- Email/calendar integrations or any domain models.
- Changes to `/health`, `/up`, or `/api/v1`.

### Technical Notes (from Jira)

- `config/routes.rb` line 27 currently holds the commented root; define `root "pages#home"` and add a `PagesController`.
- The layout currently has a bare `yield`; add the header/footer chrome there so future browser pages inherit it.
- `stylesheet_link_tag :app` already includes all stylesheets, so a new file needs no manifest change beyond being present.
- No DB, auth, or migrations are involved.

### Testing Requirements (from Jira)

- Add `spec/requests/pages_spec.rb` with explicit `type: :request` and `before { host! "example.test" }` (per repo RSpec conventions), asserting: 200 status; app name and description present; header/footer landmarks present.
- Run the suite in the Docker app container: `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rspec`.
- `bin/rubocop` clean on host.

### Definition of Done (from Jira)

- All requirements implemented
- All acceptance criteria satisfied
- Automated tests added/updated
- Existing tests pass
- No unrelated changes
- Code reviewed

---

## 2. Repository Analysis

### Application Architecture

- Rails 8.1.3.1 / Ruby 3.4.8 app, module `Randevu::Application`, PostgreSQL, Propshaft + importmap + Turbo/Stimulus (no Node build step).
- Two controller base classes are in use:
  - `ApplicationController < ActionController::Base` — the browser-facing base, carrying `allow_browser versions: :modern` and `stale_when_importmap_changes` (`app/controllers/application_controller.rb`).
  - Direct `ActionController::Base` subclasses — used deliberately for non-browser JSON endpoints (`HealthController`, `Api::V1::BaseController`) so browser-gating filters never apply to API clients.
- `config/routes.rb` currently defines `GET /up`, `GET /health`, and the `namespace :api { namespace :v1 { ... } }`. The root route is commented out (line 27), so there is currently **no** `/` route.
- `app/views/` contains only `layouts/` and `pwa/`; there are no page view directories or `PagesController` yet.
- `app/assets/stylesheets/application.css` exists but is only the Propshaft manifest comment banner — no rules yet.

### Relevant Existing Components

- `app/controllers/application_controller.rb` — base class the new browser controller must inherit from (RW1 constraint).
- `app/views/layouts/application.html.erb` — shared HTML layout; currently body is a bare `<%= yield %>`. Header/footer chrome (REQ-005/REQ-006) belongs here. It already includes `<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>` and `javascript_importmap_tags`, and a `<title>` defaulting to "Randevu".
- `app/assets/stylesheets/application.css` — existing hand-written stylesheet target for greyscale CSS (REQ-007).
- `config/routes.rb` — where the root route must be defined.
- `app/views/layouts/mailer.html.erb` / `mailer.text.erb` — mailer layouts, unrelated (must not be touched).
- No models, DB migrations, jobs, or authentication exist; none are involved.

### Existing Conventions

- Browser-facing controllers inherit `ApplicationController`; JSON/API controllers inherit `ActionController::Base` directly. KAN-7 is browser-facing, so `PagesController < ApplicationController`.
- ERB views live under `app/views/<controller>/<action>.html.erb`; layouts under `app/views/layouts/`.
- Propshaft: `stylesheet_link_tag :app` bulk-includes every `*.css` under `app/assets/**` (confirmed in propshaft 1.3.2 `lib/propshaft/helper.rb`, `:app` / `:all` bulk-inclusion options), so CSS added to the existing `application.css` — or an additional stylesheet file — is picked up with no manifest edit.
- Semantic HTML and CSS-first styling; no CSS framework and no Node toolchain exist in the app.

### Existing Tests

- `spec/requests/health_spec.rb`, `spec/requests/api/v1/health_spec.rb`, `spec/requests/api/v1/endpoints_spec.rb` — request-spec pattern: `require "rails_helper"`, `RSpec.describe "…", type: :request`, `before { host! "example.test" }` (required because Rails 8.1 test host authorization 403s the default `www.example.com`).
- `spec/units/api/v1/endpoint_listing_spec.rb` — plain-Ruby unit spec pattern (non-default `spec/units/`).
- `spec/smoke_spec.rb` — DB-free smoke test; suite currently passes (21 examples). Note: `bin/rails db:test:prepare` exits 1 because no `db/schema.rb` exists yet; this is a known, pre-existing condition and is not a test failure.
- `spec/rails_helper.rb` enables `maintain_test_schema!`; spec-type inference from file location is OFF, so `type: :request` must be declared explicitly (matches Jira testing requirement).

---

## 3. Implementation Strategy

This is a small, low-risk, additive feature. Keep the change minimal and consistent with existing conventions.

1. **Route (AC-006 / REQ-001).** Define the root route in `config/routes.rb` in place of the existing commented `# root "posts#index"` line, mapping `root "pages#home"`. This makes `root_path` resolve to the landing page and leaves `/up`, `/health`, and `/api/v1` untouched.

2. **Controller (REQ-001).** Add `app/controllers/pages_controller.rb` defining `PagesController < ApplicationController` with a `home` action. Inheriting `ApplicationController` (not `ActionController::Base`) is required by the ticket so the page is browser-facing and gets the browser-gating behavior. No explicit `render` is needed — Rails' implicit-render convention serves `app/views/pages/home.html.erb`.

3. **Landing view (REQ-002/REQ-003/REQ-004).** Add `app/views/pages/home.html.erb`. It must send the app name "Randevu" and the exact description "Randevu aggregates your calendars and meetings from connected mail accounts in one place." Wrap the content in a semantic `<main>` (the layout will provide `<header>`/`<footer>`). No other content (out of scope).

4. **Shared chrome (REQ-005 / REQ-006).** Extend `app/views/layouts/application.html.erb` so `<body>` renders a semantic `<header>` containing the app name "Randevu" linked to `root_path` (`/`), then `<%= yield %>`, then a semantic `<footer>` containing a simple Randevu copyright line. Placing this in the shared layout means future browser pages inherit it. Do not alter the mailer layouts, `<head>`, asset tags, or PWA comments.

5. **Greyscale CSS (REQ-007 / AC-005).** Add hand-written styles to the existing `app/assets/stylesheets/application.css` (the simplest, guaranteed-included location) using only greyscale values (black/white/grey hex/rgb/named values) and responsive-friendly, simple layout (max-width container, spacing, borders, muted text). No CSS framework, no new gem, no dependency, no Node step. A separate stylesheet file would also be fine because `stylesheet_link_tag :app` bulk-includes app CSS, but adding to the existing file avoids any doubt and keeps the diff small.

6. **Tests (Testing Requirements).** Add `spec/requests/pages_spec.rb` following the repo request-spec pattern, plus a small non-DB check for the greyscale/no-framework constraint. Run the suite in Docker and `bin/rubocop` on host.

No existing behavior changes: the new route is purely additive, the layout gains chrome that no other browser page currently renders (there are none), and API/health controllers and routes are untouched.

---

## 4. Implementation Tasks

### TASK-001 — Add the root route and `PagesController#home`

**Description**

Replace the commented root route in `config/routes.rb` with `root "pages#home"`. Add `app/controllers/pages_controller.rb` defining `PagesController < ApplicationController` with a `home` action that implicitly renders the landing view. Do not modify any other routes.

**Requirements**

- REQ-001
- REQ-002 (routing half)
- Technical Constraint: browser-facing controllers inherit `ApplicationController`; API/health controllers keep `ActionController::Base`.

**Acceptance Criteria**

- AC-001
- AC-006

**Expected Changes**

- `config/routes.rb` — define `root "pages#home"`.
- `app/controllers/pages_controller.rb` (new) — `PagesController < ApplicationController`, `def home`.

---

### TASK-002 — Add the landing view

**Description**

Add `app/views/pages/home.html.erb` rendering, inside a semantic `<main>`, the application name "Randevu" and the exact one-line description from REQ-004. No additional content.

**Requirements**

- REQ-002
- REQ-003
- REQ-004

**Acceptance Criteria**

- AC-001
- AC-002

**Expected Changes**

- `app/views/pages/home.html.erb` (new).

---

### TASK-003 — Add shared header/footer chrome to the application layout

**Description**

Extend `app/views/layouts/application.html.erb` so `<body>` contains a semantic `<header>` with the app name "Randevu" linked to `root_path`, the existing `<%= yield %>`, and a semantic `<footer>` with a simple Randevu copyright line. Keep `<head>`, asset tags, meta tags, and PWA comments unchanged.

**Requirements**

- REQ-005
- REQ-006
- Technical Constraint: layout must remain the shared application layout used by future browser pages; semantic `header`/`main`/`footer`.

**Acceptance Criteria**

- AC-003
- AC-004

**Expected Changes**

- `app/views/layouts/application.html.erb` — add header/footer chrome around the yield.

---

### TASK-004 — Add greyscale-only stylesheet rules

**Description**

Add hand-written CSS to `app/assets/stylesheets/application.css` providing a minimum viable greyscale presentation for the header, main content, and footer (layout container, spacing, borders, muted grey text). Use only greyscale color values. Add no gem, CSS framework, importmap entry, or build step.

**Requirements**

- REQ-007
- Technical Constraints: Propshaft, hand-written CSS, no new dependency, responsive-friendly.

**Acceptance Criteria**

- AC-005

**Expected Changes**

- `app/assets/stylesheets/application.css` — add greyscale rules (no external dependencies).

---

### TASK-005 — Add request specs for the landing page and layout chrome

**Description**

Add `spec/requests/pages_spec.rb` using `type: :request` and `before { host! "example.test" }`, asserting: `GET /` returns HTTP 200 with an HTML content type; the body contains "Randevu" and the exact description; a `<header>` landmark is present containing "Randevu" linked to `/`; a `<footer>` landmark is present with a copyright line. Also assert the root route resolves to `pages#home` / `root_path`. Add a lightweight non-DB check for the greyscale-only/no-framework constraint (see TEST-006).

**Requirements**

- REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007

**Acceptance Criteria**

- AC-001, AC-002, AC-003, AC-004, AC-005, AC-006

**Expected Changes**

- `spec/requests/pages_spec.rb` (new).

---

## 5. Test Plan

### TEST-001 — Root route returns an HTML 200

**Purpose**

Verify `GET /` responds 200 with an HTML content type and is rendered with the application layout (presence of layout chrome such as the `<html>`/`<header>`/`<footer>` structure).

**Validates**

- REQ-002
- AC-001

**Expected Evidence**

Request spec assertion: `get "/"` → `have_http_status(:ok)`, `response.media_type == "text/html"`, and body contains layout markers (e.g. `<body>` and the `header`/`footer` landmarks asserted in TEST-003/004).

---

### TEST-002 — Landing page shows the app name and description

**Purpose**

Verify the landing page contains "Randevu" and the exact description text.

**Validates**

- REQ-003
- REQ-004
- AC-002

**Expected Evidence**

Request spec asserting `response.body` includes `Randevu` and includes `Randevu aggregates your calendars and meetings from connected mail accounts in one place.`

---

### TEST-003 — Layout header landmark links to `/`

**Purpose**

Verify a `<header>` landmark exists and contains the app name linked to `/`.

**Validates**

- REQ-005
- AC-003

**Expected Evidence**

Request spec asserting the body has a `<header>…</header>` containing "Randevu" and an anchor whose `href` is `/` (or `root_path`).

---

### TEST-004 — Layout footer landmark has a copyright line

**Purpose**

Verify a `<footer>` landmark exists with a Randevu copyright line.

**Validates**

- REQ-006
- AC-004

**Expected Evidence**

Request spec asserting the body has a `<footer>…</footer>` containing a Randevu copyright line (e.g. matches /©|copyright/i and "Randevu").

---

### TEST-005 — Root route maps to `pages#home`

**Purpose**

Verify the route table maps `/` to `pages#home` and `root_path` resolves to the landing page.

**Validates**

- REQ-001
- AC-006

**Expected Evidence**

Spec assertion on the routing table (e.g. `expect(get("/").route... )` or `expect(Rails.application.routes.recognize_path("/", method: :get)).to eq(controller: "pages", action: "home")`), or that `root_path == "/"` and `GET /` reaches `PagesController#home`.

---

### TEST-006 — Greyscale-only styling, no new dependency

**Purpose**

Verify the stylesheet uses only greyscale color values and that no CSS framework/new dependency was added.

**Validates**

- REQ-007
- AC-005

**Expected Evidence**

A non-DB check (plain-Ruby unit spec under `spec/units/` or an assertion in the request/`pages_spec`) that scans `app/assets/stylesheets/application.css` and confirms every color literal is greyscale (R == G == B, or a black/white/grey named color / `transparent`), plus confirmation that `Gemfile`/`Gemfile.lock` and `config/importmap.rb` are unchanged by this ticket. If a fully automated color check proves impractical, document a manual review step against AC-005 (see Ambiguities A-1).

---

### TEST-007 — Existing routes and JSON behavior unchanged (regression)

**Purpose**

Confirm the additive change did not alter `/up`, `/health`, `/api/v1/health`, or `/api/v1/endpoints`.

**Validates**

- Technical Constraint: leave existing routes/controllers and JSON behavior unchanged.
- Out-of-scope exclusion for `/health`, `/up`, `/api/v1`.

**Expected Evidence**

Existing specs (`health_spec.rb`, `api/v1/*`) continue to pass unchanged, plus the full suite green in the Docker container. No new production code recolors the API surface.

---

## 6. Traceability Matrix

| Requirement | Acceptance Criteria | Task | Test |
|---|---|---|---|
| REQ-001 | AC-001, AC-006 | TASK-001 | TEST-005, TEST-001 |
| REQ-002 | AC-001 | TASK-001, TASK-002 | TEST-001 |
| REQ-003 | AC-002 | TASK-002 | TEST-002 |
| REQ-004 | AC-002 | TASK-002 | TEST-002 |
| REQ-005 | AC-003 | TASK-003 | TEST-003 |
| REQ-006 | AC-004 | TASK-003 | TEST-004 |
| REQ-007 | AC-005 | TASK-004 | TEST-006 |
| (constraint) unchanged routes | — | TASK-001 | TEST-007 |

---

## 7. Files Expected To Change

- `config/routes.rb` — define `root "pages#home"`.
- `app/views/layouts/application.html.erb` — add shared `<header>`/`<footer>` chrome.
- `app/assets/stylesheets/application.css` — add greyscale CSS rules.

## 8. Files Expected To Be Added

- `app/controllers/pages_controller.rb` — `PagesController < ApplicationController`.
- `app/views/pages/home.html.erb` — landing page content.
- `spec/requests/pages_spec.rb` — request specs.
- (optionally) `spec/units/pages/…` — non-DB greyscale/no-framework check, if not folded into `pages_spec.rb`.

## 9. Files Explicitly Not Expected To Change

- `Gemfile`, `Gemfile.lock`, `config/importmap.rb`, `app/javascript/**` — no new dependency (AC-005).
- `app/controllers/application_controller.rb` — base class reused as-is.
- `app/controllers/health_controller.rb`, `app/controllers/api/v1/base_controller.rb`, `app/controllers/api/v1/health_controller.rb`, `app/controllers/api/v1/endpoints_controller.rb`, `app/controllers/api/v1/endpoint_listing.rb` — JSON/API behavior unchanged.
- `app/views/layouts/mailer.html.erb`, `app/views/layouts/mailer.text.erb`, `app/views/pwa/**` — unrelated.
- `spec/requests/health_spec.rb`, `spec/requests/api/v1/**`, `spec/units/**`, `spec/smoke_spec.rb`, `spec/rails_helper.rb`, `spec/spec_helper.rb` — existing tests unchanged (regression evidence).
- `config/database.yml`, `db/**`, `config/deploy.yml`, `Dockerfile*`, `randevu-deploy/**` — no DB/infra changes.
- `ARCHITECTURE.md`, `.opencode/**`, `opencode.json`, `plans/**` — out of implementer scope.

---

## 10. Risks

- **Host-authorization in request specs.** New request specs must set `before { host! "example.test" }`, or they will fail with 403 before routing. (Established convention; low risk if followed.)
- **Rendering `GET /` triggers `allow_browser versions: :modern`.** `ApplicationController` gates on a modern User-Agent. Request specs without a modern UA could be rejected. Mitigation: rely on the default RSpec request UA (as existing specs do) or set an explicit modern UA; confirm during implementation. *Note: existing JSON specs bypass this by using `ActionController::Base`; this is the first browser-facing controller, so it is worth an explicit check.*
- **AC-005 is hard to prove fully automatically.** "Only greyscale values" and "no new dependency" are largely static properties. Mitigation: scan the stylesheet for greyscale-only color literals and confirm no dependency/manifest changes; fall back to documented manual review if automated checking is brittle.
- **Diff scope creep.** It is tempting to add navigation/branding while building the layout. All of that is out of scope; keep the layout chrome minimal.
- **`db:test:prepare` pre-existing failure.** Unrelated to this ticket; do not treat it as a regression or attempt to fix it here.

---

## 11. Ambiguities

- **A-1 — AC-005 verification method.** The ticket requires greyscale-only styling and no new dependency but does not specify how this is verified (automated assertion vs. human/reviewer check). This plan proposes a lightweight automated stylesheet scan plus a dependency-diff check, with manual review as fallback. This is a verification-method ambiguity, not a behavioral one.
- **A-2 — Exact footer copyright text.** REQ-006/AC-004 require "a simple copyright line for Randevu" without specifying exact wording. The implementer may choose a conventional line (e.g. `© <year> Randevu`). Tests should assert "Randevu" plus a copyright indicator rather than an exact string.
- **A-3 — CSS placement.** The ticket allows either extending `app/assets/stylesheets/application.css` or adding a separate file. This plan defaults to the existing file for a minimal diff; either is acceptable.
- **A-4 — `<title>`.** The layout already sets a default `<title>` of "Randevu". No requirement asks for a page-specific title; none should be added beyond what the layout already provides.

None of these ambiguities block implementation; all have a documented default.

---

## 12. Planner Verification

- [x] All requirements mapped to implementation tasks
- [x] All acceptance criteria mapped to tests
- [x] Technical constraints accounted for
- [x] Out-of-scope items explicitly excluded
- [x] Existing Rails conventions considered
- [x] No implementation code written
- [x] No Jira changes made
