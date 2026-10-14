Per-run orchestration artifacts produced by `/orch` (`.opencode/commands/orch.md`).

Each run writes `orchestration/<JIRA-KEY>/RUN.md` (based on `TEMPLATE.md`)
recording the stage-by-stage progress, gate checks, approval method, remediation
attempts, pause state, and final outcome. It is the audit trail and the resume
point for a paused run.
