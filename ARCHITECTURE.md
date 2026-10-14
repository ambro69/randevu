# 1. Overall Architecture

The system we're building is a spec-driven agentic development framework where:

- JIRA is the source of truth
- OpenCode is the agent/execution environment
- Gemini is the LLM/model used by OpenCode
- The framework controls the development workflow, rules, state and authority
- Git/repository state provides the implementation reality
- Tests/validation provide evidence that requirements were satisfied
- Human approval remains part of the workflow

The high-level flow is:

                         ┌─────────────────────┐
                         │        JIRA         │
                         │   Source of Truth   │
                         │                     │
                         │ Requirements        │
                         │ Acceptance Criteria │
                         │ Status              │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │       PLANNER       │
                         │                     │
                         │ Read specification  │
                         │ Read repository     │
                         │ Produce plan        │
                         └──────────┬──────────┘
                                    │
                              Approved Plan
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │     IMPLEMENTER     │
                         │                     │
                         │ Implement tasks     │
                         │ Write tests         │
                         │ Modify repository   │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      REVIEWER        │
                         │                      │
                         │ Review implementation│
                         │ Check requirements   │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │      VALIDATOR      │
                         │                     │
                         │ Run checks/tests    │
                         │ Verify acceptance   │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │       RELEASE       │
                         │                     │
                         │ Commit / Push / PR  │
                         │ Update JIRA         │
                         └─────────────────────┘
                        
# 2. Separation of Responsibilities

We also established that OpenCode itself shouldn't be treated as the entire framework.

Think of it as:


        ┌──────────────────────────────────────────────┐
        │          Spec-Driven Framework               │
        │                                              │
        │  Specifications                              │
        │  Workflow                                    │
        │  State                                       │
        │  Authority                                   │
        │  Rules                                       │
        │  Traceability                                │
        │  Validation                                  │
        │                                              │
        └─────────────────────┬────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │    OpenCode   │
                    │               │
                    │ Agent runtime │
                    │ Tool execution│
                    │ Model access  │
                    └───────┬───────┘
                            │
                            ▼
                        LLM API

# 3. JIRA as the Source of Truth

The fundamental principle is:

        JIRA
        │
        ├── Requirements
        ├── Acceptance Criteria
        ├── Ticket state
        └── Business intent
            │
            ▼
            Framework
            │
            ▼
        Repository / Implementation

The agent should not invent requirements.

A typical ticket eventually looks conceptually like:

        JIRA Ticket

        KAN-4

        Goal:
        Provide a lightweight HTTP health check endpoint.

        Requirements:
        REQ-001 ...
        REQ-002 ...
        REQ-003 ...

        Acceptance Criteria:
        AC-001 ...
        AC-002 ...

The planner consumes this specification and turns it into an implementation plan.

That gives us the important relationship:

        JIRA Requirement
            ↓
          Plan Task
            ↓
        Implementation
            ↓
           Test
            ↓
        Acceptance Evidence

Eventually this becomes our traceability model.

# 4. The Agent Roles

The architecture we discussed separates agents by responsibility.

## Planner

The planner:

Reads JIRA specification
Reads the repository
Understands existing architecture
Produces an implementation plan
Breaks requirements into tasks

The planner does not implement code.

Conceptually:

        JIRA + Repository
            ↓
          Planner
            ↓
        Implementation Plan

## Implementer

The implementer:

- Takes an approved plan
- Implements the tasks
- Writes/updates tests
- Changes repository files

It should not independently redefine the requirements.

        Approved Plan
            ↓
        Implementer
            ↓
        Code + Tests


## Reviewer

The reviewer is intended to inspect the implementation.

It asks things such as:

- Does implementation follow the plan?
- Are requirements addressed?
- Are there unnecessary changes?
- Are tests appropriate?
- Are there obvious problems?

The reviewer should initially be read-only.

## Validator

The validator provides actual verification.

For example:

        REQ-001 → verified
        REQ-002 → verified
        REQ-003 → failed

This is different from the reviewer.

The reviewer says:

`` "This implementation appears correct." ``

The validator provides executable evidence:

`` "These tests/checks actually passed." ``

## Release Agent

Later, a release-oriented agent can handle things such as:

- Commit
- Push
- Pull request
- JIRA status updates

