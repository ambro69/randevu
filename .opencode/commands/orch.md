---
description: Orchestrate the full pipeline (plan → approve → implement → review → validate → release) for a Jira issue
agent: orchestrator
---

Orchestrate the spec-driven pipeline for Jira issue $1.

Requested mode: $2

Interpret the mode:

- empty or `interactive` → **interactive** mode
- `auto` or `--auto` → **autonomous** mode
- any other value → stop and report the invalid mode; do not start.

Then run the pipeline defined in the Orchestrator agent instructions: launch
`planner` → `implementer` → `reviewer` → `validator` → `release` as subagents, in
order, enforcing the approval and release gates between stages.

- **Interactive mode:** pause at each gate and wait for the human (in particular,
  the human approves the plan with `/jira-approve $1`).
- **Autonomous mode:** proceed unattended — auto-record the approval as the
  invoking user, loop implement → review → validate up to the retry budget, and
  pause only on the hard-stop conditions.

Keep the run state at `orchestration/$1/RUN.md` current, and if the run is paused,
resume from it when re-invoked (pass the same mode).
