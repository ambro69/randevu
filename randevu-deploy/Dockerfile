# syntax=docker/dockerfile:1

# Development image for Randevu.
#
# Builds from the project root (see docker-compose.yml `build.context`),
# so it picks up the app code, Gemfile and Gemfile.lock.
FROM docker.io/library/ruby:3.4.8-slim

# Rails app lives here (matches the production Dockerfile).
WORKDIR /rails

# Base + build packages. libpq-dev is required to compile the pg gem.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Dev runtime: no production env, include development/test gems.
ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle

# Install gems (everything except system-specific platforms).
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code (./dockerignore filters out secrets, logs, tmp...).
COPY . .

EXPOSE 3000

# Default command; override with `docker compose run app ...`
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]