# KAN-7 — Implementation Summary

## Approval Status Verified

- Plan `plans/KAN-7.md`: **Status APPROVED**, **Approved By ambro69**,
  **Approved At 2026-10-13T18:05:24Z** — all approval-gate fields were present
  before implementation began.
- Jira issue KAN-7 matched the plan's specification snapshot (summary, status
  `To Do`, type Story, labels `frontend`; requirements/AC/constraints identical)
  — no drift, so implementation proceeded.
- First action after the gate: transitioned KAN-7 **To Do → In Progress**
  (transition id 21). This was the only Jira write made.

## Tasks Completed

| Task | Status | Summary |
|---|---|---|
| TASK-001 — root route + `PagesController#home` | implemented | `root "pages#home"` replaces the commented root in `config/routes.rb`; new `app/controllers/pages_controller.rb` inheriting `ApplicationController`. |
| TASK-002 — landing view | implemented | New `app/views/pages/home.html.erb` with `<main>` → name + exact one-line description. |
| TASK-003 — shared header/footer chrome | implemented | `app/views/layouts/application.html.erb` `<body>` now wraps the yield in a semantic `<header>` (brand link to `/`) and `<footer>` (copyright line). |
| TASK-004 — greyscale-only CSS | implemented | Hand-written greyscale rules appended to `app/assets/stylesheets/application.css`. |
| TASK-005 — request + greyscale specs | implemented | New `spec/requests/pages_spec.rb` (9 examples) and `spec/units/pages/greyscale_stylesheet_spec.rb` (5 examples). |

No tasks blocked.

## What Was Implemented (per task)

### TASK-001 — root route and `PagesController#home`

- **`config/routes.rb` (modified):** the commented `# root "posts#index"` line
  became `root "pages#home"`. Every other route (`/up`, `/health`,
  `namespace :api { namespace :v1 }`, PWA comments) is byte-for-byte unchanged.
- **`app/controllers/pages_controller.rb` (added):** `PagesController <
  ApplicationController` with an empty `home` action; Rails' implicit render
  serves `app/views/pages/home.html.erb`. Inheriting `ApplicationController`
  (not `ActionController::Base`) is required by the ticket's technical
  constraint so the page is browser-facing (`allow_browser versions: :modern`).

### TASK-002 — landing view

- **`app/views/pages/home.html.erb` (added):** semantic `<main class="page">`
  containing an `<h1>Randevu</h1>` and the exact description string
  `Randevu aggregates your calendars and meetings from connected mail accounts in one place.`
  No other content (out-of-scope items excluded). The view provides `<main>`;
  the layout provides `<header>`/`<footer>`.

### TASK-003 — shared layout chrome

- **`app/views/layouts/application.html.erb` (modified):** inside `<body>`, the
  bare `<%= yield %>` is now wrapped by a `<header class="site-header">` with
  `<nav aria-label="Primary">` and `link_to "Randevu", root_path`, and a
  `<footer class="site-footer">` with
  `<p>&copy; <%= Time.current.year %> Randevu. All rights reserved.</p>`.
  `<head>`, asset tags, meta tags, PWA comments and the mailer layouts are
  untouched.

### TASK-004 — greyscale CSS

- **`app/assets/stylesheets/application.css` (modified):** appended hand-written
  rules only — a greyscale custom-property palette (`--grey-000` `#ffffff`
  through `--grey-900` `#111111`, all channels equal), base body typography,
  header/nav bar, brand link, content container, footer, and one
  `@media (min-width: 40rem)` responsive tweak. No framework, no `@import`, no
  remote asset, no gem/importmap/build-step change. A-3 (CSS placement) resolved
  in favour of the existing file for a minimal diff, as the plan defaults to.

## Tests Added and How to Run

- `spec/requests/pages_spec.rb` (new; 9 examples): `type: :request` +
  `before { host! "example.test" }` per repo convention. Covers TEST-001..TEST-005.
- `spec/units/pages/greyscale_stylesheet_spec.rb` (new; 5 examples, non-DB):
  static greyscale/no-framework scan for TEST-006 (AC-005), at the plan's
  optional `spec/units/pages/…` location.
- Run in the Docker app container:
  - targeted: `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rspec spec/requests/pages_spec.rb spec/units/pages/greyscale_stylesheet_spec.rb`
  - full suite: `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rspec`
- Lint on host: `bin/rubocop`

## Verification Run (results)

| Check | Command | Result |
|---|---|---|
| Lint | `bin/rubocop` (host) | 38 files inspected, **no offenses** |
| New specs | `bin/rspec spec/requests/pages_spec.rb spec/units/pages/greyscale_stylesheet_spec.rb` (container) | **14 examples, 0 failures** |
| Full suite (regression, TEST-007) | `bin/rspec` (container) | **35 examples, 0 failures** (was 21 before this ticket) |
| `allow_browser` risk check | request specs render `/` | Renders successfully with the default request-spec User-Agent; no UA workaround needed |

## Deviations from the Plan

None. All implementation stayed within the plan's "Files Expected To Change" /
"Files Expected To Be Added". No existing route, controller, JSON behavior,
dependency, or test was modified.

## Notes / Things Needing Human Attention

1. **Pre-existing `db:test:prepare` failure (unrelated, not a regression).**
   `bin/rails db:test:prepare` in the container still aborts with
   "`db/schema.rb` doesn't exist yet" because the app has no migrations. This is
   documented in `AGENTS.md` as the known state on `main` and is not caused by
   this ticket; a full `bin/rspec` run is green regardless.
2. **TEST-006 scope (A-1).** AC-005 is verified by a static scan (greyscale hex /
   `rgb()` literals, greyscale named keywords in color declarations, and no CSS
   framework in the stylesheet, Gemfile, or importmap). "No new dependency" is
   additionally evidenced by the working-tree diff touching no dependency files
   (`Gemfile`, `Gemfile.lock`, `config/importmap.rb`, `app/javascript/**` are
   unmodified).
3. **TEST-007 scope.** Regression is covered by the untouched existing specs
   (`spec/requests/health_spec.rb`, `spec/requests/api/v1/*`,
   `spec/units/api/v1/*`, `spec/smoke_spec.rb`) continuing to pass; no new spec
   file was added for it.
4. **Pre-existing working-tree changes not made by this phase.** `AGENTS.md`,
   `ARCHITECTURE.md`, `opencode.json`, `.opencode/agents/release.md`,
   `.opencode/commands/jira-release.md`, `release/` and `plans/KAN-7.md` were
   already modified/untracked before implementation began; they are not
   implementer edits (the plan file is the `/jira-approve` fill-in).

## Definition of Done — Phase Attribution

Done by the implementer (this phase): all requirements implemented; all
acceptance criteria satisfied (AC-001..AC-006, per the plan Traceability
Matrix); automated tests added and passing; existing tests pass; no unrelated
changes.

Belongs to later phases (not done here): **code review** ("Code reviewed"), and
formal validation/release sign-off.

## Changes Left Uncommitted

All changes are confined to the working tree and left uncommitted for human
review. No branch, commit, push, or PR.

- Modified: `config/routes.rb`, `app/views/layouts/application.html.erb`,
  `app/assets/stylesheets/application.css`
- Added: `app/controllers/pages_controller.rb`, `app/views/pages/home.html.erb`,
  `spec/requests/pages_spec.rb`, `spec/units/pages/greyscale_stylesheet_spec.rb`,
  `tasks/KAN-7/TASK-001.md` … `TASK-005.md`, `tasks/KAN-7/IMPLEMENTATION.md`
- Jira: KAN-7 transitioned `To Do` → `In Progress` (only Jira write); no other
  field or status changed.
