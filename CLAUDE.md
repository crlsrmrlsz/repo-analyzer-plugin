# Repo Analyzer Plugin

Rules for designing orchestration system

## Prompt Design Principles

All prompts for agents follow three design principles:

1. **Goal-based**: State an objective and success criteria, not a rigid procedure.
2. **Constrained**: Guardrails encode hard boundaries, not suggestions.
3. **Self-verifying**: Every agent validates findings for internal consistency before producing output.

Sonnet agents receive light procedural scaffolding — a recommended step sequence they may adapt or reorder — because Sonnet benefits from a default path while retaining flexibility.

## Orchestration Architecture

### Agent Types

- **Planners** (Opus): Decompose objectives, delegate to specialists or sub-planners, synthesize results. Never read source code.
- **Specialists** (Sonnet): Execute focused, well-scoped analysis tasks. Write findings to `.analysis/`.

The orchestrator is the root planner. It launches phase planners, which launch specialists (or sub-planners for complex tasks).

### Communication

- **Upward**: Every agent returns only a concise summary to its caller. Detailed findings go to `.analysis/` files.
- **Structural enforcement**: The planner layer insulates the orchestrator from specialist output. Prompt instructions enforce concise returns at every level.
- **Downstream context**: Agents receive file paths to prior `.analysis/` outputs, not their content.

### Task Decomposition

- Decompose into atomic subtasks modeled as a dependency DAG. Each subtask = one clear objective + one verification criterion.
- Subtasks must be MECE. Define explicit handoff contracts for inter-agent dependencies.
- Gate before routing: validate task feasibility before dispatching.
- Calibrate agent count and granularity to actual project complexity.
- Parallelize independent tasks; serialize dependent pipelines.

### Context Isolation

- Each sub-agent receives only what it needs: focused objective, relevant prior findings, and the minimum toolset.
- Target 50-60% context-window usage per agent to preserve analytical depth.

### Recursion Controls

- Depth tracked via `[depth:N/M]` markers in Task descriptions.
- PreToolUse hook enforces the maximum. Default: 3 levels.
- Sub-planners are the exception, not the norm. Most phases need only one planner.

## Verification

- Evaluate agent outputs on three axes: **relevance** (addresses the objective?), **correctness** (evidence is sound?), **completeness** (no gaps?).

## Failure Handling

- Low-confidence or truncated results: narrow scope, rephrase, and retry.
- Persistent failure: escalate to the user rather than guessing.
