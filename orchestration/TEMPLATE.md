# {{JIRA_KEY}} — Orchestration Run

Status: {{RUNNING | PAUSED | COMPLETED | ABORTED}}
Mode: {{interactive | autonomous}}
Jira Issue: {{JIRA_KEY}}
Started: {{ISO-8601 UTC}}
Updated: {{ISO-8601 UTC}}
Invoked By: {{git config user.name}}

## Pipeline

| # | Stage | Agent | Status | Started | Finished | Artifact / Result |
|---|-------|-------|--------|---------|----------|-------------------|
| 1 | Plan | planner | pending | | | plans/{{JIRA_KEY}}.md |
| 2 | Approve | (gate) | pending | | | Status + Approved By/At |
| 3 | Implement | implementer | pending | | | tasks/{{JIRA_KEY}}/IMPLEMENTATION.md |
| 4 | Review | reviewer | pending | | | review/{{JIRA_KEY}}/REVIEW.md |
| 5 | Validate | validator | pending | | | validation/{{JIRA_KEY}}/VALIDATION.md |
| 6 | Release | release | pending | | | release/{{JIRA_KEY}}/RELEASE.md |

Stage `Status`: `pending | in_progress | done | failed | skipped`.

## Remediation Attempts

| Attempt | Trigger | Stages Re-run | Outcome |
|---------|---------|---------------|---------|
| | | | |

## Gate Checks

- Approval gate: pending — plan Status / Approved By / Approved At
- Release gate: pending — plan APPROVED + validation `Verdict: PASS`

## Approval

- Method: {{human (/jira-approve) | auto (autonomous) }}
- Approved By: {{name}}
- Approved At: {{timestamp}}

## Preflight

- Working tree snapshot: {{clean | pre-existing changes}}
- Pre-existing unrelated changes: {{list, or "none"}}

## Pause

- Reason: {{reason}}
- Resume from stage: {{stage}}
- Required to continue: {{what the human must do}}

## Outcome

- Release: branch {{feature/JIRA-KEY}} — commit {{SHA}} — PR {{URL}}
- Jira transition: {{To Do → In Progress → In Review}}
- Excluded unrelated changes: {{list, or "none"}}

## Notes

- {{anything worth recording}}
