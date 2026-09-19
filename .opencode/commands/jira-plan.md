---
description: Create an implementation plan from a Jira issue
agent: planner
---

Create an implementation plan for Jira issue $ARGUMENTS.

The operation is strictly read-only with respect to:

- application source code
- tests
- configuration
- database schema
- Jira

You may create or update planning artifacts under plans/, tasks/,
and decisions/.

Retrieve the Jira issue using the jira-spec skill.

Inspect the Rails repository.

Produce the implementation plan at:

plans/<JIRA-KEY>.md

Do not implement the feature.
Do not create a branch.
Do not commit.
Do not push.
Do not modify Jira.
