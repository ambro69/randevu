---
description: Implement an approved plan for a Jira issue
agent: implementer
---

Implement the approved implementation plan for Jira issue $ARGUMENTS.

Operate from the approved plan at plans/$ARGUMENTS.md.

First verify the Approval Gate: the plan must read Status: APPROVED with
Approved By and Approved At filled. If the plan is DRAFT or lacks approval
fields, stop and request human approval — do not implement anything.

You MAY:

- read the repository and the Jira issue (read-only)
- modify application code and tests
- run tests and linters
- create/update task status artifacts under tasks/$ARGUMENTS/

You MUST NOT:

- edit the plan file under plans/ (binding)
- modify framework definitions under .opencode/ or opencode.json
- create branches, commit, push, or open pull requests
- update or transition the Jira issue
- implement review, validation, or release features (later phases)

Work through the plan's Implementation Tasks in order, marking status under
tasks/$ARGUMENTS/ as you go, and finish with an implementation summary at
tasks/$ARGUMENTS/IMPLEMENTATION.md.

Leave all changes uncommitted in the working tree for human review.