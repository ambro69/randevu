---
description: Release a validated implementation (branch, commit, PR, Jira update)
agent: release
---

Release the validated implementation for Jira issue $ARGUMENTS.

First verify the Release Gate: plans/$ARGUMENTS.md must read Status: APPROVED with
Approved By and Approved At filled, and validation/$ARGUMENTS/VALIDATION.md must
report Verdict: PASS. If either fails, stop and mutate nothing.

Once the gate passes, release exactly the files the plan expects plus the workflow
artifacts (plans/$ARGUMENTS.md, tasks/$ARGUMENTS/, review/$ARGUMENTS/,
validation/$ARGUMENTS/):

- create branch feature/$ARGUMENTS from main locally, stage the enumerated files,
  commit them in a single commit, and push the branch with local git
- open a pull request against main via the GitHub MCP with a plan- and
  validation-derived body (the local environment has no gh CLI)
- transition the Jira issue to In Review and link the pull request via a comment
- write release/$ARGUMENTS/RELEASE.md recording the real commit SHA and PR URL

You MUST NOT:

- modify application code, tests, config, or database files
- edit plans/tasks/review/validation artifacts or framework definitions
- merge the pull request, push to main, or force-push
- transition Jira to any status other than In Review

Exclude unrelated working-tree changes from the commit, leave them untouched, and
report them. Leave the release artifact uncommitted.
