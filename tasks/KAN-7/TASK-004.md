# KAN-7 — TASK-004 — Add greyscale-only stylesheet rules

Status: implemented

## Requirements

- REQ-007
- Technical Constraints: Propshaft, hand-written CSS, no new dependency, responsive-friendly.

## Acceptance Criteria

- AC-005

## Implementation Notes

- `app/assets/stylesheets/application.css` — appended hand-written rules to the existing Propshaft manifest file (A-3 default): a greyscale custom-property palette (`--grey-000` … `--grey-900`, all channels equal), base `body` typography, a max-width `.site-header`/`.site-nav` bar, `.site-brand` link, `.page`/`.hero` content container, `.site-footer`, and one `@media (min-width: 40rem)` responsive tweak.
- Only greyscale values are used: `#111111`, `#333333`, `#555555`, `#cccccc`, `#f2f2f2`, `#ffffff` (every channel of each value is identical).
- No CSS framework, no `@import`, no remote stylesheet, no gem/importmap/build-step change.

## Tests

- `spec/units/pages/greyscale_stylesheet_spec.rb` (TEST-006) — static scan asserting all hex and `rgb()/rgba()` literals are greyscale, that named color keywords in color declarations are greyscale, and that no CSS framework appears in the stylesheet, Gemfile, or importmap.

## Verification

- RSpec (Docker container): `spec/units/pages/greyscale_stylesheet_spec.rb` 5 examples, 0 failures.
- `bin/rubocop` — no offenses.

## Blockers / Notes for Human

- none
