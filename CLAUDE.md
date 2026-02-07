  # Repo Analyzer Plugin

  Rules for designing and refining the orchestration system — command prompt, agent prompts, hooks, and communication mechanisms.

  ## Prompt Design Principles

  All prompts — orchestrator and agents — follow three design principles:

  1. **Goal-based**: State an objective and success criteria, not a rigid procedure. Agents choose their strategy based on what they find.
  2. **Constrained**: Guardrails encode hard boundaries, not suggestions. Constrain retrieval interfaces, not just tool lists — structured access methods are themselves guardrails against hallucination.
  3. **Self-verifying**: Every agent validates findings for internal consistency before producing output.

  Sonnet agents receive light procedural scaffolding — a recommended step sequence they may adapt or reorder — because Sonnet benefits from a default path while retaining flexibility. The orchestrator applies the same pattern at the phase level: each phase has an **Objective**, **Constraints**, and **"This phase succeeds when"** criteria.

  ## Orchestrator–Subagent Architecture

  ### Communication

  - One orchestrator spawns N specialist subagents.
  - Communication is file-based: agents write detailed findings to shared storage.
  - All agent outputs follow a predefined structured format so results are machine-parseable and comparable.
  - The orchestrator reads agent-produced summaries to detect gaps and adapt the plan. It never analyzes source code directly.

  ### Task Decomposition

  - Decompose into atomic subtasks modeled as a dependency DAG. Each subtask = one clear objective + one verification criterion. When in doubt, split further.
  - Subtasks must be MECE (mutually exclusive, collectively exhaustive). Define explicit handoff contracts for inter-agent dependencies.
  - Gate before routing: validate task feasibility (scope, data availability, access) before dispatching. Cheap pre-checks save expensive downstream failures.
  - Calibrate agent count and granularity to actual project complexity.
  - IMPORTANT: Invest most effort in decomposition quality and agent briefs. A well-scoped task with a clear objective is worth more than a polished agent prompt.

  ### Context Isolation

  - Each subagent receives only what it needs: focused objective, relevant prior findings, and the minimum toolset for its task.
  - Enrich briefs with resolved context: disambiguate references, pin versions, inject timestamps — subagents should never guess what "current" means.
  - Inject domain context per-subtask, not globally. Each agent gets only the domain knowledge, examples, and constraints relevant to its specific slice.
  - Target 50–60% context-window usage per agent to preserve analytical depth.
  - Parallelize independent tasks; serialize dependent pipelines where each agent builds on prior findings.

  ### Verification

  - Evaluate agent outputs on three axes: **relevance** (addresses the objective?), **correctness** (evidence is sound?), **completeness** (no gaps?). A response can be correct but incomplete, or complete but irrelevant — check all three.

  ### Failure Handling

  - Low-confidence or truncated results: narrow scope, rephrase, and retry.
  - Persistent failure: escalate to the user rather than guessing.