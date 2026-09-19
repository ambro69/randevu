---
name: jira-spec
description: Retrieve a Jira issue through the connected Atlassian MCP server and normalize it into the project's standard engineering specification format.
---

# Jira Specification Skill

## Purpose

This skill converts a Jira issue into the normalized specification
used by the spec-driven development workflow.

Jira is the authoritative source of the feature specification.

The output of this skill is consumed by planning and implementation
agents.

## Core Rules

1. Jira is the source of truth.
2. Never invent missing requirements.
3. Never silently reinterpret ambiguous requirements.
4. Preserve requirement and acceptance-criteria identifiers exactly.
5. Preserve the distinction between requirements and acceptance criteria.
6. Preserve technical constraints.
7. Preserve out-of-scope items.
8. Preserve testing requirements.
9. Preserve definition-of-done items.
10. Treat Jira metadata separately from the feature specification.
11. Retrieval must be read-only unless another workflow explicitly
   authorizes a Jira write operation.
12. Do not modify the Jira issue while processing it.

## Retrieval

When given a Jira issue key:

1. Retrieve the issue using the connected Atlassian MCP server.
2. Read the complete issue description.
3. Read relevant issue metadata.
4. Check for relevant comments if the workflow explicitly requests
   them.
5. Check for relevant custom fields.
6. Do not modify the issue.

The Jira issue may contain rich-text formatting. Convert it into
structured text while preserving semantic meaning.

## Normalized Structure

Normalize the issue into the following conceptual structure:

```yaml
ticket:
  key: string

  metadata:
    project:
      key: string
      name: string

    issue_type: string
    status: string
    priority: string
    labels: []

  specification:
    summary: string

    context: string

    goal: string

    requirements:
      - id: string
        description: string

    acceptance_criteria:
      - id: string
        given: string
        when: string
        then: string

    technical_constraints:
      - string

    out_of_scope:
      - string

    testing_requirements:
      - string

    definition_of_done:
      - string
