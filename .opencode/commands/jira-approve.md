---
description: Approve a plan so the implementer can begin
---

Mark the implementation plan at plans/$ARGUMENTS.md as approved by a human.
If that plan file does not exist, stop and say so — do not create it.

Read the plan's current approval block, then update ONLY these fields:

- `Status:` → `APPROVED`
- `Approval:` → `Approved`
- `Approved By:` → !`git config user.name` (the git-configured user name; if that
  is empty, ask me for my name instead of inventing one)
- `Approved At:` → !`date -u +%Y-%m-%dT%H:%M:%SZ`

Rules:

- If the plan already reads `Status: APPROVED`, do NOT overwrite the existing
  approval — report the current Approved By / Approved At and stop.
- Change nothing else in the plan. Do not touch any other file.
- Do not commit, push, or update Jira — approving only records the human
  go-ahead in the plan file.

When done, confirm the resulting approval block and state that the plan is
ready for /jira-implement $ARGUMENTS.