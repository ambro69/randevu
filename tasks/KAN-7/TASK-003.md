# KAN-7 — TASK-003 — Add shared header/footer chrome to the application layout

Status: implemented

## Requirements

- REQ-005
- REQ-006
- Technical Constraint: layout must remain the shared application layout used by future browser pages; semantic `header`/`main`/`footer`.

## Acceptance Criteria

- AC-003
- AC-004

## Implementation Notes

- `app/views/layouts/application.html.erb` — inside `<body>`, wrapped the existing `<%= yield %>` with:
  - `<header class="site-header">` containing a `<nav aria-label="Primary">` with `link_to "Randevu", root_path` (REQ-005 / AC-003).
  - `<footer class="site-footer">` containing `<p>&copy; <%= Time.current.year %> Randevu. All rights reserved.</p>` (REQ-006 / AC-004).
- `<head>` (title, meta tags, csrf/csp, PWA comments, icon links, stylesheet/importmap tags) and the mailer layouts are unchanged.
- A-2 (footer wording) resolved with a conventional `© <year> Randevu. All rights reserved.` line; the spec asserts "Randevu" plus a copyright indicator rather than an exact string.

## Tests

- `spec/requests/pages_spec.rb` — "renders a header landmark with the app name linked to /" and "renders a footer landmark with a Randevu copyright line" (TEST-003 / TEST-004), parsed with Nokogiri.

## Verification

- RSpec (Docker container): full suite green (35 examples, 0 failures).

## Blockers / Notes for Human

- none
