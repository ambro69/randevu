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
| Implementer |     maybe |         ✅ |           ✅ |         ✅ |      ❌ | later/controlled |       ❌ |  controlled |
| Reviewer    |     maybe |         ✅ |           ❌ |     maybe |      ✅ |                ❌ |       ❌ |           ❌ |
| Validator   |     maybe |         ✅ |           ❌ |         ✅ |      ❌ |                ❌ |       ❌ |           ❌ |
| Release     |     maybe |         ✅ |           ❌ |     maybe |      ❌ |                ✅ |       ✅ |           ✅ |

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
  - **Task tracking:** per-task status artifacts under `tasks/<JIRA-KEY>/` (layout:
    `tasks/TEMPLATE.md`) with an implementation summary `IMPLEMENTATION.md`.
  - **Output contract:** changes are confined to the working tree and left uncommitted for human
    review; no branches, commits, pushes, PRs, or Jira updates (those are Phase 4).
  - **Phase scope respected:** no reviewer/validator/release/orchestration machinery was added
    (Phases 3–5).
  - **Exercised end-to-end (KAN-4):** `plans/KAN-4.md` was human-approved via `/jira-approve`
    (2026-09-20), and the implementer then delivered the approved plan — `health` controller, route,
    and request specs — tracked under `tasks/KAN-4/` with an `IMPLEMENTATION.md`. Verified in the
    Docker dev stack: `bin/rspec` 5 examples / 0 failures, `bin/rubocop` 28 files clean; all changes
    left uncommitted for human review.

- [ ] Phase 3 — Review & Validation (Reviewer/Validator agents; not started — `review/` and
  `validation/` are placeholders only)

- [ ] Phase 4 — Git / PR / JIRA Workflow (Release agent; not started — no release automation)

  Documented future requirement (§12 — do not implement yet): per-ticket working-tree isolation via
  feature branches — plans already record a `Recommended Branch: feature/<JIRA-KEY>` (plans/
  `PLAN_TEMPLATE.md`); the Phase 4 release workflow should create the branch, commit the
  implementation, push, open the PR against `main`, and update Jira. Until then, a human creates the
  feature branch manually and agents work in the current working tree, branch-less by design.

- [ ] Phase 5 — Orchestration (not started — workflow runs as discrete manual commands)