This is deliberately separated from implementation.

## 5. Authority Model

Each agent should have explicit authority.

A simplified version is:

| Agent       | Read JIRA | Read Repo | Modify Code | Run Tests | Review |       Git Commit | Push/PR | Update JIRA |
| ----------- | --------: | --------: | ----------: | --------: | -----: | ---------------: | ------: | ----------: |
| Planner     |         ✅ |         ✅ |           ❌ |         ❌ |      ❌ |                ❌ |       ❌ |           ❌ |
| Implementer |     maybe |         ✅ |           ✅ |         ✅ |      ❌ | later/controlled |       ❌ |      ⚠ start¹ |
| Reviewer    |     maybe |         ✅ |           ❌ |     maybe |      ✅ |                ❌ |       ❌ |           ❌ |
| Validator   |     maybe |         ✅ |           ❌ |         ✅ |      ❌ |                ❌ |       ❌ |           ❌ |
| Release     |     maybe |         ✅ |           ❌ |     maybe |      ❌ |                ✅ |       ✅ |           ✅ |

¹ The only Jira write the Implementer is permitted: transitioning the approved issue
`To Do` → `In Progress` at implementation start, immediately after the Approval Gate passes.
All other Jira status/field updates (e.g. → Done) belong to the Release agent (Phase 4).

The important architectural principle is:

`` An agent's capabilities must be explicitly defined rather than implicitly inherited from OpenCode. ``

## 6. The Phase Plan

Phase 1 — Foundation

Goal:

Build the minimum system capable of going from:

        JIRA specification
                ↓
        normalized specification
                ↓
        implementation plan


- Phase 1 includes
- Basic project/framework structure
- JIRA integration
- Fetching a JIRA ticket
- Representing/normalizing the specification
- Requirements and acceptance criteria representation
- Planner
- Plan output
- Basic authority boundaries needed for this phase
- Basic configuration needed to run the system

Phase 1 does NOT include

- ❌ Actual implementation agent
- ❌ Reviewer
- ❌ Validator
- ❌ Automated requirement verification
- ❌ PR creation
- ❌ Git push
- ❌ Release automation
- ❌ Full orchestration
- ❌ Complete traceability system

The output of Phase 1 is essentially:

        JIRA ticket
            ↓
        Planner
            ↓
        Implementation Plan

## 7. Phase 2 — Development

Once Phase 1 works reliably, we add implementation.

        JIRA
        ↓
        Planner
        ↓
        Approved Plan
        ↓
        Implementer
        ↓
        Code + Tests

This phase introduces the implementation agent.

The implementer works from the approved plan.

At start, once the Approval Gate passes, the implementer moves the approved issue
`To Do` → `In Progress` — the single Jira write permitted in this phase. The ticket
stays `To Do` through planning and approval and only moves when implementation begins.

It should not suddenly become a reviewer, release agent, or full autonomous orchestrator.

## 8. Phase 3 — Review & Validation

Then we introduce verification.

                    ┌──→ Reviewer
                    │
        Implementation
                    │
                    └──→ Validator

The reviewer evaluates the implementation.

The validator executes checks and maps results back to requirements.

This is where the requirement-level verification concept becomes more important:

        REQ-001
        ↓
        Implementation
        ↓
        Test
        ↓
        Evidence

## 9. Phase 4 — Git / PR / JIRA Workflow

Only after development and validation are established do we introduce release operations.

Conceptually:

        Validated Implementation
                ↓
            Commit
                ↓
                Push
                ↓
                PR
                ↓
            JIRA update

This phase introduces higher-risk capabilities, so they should not be given to earlier agents just because OpenCode technically can execute them.

## 10. Phase 5 — Orchestration

Finally, we make the entire workflow operate as a coherent system.

Something conceptually like:

        JIRA
        ↓
        Planning
        ↓
        Approval
        ↓
        Implementation
        ↓
        Review
        ↓
        Validation
        ↓
        Release
        ↓
        JIRA update


At this stage we can introduce higher-level commands/workflows and automation.

This is where the framework starts becoming genuinely agentic, rather than just a collection of individual agents.

## 11. The Important Architectural Invariant

`` Every implementation change must be traceable back to a requirement, and every requirement must eventually have verification evidence. ``


