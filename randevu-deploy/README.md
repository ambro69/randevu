# Randevu — Docker Compose (development)

Bare-minimum Dockerized setup for the Randevu app with PostgreSQL.

## Setup

1. Docker with Compose v2 (`docker compose version`).
2. Create the environment file with the database credentials (already done if
   `.env` exists next to this file):

   ```sh
   cp .env.example .env
   ```

   `.env` is git-ignored. The values are used by Docker Compose to configure
   both the Postgres container and the Rails app.

## Usage

```sh
# Build the app image and start Postgres + Rails (from the repo root)
docker compose -f randevu-deploy/docker-compose.yml up --build

# Open the app
open http://localhost:3000
```

The `app` service mounts the repository at `/rails`, so code edits are picked
up by Rails' reloader. The database is created automatically on first boot
(`bin/rails db:prepare` runs via the entrypoint). Postgres data persists in
the `postgres_data` volume.

## Useful commands

```sh
# Run a one-off command, e.g. create/migrate the database
docker compose -f randevu-deploy/docker-compose.yml run --rm app bin/rails db:prepare

# Open a Rails console against the running stack
docker compose -f randevu-deploy/docker-compose.yml exec app bin/rails console

# Tail app logs
docker compose -f randevu-deploy/docker-compose.yml logs -f app

# Stop everything
docker compose -f randevu-deploy/docker-compose.yml down
```

## Environment

| Variable            | Source        | Purpose                         |
| ------------------- | ------------- | ------------------------------- |
| `POSTGRES_DB`       | `randevu-deploy/.env` | Postgres database name   |
| `POSTGRES_USER`     | `randevu-deploy/.env` | Postgres role            |
| `POSTGRES_PASSWORD` | `randevu-deploy/.env` | Dev-only password        |
| `DATABASE_HOST`     | `docker-compose.yml`  | Postgres service name    |

- Credentials live only in `randevu-deploy/.env` (git-ignored); `docker-compose.yml`
  references them via `${VAR}` substitution.
- Production deployment (Kamal) is configured separately in `config/deploy.yml`
  with its own Postgres accessory and secrets in `.kamal/secrets`.