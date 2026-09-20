---
name: jira-create
description: Turn a raw user requirement into a proper, codebase-grounded Jira ticket — ask clarifying questions, finalize a structured description, and create the ticket through the connected Atlassian MCP server.
---

# Jira Ticket Creation Skill

## Purpose

This skill converts a raw, loosely-stated user requirement into a
well-formed Jira ticket in the project's standard engineering
specification format (`plans/JIRA_TEMPLATE.md`).

It is the intake (left) side of the spec-driven workflow:

        Raw requirement
            ↓
        Clarifying questions
            ↓
        Finalized specification (REQ/AC in JIRA_TEMPLATE format)
            ↓
        Metadata selection (type, priority, labels, …)
            ↓
        Jira ticket created
            ↓
        /jira-plan <KEY> (next step)

Unlike free-typed descriptions, this skill grounds the requirements in
the actual repository so the resulting ticket is precise, feasible, and
normalizable later by the `jira-spec` skill.

## When to Use

Use when the user describes a feature, bug fix, or change in plain words
and wants it captured as a Jira ticket. Stop and ask for the requirement
first if none has been provided.

## Inputs

- **Raw requirement** (required): the user's description of what they want.
- **Metadata provided upfront** (optional): any of project key, issue type,
  priority, labels, assignee. Use them; only ask for what is missing.

## Core Rules

1. The user requirement plus the repository are the grounding sources —
   never invent requirements the user did not agree to.
2. Ground every requirement in the codebase: check `AGENTS.md`,
   `config/routes.rb`, `Gemfile`, `app/`, `spec/`, and any existing
   `plans/`/`tasks/` so the ticket respects what already exists.
3. If the requirement conflicts with the codebase (already implemented,
   contradicts existing routes/models/conventions), surface it to the
   user before drafting — do not silently adapt.
4. Preserve the exact section order and heading names of
   `plans/JIRA_TEMPLATE.md` in the ticket description, and use sequential
   `REQ-xxx` / `AC-xxx` identifiers (AC in Given/When/Then form). This
   keeps the description losslessly normalizable by `jira-spec`.
5. Ask, don't assume. Clarify ambiguities with targeted questions; batch
   questions in small groups (aim for 3 or fewer per ask) and offer
   sensible defaults drawn from the codebase and the project template.
6. Before creating the ticket, play the complete drafted specification
   back to the user and get explicit confirmation. Do not create the
   ticket otherwise.
7. Creating the ticket is the single Jira write this skill authorizes.
   Do not modify other issues, and do not transition statuses.
8. Check for likely duplicates (Jira search on the summary / key nouns)
   and tell the user before creating a new ticket.

## Workflow

### Step 1 — Read the requirement and ground it

1. Read the raw requirement the user provided.
2. Inspect the repository enough to ground the requirement:
   - `AGENTS.md` for the app's architecture and runbook.
   - `config/routes.rb`, `Gemfile`, `app/controllers|models|services`,
     `spec/`, and existing `plans/`/`tasks/` for relevant context.
   - Depth should be proportional to the feature's complexity (small
     feature → small inspection).
3. Identify gaps, ambiguities, and possible codebase conflicts. Note them
   for the question round.

### Step 2 — Ask clarifying questions

Ask only about what is genuinely unclear or missing; never re-ask what
was already stated or what the codebase answers.

Cover, in order:

- **Scope & goal** — what success looks like, what is out of scope.
- **Behavior** — exact user-facing behavior and edge cases.
- **Non-functional concerns** — performance, auth, dependencies,
  configuration. If the user mentions nothing, default to the project's
  constraints (e.g., no new dependencies) and record them in the draft.
- **Testing expectations** — what automated tests should verify.

Batch related questions together. After each round, revise your draft.

### Step 3 — Draft the specification

Draft the description in the `plans/JIRA_TEMPLATE.md` structure:

```markdown
# Summary

Short description of what is being built.

# Context

Why this change is needed.
Relevant background information.

# Goal

What the completed feature should accomplish.

# Requirements

REQ-001: ...
REQ-002: ...

# Acceptance Criteria

AC-001
Given ...
When ...
Then ...

# Technical Constraints

- ... (e.g. follow existing Rails conventions; no new dependency)

# Out of Scope

- ...

# Technical Notes

Optional hints about the expected implementation, grounded in the repo
(e.g. "mirrors the existing X controller at /up").

# Testing Requirements

- ...

# Definition of Done

- [ ] All requirements implemented
- [ ] All acceptance criteria satisfied
- [ ] Automated tests added/updated
- [ ] Existing tests pass
- [ ] No unrelated changes
- [ ] Code reviewed
```

### Step 4 — Finalize with the user

Present the full draft and ask for confirmation or specific changes.
Iterate until the user says the requirements are final. Do not skip this
step.

### Step 5 — Select metadata

Ask for anything not already supplied:

- **Issue type** — default `Story` for features, `Bug` for defects,
  `Task` for chores. Verify against the project's allowed types via the
  Atlassian MCP `listJiraProjectIssueTypesMetadata` before creating.
- **Priority** — default `Medium`; offer Highest/High/Medium/Low/Lowest.
- **Labels** — suggest codebase-relevant labels (e.g. `backend`,
  `frontend`, `spec-driven`) from existing tickets/project conventions.
- **Assignee** — optional; only if the user names someone (they may
  remain unassigned).

Summarize the final metadata for confirmation along with the finalized
requirements, then proceed.

### Step 6 — Create the ticket

Create the Jira ticket through the connected Atlassian MCP server:

- Resolve the cloudId once via `getAccessibleAtlassianResources` and pass
  it explicitly.
- Use `createJiraIssue` with: `projectKey`, `summary`
  (concise, imperative — e.g. "Add application health check endpoint"),
  `description` (the finalized markdown from Step 3), `issueType`,
  `priority`, `labels`, and `assignee` (accountId) if chosen.
- Optional duplicate guard: if a close match was found in Step 2/8,
  re-confirm with the user before creating.

Report the created ticket key and URL, confirm which metadata was set,
and point to the next step: `/jira-plan <KEY>`.