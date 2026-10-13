# AGENTS.md

Rails 8.1.3.1 + Ruby 3.4.8 + PostgreSQL web app (module `Randevu::Application`). Importmap +
Turbo/Stimulus, no Node build step. Intended to aggregate calendar/meetings from connected mail
accounts (no integrations implemented yet). Built spec-driven from Jira; `ARCHITECTURE.md` is the
design of record for the agent roles, authority model, and phased rollout.

## Current app state

- No models or app migrations yet (`db/` holds only cache/queue/cable schemas + `seeds.rb`, so there
  is **no `db/schema.rb`**). Domain code so far is JSON endpoints from KAN-4/KAN-5:
  `GET /health` (root) and the versioned namespace `GET /api/v1/health`, `GET /api/v1/endpoints`.
- Non-browser/JSON controllers subclass `ActionController::Base` directly (e.g. `HealthController`,
  `Api::V1::BaseController`) rather than `ApplicationController`, so `allow_browser versions: :modern`
  / `stale_when_importmap_changes` never gate API clients. Follow that precedent for new API endpoints.
- `/api/v1/endpoints` is dynamic: `Api::V1::EndpointListing` derives the method+path list from the
  live `Rails.application.routes.routes`, filtered to `/api/v1/` — never hardcode that listing.
- Routes live in `config/routes.rb`. There is no authentication/authorization mechanism anywhere.

## Spec-driven workflow (OpenCode)

- Jira is the source of truth: never invent requirements, and treat the approved plan as binding
  (re-plan if the Jira spec drifts). Two entry points: `/jira-create` (drafts a new ticket from a
  requirement, repo-grounded) and `/jira-plan <KEY>` (planner subagent → `plans/<JIRA-KEY>.md`, layout
  `plans/PLAN_TEMPLATE.md`).
- The **planner** (`.opencode/agents/planner.md`) is read-only w.r.t. app code/tests/config/Jira and
  may only write `plans/`, `tasks/`, `decisions/`. Plans are DRAFT until approved.
- A human approves with `/jira-approve <KEY>` (`.opencode/commands/jira-approve.md`), which sets
  `Status: APPROVED` plus `Approved By`/`Approved At` from `git config user.name` and UTC now.
- The **implementer** (`.opencode/agents/implementer.md`, `/jira-implement <KEY>`) runs only after the
  approval gate passes. It may edit app code/tests, run them, and write `tasks/<JIRA-KEY>/`
  (layout `tasks/TEMPLATE.md`) + `IMPLEMENTATION.md`; it must not edit `plans/**`, `.opencode/**`,
  or `opencode.json`. Its only Jira write is `To Do → In Progress` at start.
- The implementer never branches/commits/pushes/opens PRs and leaves changes uncommitted for review.
  Later Jira transitions (e.g. → Done) and Git/PR work are later phases (see `ARCHITECTURE.md`).

## Shell / gemset

- Ruby lives in rvm gemset `3.4.8@randevu` (pinned by `.ruby-version` / `.ruby-gemset`);
  `bin/rails`, `bin/rspec`, `bin/rubocop` run directly in the session shell.
- If a shell instead fails with `command not found` or `Bundler::GemNotFound` (stale `GEM_HOME`),
  re-select the gemset via a login shell:

  ```sh
  bash --login -c "rvm use ruby-3.4.8@randevu >/dev/null && cd /home/ambro/projects/randevu && <cmd>"
  ```

- The `Warning! PATH is not properly set up, ...` message from shell init is harmless.

## Database & running the app

- PostgreSQL, **not** the Rails 8 sqlite3 default. `config/database.yml` is env-driven
  (`DATABASE_HOST/PORT/USERNAME/PASSWORD`, defaults `localhost` / `postgres` / `postgres`).
  DBs: `randevu_development`, `randevu_test`, and production
  `randevu_production{,_cache,_queue,_cable}`; Solid Cache/Queue/Cable use separate PG DBs in prod
  and the primary DB in dev/test.
- No Postgres is installed on the host. **Do not run DB-touching commands on the host** — run them
  inside the Docker app container.
- Dev stack: `docker compose -f randevu-deploy/docker-compose.yml up --build`
  (app on `:3000`, Postgres on `:5432`, data persists in the `postgres_data` volume).
- One-off commands:
  `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rails <cmd>`.
- Postgres credentials live in `randevu-deploy/.env` (git-ignored); template is `.env.example`.
  Never commit real credentials.
- To update the lockfile run `bundle lock` on the host (no native compilation). Avoid
  `bundle install` on the host (the `pg` gem needs `libpq` headers that aren't installed).

## Verification / tests

- Lint + security (host, no DB): `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit`,
  `bin/importmap audit`.
- Tests use **RSpec** (`bin/rspec`). Postgres and the `pg` gem exist only in the container, so run
  specs there:
  `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rspec`.
- **Gotcha:** `bin/rails db:test:prepare` currently exits 1 with
  "`db/schema.rb` doesn't exist yet" because the app has no migrations. The suite still runs and
  passes (21 examples) — don't mistake the prepare failure for a test failure. CI's `test` job chains
  `bin/rails db:test:prepare && bin/rspec`, so the same failure mode applies there.
- `bin/ci` (`config/ci.rb`) runs: setup → rubocop → security audits (bundler-audit, importmap,
  brakeman) → `db:test:prepare && rspec` → `db:seed:replant`.

## RSpec conventions

- Specs live in `spec/`. Note the non-default `spec/units/` (plain-Ruby unit specs) alongside
  `spec/requests/`; `spec/smoke_spec.rb` is DB-free.
- Spec type inference is OFF (`config.infer_spec_type_from_file_location!` is commented out), so
  request specs must declare `type: :request` explicitly.
- Request specs MUST set `before { host! "example.test" }`: Rails 8.1 test-env
  `ActionDispatch::HostAuthorization` returns 403 for the default `www.example.com` before routing.
- `spec/rails_helper.rb` calls `maintain_test_schema!`; `spec/examples.txt` is git-ignored.

## Image split (do not conflate)

- Root `Dockerfile` is the **production/Kamal** image: baked `RAILS_ENV=production`,
  `BUNDLE_WITHOUT=development`, non-root `rails` user, Thruster on `:80`. Not for dev.
- `randevu-deploy/Dockerfile` is the **dev** image: all gems incl. dev/test, root user, repo
  live-mounted at `/rails`.
- `config/deploy.yml` uses a postgres `accessories.db` for production deploys.

## Workflow artifacts

- `ARCHITECTURE.md` — agent roles, authority table, phase plan (Phases 1–4 completed; Phase 5 not started).
- Agents: `planner`, `implementer`, `reviewer`, `validator`, `release` (and commands `/jira-plan`, `/jira-approve`, `/jira-implement`, `/jira-review`, `/jira-validate`, `/jira-release`).
- Artifacts: `plans/<JIRA-KEY>.md` (`plans/PLAN_TEMPLATE.md`), `tasks/<JIRA-KEY>/` (`tasks/TEMPLATE.md`), `review/<JIRA-KEY>/REVIEW.md`, `validation/<JIRA-KEY>/VALIDATION.md`, `release/<JIRA-KEY>/RELEASE.md`, `decisions/`.
