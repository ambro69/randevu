---
description: Review implementation against an approved plan and Jira spec
agent: reviewer
---

Review implementation for Jira issue $ARGUMENTS.

Operate read-only. Retrieve Jira spec via jira-spec, read approved plan at plans/$ARGUMENTS.md, read task artifacts at tasks/$ARGUMENTS/, and inspect working tree changes.

Produce review report at review/$ARGUMENTS/REVIEW.md with verdict (Approve/Changes Requested/Needs Clarification) and concrete findings.

Do not modify code, tests, plans, tasks, Jira, or Git history. Leave changes uncommitted.
