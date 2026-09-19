# AGENTS.md

Rails 8.1.3.1 + Ruby 3.4.8 + PostgreSQL web app (module `Randevu::Application`).
Importmap + Turbo/Stimulus, no Node build step. Aggregates calendar/meetings from connected mail
accounts (Google, Outlook, ...).

The app is still a bare Rails 8 scaffold: only the default `up`/`rails/health` route and base
`ApplicationRecord`/`ApplicationController` exist — no domain code yet.

## Spec-driven workflow (OpenCode)

- The app is built spec-driven from **Jira**: `opencode.json` wires the Atlassian MCP server,
  `.opencode/skills/jira-spec/SKILL.md` normalizes an issue into the project's spec format, and the
  **planner** subagent (`.opencode/agents/planner.md`, invoked via `.opencode/commands/jira-plan.md`)
  converts a spec into `plans/<JIRA-KEY>.md` (layout: `plans/PLAN_TEMPLATE.md`).
- Jira is the source of truth — never invent requirements, and treat the approved plan as binding
  (re-plan if the Jira spec drifts).
- The planner is strictly read-only w.r.t. app code, tests, config, and Jira; it may only write
  `plans/`, `tasks/`, and `decisions/`. Plans are DRAFT until a human approves them.

## Shell / gemset (critical)

- Ruby lives in rvm gemset `3.4.8@randevu` (pinned by `.ruby-version` / `.ruby-gemset`).
- Plain non-login shells keep a stale `GEM_HOME` pointing at the deleted `@randeivu`
  gemset, so `rails` and bundler commands fail ("command not found" / `Bundler::GemNotFound`).
  Always run app commands through a login shell that selects the gemset:

  ```sh
  bash --login -c "rvm use ruby-3.4.8@randevu >/dev/null && cd /home/ambro/projects/randevu && <cmd>"
  ```

- The `Warning! PATH is not properly set up, ...@randeivu/bin` message from shell init is
  harmless — that gemset no longer exists.

## Database & running the app

- PostgreSQL, **not** the Rails 8 sqlite3 default. `config/database.yml` is env-driven
  (`DATABASE_HOST/PORT/USERNAME/PASSWORD`, defaults `localhost` / `postgres` / `postgres`).
  DBs: `randevu_development`, `randevu_test`, and production
  `randevu_production{,_cache,_queue,_cable}` (Solid Cache/Queue/Cable use separate PG DBs in
  prod, the primary DB in dev/test).
- No Postgres is installed on the host (installing needs sudo, which requires a password).
  **Do not run DB-touching commands on the host** — run everything inside the Docker app container.
- Dev stack: `docker compose -f randevu-deploy/docker-compose.yml up --build`
  (app on `:3000`, Postgres on `:5432`, PG data persists in the `postgres_data` volume).
- One-off commands: `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rails <cmd>`
  (e.g. `bin/rails db:prepare`, `bin/rails console`).
- Postgres credentials live in `randevu-deploy/.env` (git-ignored); the committed template is
  `randevu-deploy/.env.example`. Never commit real credentials.
- Docker Desktop (engine 28.3, Compose v2) is installed and the daemon is reachable — the dev
  stack above works. First `up --build` builds the dev image and creates the `postgres_data` volume.
- To update the lockfile, run `bundle lock` on the host (no native compilation needed).
  Avoid `bundle install` on the host (pg needs `libpq` headers that aren't installed).

## Verification

- Lint: `bin/rubocop`. Security (no DB needed): `bin/brakeman`, `bin/bundler-audit`, `bin/importmap audit`.
- Tests use **RSpec** (`bin/rspec`, a.k.a. `bundle exec rspec`). There is no Minitest
  suite anymore (`test/` was removed; specs live in `spec/`).
- RSpec needs Postgres and the pg gem, which only exist in the container:
  `docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rails db:test:prepare` then
  `bin/rspec`. `db:test:prepare` is a manual prerequisite of the test task. Locally (host, no
  Postgres), only DB-free specs run — the committed smoke spec (`spec/smoke_spec.rb`) is DB-free
  for this reason.
- `bin/ci` runs setup → rubocop → audits → tests → seeds replant.
- GitHub Actions CI `test` job has a `postgres` service container and runs
  `bin/rails db:test:prepare && bin/rspec`. The former `system-test` job is disabled until
  system specs exist (see the commented-out block in `.github/workflows/ci.yml`).

## Image split (do not conflate)

- Root `Dockerfile` is the **production/Kamal** image: baked `RAILS_ENV=production`,
  `BUNDLE_WITHOUT=development`, non-root `rails` user, Thruster on `:80`. Not for dev.
- `randevu-deploy/Dockerfile` is the **dev** image: all gems incl. dev/test, root user, repo
  live-mounted at `/rails`.
- `config/deploy.yml` uses a postgres `accessories.db` for production deploys.

## History

- App was renamed **Randeivu → Randevu**; only stale shell PATH warnings still mention the old name.
- Test suite migrated **Minitest → RSpec**: `test/` removed, `rspec-rails` added, one DB-free
  smoke spec (`spec/smoke_spec.rb`) proves the suite runs. `spec/rails_helper.rb` still calls
  `maintain_test_schema!`; enable it around the first DB-backed spec (needs `db:test:prepare`
  first). `spec/examples.txt` is git-ignored.
- No app migrations yet (`db/` only has cache/queue/cable schemas + `seeds.rb`), so there is no `db/schema.rb`.