So the eventual model is:

                 JIRA
                  │
                  ▼
            Requirement
                  │
                  ▼
                Task
                  │
                  ▼
           Implementation
                  │
                  ▼
                Test
                  │
                  ▼
              Evidence
                  │
                  ▼
             Acceptance


## 12. Our Phase Boundary Rule

I'd like us to adopt this as an explicit development rule from now on:

When implementing a phase:
Only implement requirements belonging to that phase.
Do not implement infrastructure that exists solely for a later phase.
Do not anticipate later agents unless the current phase explicitly needs their interfaces.
Do not add "helpful" automation that belongs to a later phase.
If a later-phase concern is discovered, document it as a future requirement, don't implement it.
At the end of a phase, verify that the phase's acceptance criteria are satisfied.
Only then move to the next phase.

# Phase checkpoint

- [x] **Phase 1 — Foundation** (completed, verified 2026-09-20)

  All Phase 1 scope is implemented and was exercised end-to-end:

  - **JIRA integration / fetching a ticket:** `opencode.json` wires the Atlassian MCP server
    (`https://mcp.atlassian.com/v2/mcp`); verified reachable against `randevu.atlassian.net`,
    `getJiraIssue` retrieves KAN-4 (status "To Do", matching the plan's recorded snapshot).
  - **JIRA ticket creation (intake):** `jira-create` skill (`.opencode/skills/jira-create/SKILL.md`)
    plus the `/jira-create` command (`.opencode/commands/jira-create.md`) convert a raw user
    requirement into a structured, codebase-grounded Jira ticket: clarifying questions → draft
    specification in the `plans/JIRA_TEMPLATE.md` structure (REQ-001…, AC-001… Given/When/Then) →
    explicit user confirmation → metadata selection (issue type, priority, labels, optional
    assignee) → creation via Atlassian MCP `createJiraIssue`. Guards: creating the ticket is the
    only Jira write it performs (no transitions, no edits to other issues); likely duplicates and
    codebase conflicts are surfaced to the user before creation. Pairing with `jira-spec`
    (retrieval), this closes the Jira integration loop in both directions.
  - **Normalized specification / requirements & AC representation:** `jira-spec` skill
    (`.opencode/skills/jira-spec/SKILL.md`) defines the normalized structure (ticket → metadata +
    specification with requirements, acceptance criteria, constraints, out-of-scope, testing
    requirements, definition of done); `plans/JIRA_TEMPLATE.md` is the Jira-side spec template
    (REQ-001…, AC-001… Given/When/Then).
  - **Planner:** `.opencode/agents/planner.md` (subagent; `edit:*` denied) plus the `/jira-plan`
    command. Authority boundaries enforced: strictly read-only w.r.t. application code and Jira;
    may only write `plans/`, `tasks/`, `decisions/`; no branch/commit/push/PR/Jira transition.
  - **Plan output:** `plans/PLAN_TEMPLATE.md` (12 sections incl. specification, tasks, test plan,
    traceability matrix, risks, ambiguities) and a real produced plan `plans/KAN-4.md` (DRAFT,
    pending human approval).
  - **Basic project/framework structure & configuration:** `.opencode/` (agents/commands/skills),
    `plans/`, `tasks/`, `decisions/` directories, `AGENTS.md` runbook, `review/`/`validation/`
    placeholders reserved for later phases, `randevu-deploy` dev stack.
  - **Phase 1 excludes respected:** no implementer/reviewer/validator agents, no automated
    requirement verification, no release/Git automation, no orchestration.

- [x] **Phase 2 — Development** (completed, verified 2026-09-20)

  The implementer role from §1/§5/§7 is in place and its authority boundary was
  exercised end-to-end:

  - **Implementer agent:** `.opencode/agents/implementer.md` (subagent). Default-allow tools
    (modifies code, writes/updates tests, runs tests) with hard denials for non-Phase-2
    authority: cannot edit `plans/**` (binding plan), `.opencode/**`, or `opencode.json`
    (framework), cannot run `git commit/push`, branch creation, or `gh pr` commands, and cannot
    launch subagents (not an orchestrator).
  - **Command:** `/jira-implement <JIRA-KEY>` (`.opencode/commands/jira-implement.md`) routes a
    Jira key to the implementer agent.
  - **Approval command:** `/jira-approve <JIRA-KEY>` (`.opencode/commands/jira-approve.md`) lets a
    human mark a plan `APPROVED` without hand-editing — it fills `Approved By` from
    `git config user.name` and `Approved At` from the UTC timestamp automatically, and refuses to
    overwrite an existing approval.
  - **Approval gate enforced:** the implementer must not begin until the plan reads
    `Status: APPROVED` with `Approved By`/`Approved At` filled. Verified live: invoked against
    `plans/KAN-4.md` (still DRAFT) — the implementer stopped and requested human approval
    instead of implementing.
  - **Jira status at start:** once the gate passes, the implementer transitions the approved issue
    `To Do` → `In Progress` as its first action — the sole Jira write of this phase (the deliberate
    carve-out to the "no Jira updates until Phase 4" rule; all other transitions, e.g. → Done, stay
    in Phase 4).
  - **Task tracking:** per-task status artifacts under `tasks/<JIRA-KEY>/` (layout:
    `tasks/TEMPLATE.md`) with an implementation summary `IMPLEMENTATION.md`.
  - **Output contract:** changes are confined to the working tree and left uncommitted for human
    review; no branches, commits, pushes, or PRs (Git/PR work is Phase 4).
  - **Phase scope respected:** no reviewer/validator/release/orchestration machinery was added
    (Phases 3–5).
  - **Exercised end-to-end (KAN-4):** `plans/KAN-4.md` was human-approved via `/jira-approve`
    (2026-09-20), and the implementer then delivered the approved plan — `health` controller, route,
    and request specs — tracked under `tasks/KAN-4/` with an `IMPLEMENTATION.md`. Verified in the
    Docker dev stack: `bin/rspec` 5 examples / 0 failures, `bin/rubocop` 28 files clean; all changes
    left uncommitted for human review.

- [x] **Phase 3 — Review & Validation** (completed, verified 2026-10-13)

  Reviewer and validator roles from §8 are implemented and exercised on KAN-5:

  - **Reviewer agent:** `.opencode/agents/reviewer.md` (subagent). Read-only w.r.t. code/tests/plans/Jira/Git; produces `review/<JIRA-KEY>/REVIEW.md` with verdict and findings.
  - **Validator agent:** `.opencode/agents/validator.md` (subagent). Read-only, runs verification per runbook and produces `validation/<JIRA-KEY>/VALIDATION.md` with requirement-level evidence matrix and test/lint/audit results.
  - **Commands:** `/jira-review <JIRA-KEY>` (`.opencode/commands/jira-review.md`) and `/jira-validate <JIRA-KEY>` (`.opencode/commands/jira-validate.md`).
  - **Artifacts:** `review/KAN-5/REVIEW.md` (verdict Approve) and `validation/KAN-5/VALIDATION.md` (verdict PASS; maps REQ-001..REQ-010/AC-001..AC-008, shows 21 examples/0 failures, rubocop/security clean).
  - **Authority boundaries:** both agents deny edits to code/tests/plans, deny git/PR operations, deny Jira writes, deny spawning subagents — consistent with Phase 3 (verification only). No release/orchestration introduced.

- [x] **Phase 4 — Git / PR / JIRA Workflow** (completed)

  The Release role from §1/§5/§9 is implemented and its authority boundary is enforced:

  - **Release agent:** `.opencode/agents/release.md` (subagent). Holds the Phase 4 release authority
    (create the feature branch, commit, push, open a PR, transition Jira) while denying edits to
    `app/**`, `spec/**`, `config/**`, `db/**`, `lib/**`, `plans/**`, `.opencode/**`, `opencode.json`;
    releasing with local `git` for the branch/commit/push and the GitHub MCP for the pull request, with
    guardrail denials for `git push origin main*`, `git push -u origin main*`, `git push --force*`/`-f*`,
    and `gh pr merge*`; denying the GitHub MCP merge tool (`github_merge_pull_request`); and denying
    spawning subagents (not an orchestrator).
  - **Command:** `/jira-release <JIRA-KEY>` (`.opencode/commands/jira-release.md`) routes a Jira key
    to the Release agent.
  - **Release gate:** refuses, mutating nothing, unless `plans/<JIRA-KEY>.md` is `Status: APPROVED`
    (with `Approved By`/`Approved At`) and `validation/<JIRA-KEY>/VALIDATION.md` reports
    `Verdict: PASS`.
  - **Release process:** the commit contains exactly the plan's Files Expected To Change/Added plus
    `plans/<JIRA-KEY>.md` plus `tasks/<KEY>/`, `review/<KEY>/`, `validation/<KEY>/`; branch
    `feature/<JIRA-KEY>` is created from `main` locally; the enumerated files are staged, committed in
    a single commit, and the branch is pushed with local `git`, then a pull request is opened against
    `main` via the GitHub MCP with a plan- and validation-derived body; the Jira issue is transitioned
    to `In Review` and the PR is linked via a comment; `release/<JIRA-KEY>/RELEASE.md` is written after
    the commit (uncommitted) recording the real commit SHA and PR URL.
  - **Unrelated changes:** proceed-and-exclude — unrelated working-tree changes are not committed or
    pushed, are left untouched, and are reported.
  - **Safety:** never pushes to `main`, never force-pushes, and never merges a PR (merging is
    human-only).
  - **Transport:** branch/commit/push are performed locally with `git`; the pull request is opened via
    the GitHub MCP (no `gh` CLI in the local environment); Jira updates use the Atlassian MCP.
  - **Phase scope respected:** no Phase 5 orchestration/chaining, no deployment/tagging/Kamal changes,
    no CI changes.

- [x] **Phase 5 — Orchestration** (completed)

  The orchestrator role from §10 and the `/orch` command compose the Phase 1–4 roles into a single
  pipeline:

  - **Orchestrator agent:** `.opencode/agents/orchestrator.md` (`mode: primary`). Holds no
    implementation, plan-content, Git, or Jira authority of its own: it may only launch the five
    existing role subagents (a `subagent` allow-list), write its own run-state artifact under
    `orchestration/`, and — in autonomous mode only — record the plan's approval block. Denials: edits
    everywhere except `orchestration/*` and (approval block only) `plans/*`; no
    `git commit/push/branch/checkout -b/switch -c/reset/rebase/merge` and no `gh pr`; no Atlassian or
    GitHub MCP access (both delegated).
  - **Command:** `/orch <JIRA-KEY> [mode]` (`.opencode/commands/orch.md`, `agent: orchestrator`).
    `mode` is optional and defaults to interactive; `auto` (or `--auto`) runs unattended.
    An unrecognized mode aborts before the pipeline starts.
  - **Pipeline:** plan → approve → implement → review → validate → release. Each stage is performed by
    its existing subagent with a prompt equivalent to `/jira-plan`, `/jira-implement`, `/jira-review`,
    `/jira-validate`, `/jira-release`; the orchestrator reads the produced artifact and enforces the
    approval and release gates before advancing.
  - **Interactive mode:** pauses at each gate; the human approves the plan via `/jira-approve <KEY>`.
  - **Autonomous mode:** auto-records the approval block as the invoking user (from
    `git config user.name`; pauses rather than inventing one if empty), loops implement → review →
    validate up to a bounded retry budget (2 remediation attempts), and pauses only on hard-stop
    conditions.
  - **Pause conditions:** spec drift, an ambiguity/conflict needing a human decision, reviewer
    `Needs Clarification`, exhausted retry budget (review still `Changes Requested` or validation not
    `PASS`), an unmet gate, pre-existing tracked-code changes in the working tree, a release conflict
    (branch/PR already exists), a tool/Jira/GitHub failure, or anything requiring an unauthorized
    destructive action.
  - **Run state & resumption:** `orchestration/<JIRA-KEY>/RUN.md` (`orchestration/TEMPLATE.md`)
    records the stage table, gate checks, approval method, remediation attempts, pause state, and
    outcome; a paused run resumes from it when `/orch <KEY> <mode>` is re-invoked.
  - **Human checkpoint preserved:** the pipeline stops before merge — merging the PR remains
    human-only (release never merges) — and the approved-plan invariant is recorded honestly
    (auto-approval names the invoking user) rather than silently skipped.
  - **Phase scope respected:** the orchestrator adds no new authorities; it sequences the existing
    Phase 1–4 roles and records state. No deployment/tagging/Kamal/CI changes.
