# KAN-7 Review

**Jira:** KAN-7 — Add basic greyscale landing page at the root URL
**Reviewer:** Phase 3 Reviewer Agent
**Date:** 2026-10-13T18:16:48Z
**Base commit:** `6797497` (changes reviewed are uncommitted in the working tree)
**Verdict:** Approve

## Summary

The implementation matches the approved plan (`plans/KAN-7.md`, Status APPROVED, Approved By
ambro69, Approved At 2026-10-13T18:05:24Z) and satisfies every requirement (REQ-001..REQ-007) and
acceptance criterion (AC-001..AC-006). The change is small and purely additive: a root route, a
browser-facing `PagesController`, a landing view, shared header/footer chrome in the application
layout, and hand-written greyscale CSS — plus request and unit specs.

The KAN-7 change set is exactly the plan's "Files Expected To Change/Added" and nothing else. I
independently confirmed the evidence: `bin/rubocop` is clean (38 files, no offenses), a live
`GET http://localhost:3000/` returns `HTTP 200` / `text/html; charset=utf-8` with the header, main
name + description, and footer, and `bin/rspec` in the dev container is green (35 examples,
0 failures). No blocking issues.

## Plan Adherence

- **Strategy followed per plan §3.** Root route defined as `root "pages#home"`; `PagesController <
  ApplicationController` with an implicit-render `home` action; landing content in
  `app/views/pages/home.html.erb`; shared `<header>`/`<footer>` chrome added to
  `app/views/layouts/application.html.erb`; greyscale CSS appended to the existing
  `app/assets/stylesheets/application.css`; specs added at the planned paths.
- **Tasks TASK-001..TASK-005 all implemented and traceable** (see Requirement Coverage). Task
  artifacts report `Status: implemented`, and `tasks/KAN-7/IMPLEMENTATION.md` records the
  approval-gate verification and the single Jira write (`To Do → In Progress`).
- **Documented ambiguities resolved with the plan's defaults:** A-1 (AC-005 verified by a static
  stylesheet scan + dependency check), A-2 (footer text `© <year> Randevu. All rights reserved.`,
  asserted loosely), A-3 (CSS added to the existing file for a minimal diff), A-4 (no extra
  `<title>` added — layout default "Randevu" retained).
- **No spec drift.** The KAN-7 Jira description (summary, requirements, acceptance criteria,
  constraints) matches the plan's Section 1 verbatim. The only Jira state change is status
  `To Do → In Progress` (expected implementer transition), not a spec change.

### Plan-accurate details worth calling out

- `config/routes.rb`: the commented `# root "posts#index"` was replaced with `root "pages#home"`;
  `/up`, `/health`, and the `namespace :api { namespace :v1 { ... } }` block are byte-for-byte
  unchanged. The one-line comment above the root route was reworded to describe the landing page —
  within TASK-001 scope, cosmetic only.
- `app/controllers/pages_controller.rb` inherits `ApplicationController` (not
  `ActionController::Base`), satisfying the browser-facing technical constraint.
- `app/views/layouts/application.html.erb`: only `<body>` changed; `<head>`, meta tags, CSRF/CSP
  tags, PWA comments, icon links, and the asset tags (`stylesheet_link_tag :app`,
  `javascript_importmap_tags`) are untouched.
- `app/assets/stylesheets/application.css`: hand-written rules only; greyscale custom-property
  palette (`#111111`, `#333333`, `#555555`, `#cccccc`, `#f2f2f2`, `#ffffff` — all channels equal),
  one `@media (min-width: 40rem)` tweak. No `@import`, no remote asset, no framework.

## Requirement Coverage

