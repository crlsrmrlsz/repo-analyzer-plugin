---
name: agent-task-design
description: This skill should be used when the orchestrator needs to write launch prompts for specialist agents, scope agent tasks, or decide what context to pass to subagents. Provides templates, examples, and heuristics for effective agent task briefs.
---

# Agent Task Design

Patterns for writing effective launch prompts that maximize agent performance within their context window.

## Launch Prompt Structure

Every agent launch prompt should include these elements in order:

1. **Objective**: Single sentence stating what to achieve (not how)
2. **Scope boundary**: Specific directories, modules, or files to focus on
3. **Output path**: Where to write detailed findings in `.analysis/`
4. **Prior context**: File paths to relevant `.analysis/` outputs from earlier phases (not summaries — let the agent read them directly)
5. **Constraints** (if any): Override or narrow the agent's default behavior for this specific task

## Heuristics

**Context budget**: The launch prompt consumes the agent's context. Every word you write is a word the agent can't use for analysis. Target 100-300 words per launch prompt.

**Pass paths, not content**: Reference `.analysis/` file paths instead of summarizing their content. The agent reads them in its own context — your summary wastes tokens in both contexts.

**One objective per agent**: If you need "map the auth module AND audit its security," launch two agents. Combining objectives produces shallow results on both.

**Scope by boundaries the agent can verify**: "Analyze the `src/auth/` directory" is better than "analyze the authentication system" — the agent can immediately verify the directory exists and enumerate its files.

**Name what you DON'T need**: If an agent has 7 analytical dimensions but you only need 3, say which 3. This prevents the agent from spending context on irrelevant analysis.

## Templates

### Structural Analysis (code-explorer)

```
Objective: Map the structural organization of [module/area].
Scope: [specific directories]
Output: .analysis/p2/[area]_structure.md
Prior context: Read .analysis/p1/scope_summary.md for tech stack context.
Focus on: module boundaries, entry points, dependency relationships.
Skip: execution flow tracing, business rule extraction.
```

### Behavioral Analysis (code-explorer)

```
Objective: Trace the [workflow name] execution flow from entry to output.
Scope: Start from [entry point file:line], follow the call chain.
Output: .analysis/p3/[workflow]_flow.md
Prior context: Read .analysis/p2/architecture_summary.md for module map.
Capture: data transformations, state changes, external calls, error paths.
```

### Database Analysis (database-analyst)

```
Objective: Inventory the [database type] schema and detect ORM drift.
Scope: Database connection via [method]. ORM models in [directory].
Output: .analysis/p3/data_layer.md
Prior context: Read .analysis/p1/scope_summary.md for tech stack.
Connection: [connection details or reference to settings].
```

### Audit Task (code-auditor)

```
Objective: Audit [specific dimension] for [scope area].
Scope: [directories or modules]
Output: .analysis/p4/[dimension]_audit.md
Prior context: Read .analysis/p2/architecture_summary.md and .analysis/p3/domain_summary.md for critical path context.
Priority: Focus on [critical paths identified in prior phases].
```

### Documentation Section (documentalist)

```
Section: [section name]
Audience: [target audience]
Inputs: [list of .analysis/ files to synthesize]
Output: .analysis/report/[section_name].md
```

## Anti-Patterns

- **Pasting file contents into the launch prompt**: Wastes orchestrator context AND agent context. Pass the file path instead.
- **Vague scope**: "Analyze the backend" forces the agent to spend context figuring out what "backend" means. Be specific: "Analyze `src/api/` and `src/services/`."
- **Multiple unrelated objectives**: "Map architecture AND find security issues" produces shallow results on both. Split into two agents.
- **Redundant instructions**: Don't repeat what's already in the agent's system prompt (e.g., "write findings to .analysis/" — the agent already knows this).
- **Over-specifying process**: Don't tell the agent HOW to investigate. It has domain expertise. Tell it WHAT you need to know.
