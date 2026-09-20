---
description: Create a Jira ticket from a requirement via guided, codebase-aware questions
---

Load the `jira-create` skill and use it to turn the user's requirement
into a Jira ticket.

Requirement: $ARGUMENTS

If $ARGUMENTS is empty, ask the user to describe the requirement before
starting.

Follow the skill's workflow:

1. Ground the requirement in the repository (architecture, routes,
   models, specs, existing plans/tickets; see `AGENTS.md`).
2. Ask targeted clarifying questions until the scope, behavior,
   constraints, and testing expectations are clear.
3. Draft the specification in the `plans/JIRA_TEMPLATE.md` structure
   (Summary, Context, Goal, Requirements REQ-xxx, Acceptance Criteria
   AC-xxx in Given/When/Then, Technical Constraints, Out of Scope,
   Technical Notes, Testing Requirements, Definition of Done).
4. Play the full draft back and get explicit user confirmation.
5. Ask for any missing metadata: issue type, priority, labels, and
   optional assignee — verify the issue type is valid for the project.
6. Create the ticket in Jira via the Atlassian MCP server
   (`createJiraIssue`), then report the ticket key/URL and the next
   step (`/jira-plan <KEY>`).

Rules:

- Only create the ticket after the user has confirmed the finalized
  requirements and metadata.
- Creating the ticket is the only Jira write this workflow performs — do
  not modify other issues or transition statuses.
- Do not invent requirements the user did not agree to.
- If the requirement conflicts with the codebase, surface it to the user
  rather than silently adapting.