| Req | Status | Evidence |
|---|---|---|
| REQ-001 | ✅ | `config/routes.rb` → `root "pages#home"`; `app/controllers/pages_controller.rb` defines `PagesController < ApplicationController` with `home`. |
| REQ-002 | ✅ | Live `GET /` returns 200 / `text/html`; rendered body includes `<!DOCTYPE html>` and application-layout chrome. |
| REQ-003 | ✅ | `app/views/pages/home.html.erb` renders `<h1>Randevu</h1>`. |
| REQ-004 | ✅ | Landing view renders the exact string `Randevu aggregates your calendars and meetings from connected mail accounts in one place.` |
| REQ-005 | ✅ | Layout `<header class="site-header">` → `link_to "Randevu", root_path` (asserts `href == "/"`). |
| REQ-006 | ✅ | Layout `<footer class="site-footer">` → `<p>&copy; <%= Time.current.year %> Randevu. All rights reserved.</p>`. |
| REQ-007 | ✅ | `application.css` uses only greyscale literals; `Gemfile`, `Gemfile.lock`, `config/importmap.rb`, `app/javascript/**` unmodified. |

## Acceptance Criteria Check

| AC | Status | Evidence |
|---|---|---|
| AC-001 | ✅ | `spec/requests/pages_spec.rb` — 200 + `media_type == "text/html"` + `<!DOCTYPE html>`/`<body>`; independently reproduced via live `curl` → `HTTP 200`. |
| AC-002 | ✅ | pages_spec asserts body includes "Randevu" and the exact description. |
| AC-003 | ✅ | pages_spec parses `header` with Nokogiri: contains "Randevu" and an anchor with `href == "/"`. |
| AC-004 | ✅ | pages_spec parses `footer`: contains "Randevu" and matches `/©\|\(c\)\|copyright/i`. |
| AC-005 | ✅ | `spec/units/pages/greyscale_stylesheet_spec.rb` scans hex/`rgb()` literals, named color keywords, and framework markers in the stylesheet/Gemfile/importmap; working tree confirms no dependency/manifest edits. |
| AC-006 | ✅ | pages_spec asserts `recognize_path("/", method: :get) == {controller: "pages", action: "home"}` and `root_path == "/"`. |

## File Scope

**Changed (as planned):**
- `config/routes.rb` — added `root "pages#home"` (comment reworded).
- `app/views/layouts/application.html.erb` — added `<header>`/`<footer>` chrome around the yield.
- `app/assets/stylesheets/application.css` — appended greyscale rules.

**Added (as planned):**
- `app/controllers/pages_controller.rb`
- `app/views/pages/home.html.erb`
- `spec/requests/pages_spec.rb`
- `spec/units/pages/greyscale_stylesheet_spec.rb`

**No changes** to `Gemfile`, `Gemfile.lock`, `config/importmap.rb`, `app/javascript/**`,
`app/controllers/application_controller.rb`, the health/API controllers, mailer layouts,
`app/views/pwa/**`, `db/**`, `Dockerfile*`, `randevu-deploy/**`, or any existing spec — all matching
the plan's §9 "Files Explicitly Not Expected To Change".

