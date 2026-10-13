---
description: Validate implementation and produce requirement-level evidence
agent: validator
---

Validate implementation for Jira issue $ARGUMENTS.

Operate read-only. Retrieve Jira spec via jira-spec, read approved plan at plans/$ARGUMENTS.md, read tasks/$ARGUMENTS/ and any review/$ARGUMENTS/ if present.

Follow repo runbook in AGENTS.md: run lint/security as appropriate (host) and RSpec in Docker container. Map each REQ-xxx/AC-xxx to executable evidence.

Produce validation report at validation/$ARGUMENTS/VALIDATION.md with verdict (PASS/PARTIAL/FAIL) and evidence matrix.

Do not modify code, tests, plans, tasks, Jira, or Git history. Leave changes uncommitted.