**Working-tree changes not attributable to KAN-7 (out of this ticket's scope).**
The working tree also contains: `AGENTS.md`, `ARCHITECTURE.md`, `opencode.json`,
`.opencode/agents/release.md`, `.opencode/commands/jira-release.md`, `release/` (Phase 4 / release
scaffolding), the reviewer permission fix in `.opencode/agents/reviewer.md`, and the
`/jira-approve` fill-in of `plans/KAN-7.md`. `tasks/KAN-7/IMPLEMENTATION.md` documents these as
pre-existing/other-phase and not implementer edits. They are consistent with the Phase 4 completion
described in `ARCHITECTURE.md` and the agent-permission fix supplied with this review run, and they
do not touch the KAN-7 implementation surface. Verified the KAN-7 diff itself is clean.

## Tests

Matches the plan's Test Plan §5:

- **TEST-001** — 200 + HTML media type + layout markers: covered (`pages_spec.rb`).
- **TEST-002** — app name + exact description: covered.
- **TEST-003** — header landmark with app name linked to `/`: covered (Nokogiri).
- **TEST-004** — footer landmark with copyright line: covered.
- **TEST-005** — route recognises to `pages#home` / `root_path == "/"`: covered (plus an
  inheritance assertion).
- **TEST-006** — greyscale-only / no-framework static check: covered by
  `spec/units/pages/greyscale_stylesheet_spec.rb` (5 examples) at the plan's optional
  `spec/units/pages/…` location.
- **TEST-007** — regression: satisfied by the existing specs remaining unchanged and green.

**Independent verification performed by this review:**
- `bin/rubocop` (host) — `38 files inspected, no offenses detected`.
- `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rspec` —
  `35 examples, 0 failures` (was 21 before; +14 new).
- Live `GET http://localhost:3000/` — `HTTP 200`, `text/html; charset=utf-8`, body contains the
  brand link to `/`, `<h1>Randevu</h1>`, the exact description, and the `© 2026 Randevu` footer.

Test placement and RSpec conventions are correct: `require "rails_helper"`, explicit
`type: :request`, and `before { host! "example.test" }` per the repo's host-authorization
requirement; the greyscale check sits in the non-default `spec/units/` tree.

## Conventions

- Browser-facing controller inherits `ApplicationController`; JSON/API controllers untouched —
  matches the repo precedent documented in `AGENTS.md`.
- Semantic `header`/`main`/`footer` markup; CSS-first styling with no CSS framework and no Node
  build step.
- Propshaft inclusion via the existing `stylesheet_link_tag :app` needs no manifest change; the
  compiled asset (`/assets/application-*.css`) is emitted in the live response.
- RuboCop clean; no new gem/dependency; no new route helpers or config beyond the root route.

## Issues/Concerns

No blocking issues for KAN-7.

Minor, non-blocking observations:

1. **Out-of-scope security concern (not KAN-7).** `opencode.json` in the working tree contains a
   hard-coded GitHub personal access token (`ghp_…`) in the `mcp.servers.github.headers.Authorization`
   value. This file belongs to the Phase 4/release scaffolding, not the KAN-7 implementation, and the
   reviewed KAN-7 diff does not touch it. It directly conflicts with `AGENTS.md`'s "Never commit real
   credentials." Recommend rotating the token and supplying it via an environment reference (e.g.
   `{env:GITHUB_MCP_TOKEN}`, as `ARCHITECTURE.md` describes) before any commit. Flagged here only
   because the reviewer sees the whole working tree.
2. **TEST-006 scan coverage.** The greyscale unit spec covers hex, `rgb()/rgba()`, and named color
   keywords in color declarations (plus framework markers), which fully covers the CSS actually
   written. It would not catch `hsl()/hsla()` or other color functions if introduced later; not used
   today, so no impact.
3. **AC-003/AC-004 "any browser page" wording.** The criteria are stated for any layout-rendered
   page, but the tests exercise only `/` (the only browser page that exists). Verifying through the
   shared layout is the correct and sufficient interpretation at this point in the project.
4. **Pre-existing `db:test:prepare` exit 1** ("`db/schema.rb` doesn't exist yet") remains true and is
   documented in `AGENTS.md`; unrelated to this ticket and not a regression.

## Recommendations

- None blocking. Ready for Phase 4 validation.
- (Follow-up, outside KAN-7) Rotate the GitHub token and replace the literal in `opencode.json` with
  an env reference, as recommended in Issue/Concern 1.

## Verdict

**Approve**

Implementation matches the approved plan and the KAN-7 specification; all REQ-001..REQ-007 and
AC-001..AC-006 are satisfied with tests at the planned locations; the KAN-7 file scope is exactly as
planned with no changes to the "not expected to change" set; conventions are followed; and no
unrelated KAN-7 changes were made. Independently reproduced: rubocop clean, 35 examples / 0 failures
in the container, live `/` returns 200 HTML with the expected content.

_Phase boundary: this is a Phase 3 review verdict; it is not a release sign-off. Executable
validation evidence (Phase 4) is provided by the validator agent._
