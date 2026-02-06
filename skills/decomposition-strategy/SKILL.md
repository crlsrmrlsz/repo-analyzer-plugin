---
name: decomposition-strategy
description: This skill should be used when the orchestrator needs to decide how to break a codebase into agent tasks based on project type, scale, and complexity. Provides decomposition patterns, agent-count heuristics, and common anti-patterns.
---

# Decomposition Strategy

Patterns for breaking analysis phases into agent tasks based on project characteristics.

## Decision Flow

1. Can a single agent cover the entire phase scope without context exhaustion? → Use one agent.
2. If not, identify the natural boundaries: modules, layers, services, or concern areas.
3. Map dependencies between sub-tasks. Parallelize independent ones, chain dependent ones.
4. Assign one agent per sub-task. Each gets a clear objective and bounded scope.

## Patterns by Project Type

### Small Project (<10k LOC, <5 modules)

- **Phase 2 (Architecture)**: Single code-explorer covers the entire codebase
- **Phase 3 (Domain)**: Single code-explorer + database-analyst (if DB exists)
- **Phase 4 (Health)**: Single code-auditor + git-analyst in parallel
- **Phase 5 (Docs)**: Single documentalist, possibly 2 sections per launch
- **Total agents**: 4-6 across all phases

### Monolith (10k-100k LOC, layered architecture)

- **Phase 2**: Decompose by layer — one explorer per layer (API, business logic, data, infrastructure)
- **Phase 3**: Decompose by domain area — one explorer per bounded context or major feature area
- **Phase 4**: Split auditor by concern (security + testing vs. complexity + debt). Git-analyst runs independently
- **Phase 5**: One documentalist per section type
- **Total agents**: 8-15 across all phases

### Microservices / Multi-Module

- **Phase 2**: One explorer per service/module for internal structure, plus one explorer for inter-service communication patterns
- **Phase 3**: One explorer per service for domain logic, one database-analyst per data store
- **Phase 4**: One auditor per service (or group small services). Git-analyst covers the full repo
- **Phase 5**: One documentalist per section type
- **Total agents**: 12-25 depending on service count

### Monorepo

- **Phase 2**: One explorer for workspace structure, then one per significant package
- **Phase 3**: Group related packages by domain for explorer assignments
- **Phase 4**: Prioritize — audit high-risk packages first, skip generated code
- **Total agents**: Scale with package count, cap at 20 per phase

## Agent Count Heuristics

| Complexity (from Phase 1) | Agents per phase | Total across phases |
|---------------------------|-----------------|---------------------|
| Simple | 1-2 | 4-8 |
| Moderate | 2-4 | 8-16 |
| Complex | 3-6 | 15-25 |

**Upper bound**: If you're launching more than 6 agents in a single phase, the sub-tasks are probably too granular. Each agent launch costs orchestrator context for the summary — keep it manageable.

## Common Anti-Patterns

- **Over-decomposition**: Launching 5 agents for a 3k LOC project wastes orchestrator context on coordination overhead. Scale to actual complexity.
- **Overlapping scope**: Two agents both analyzing `src/auth/` will produce redundant findings and potential contradictions. Each file belongs to exactly one agent per phase.
- **Missing coverage**: After decomposition, verify that every significant directory is assigned to an agent. Gaps produce blind spots in the analysis.
- **Ignoring dependencies**: Launching Phase 3 agents before Phase 2 completes means they have no architecture context to build on. Respect the phase dependency chain.
- **Equal-size splitting**: Don't split by equal file count. Split by logical boundaries. A 500-line core module may need its own agent while 5,000 lines of generated code need none.

## Resilience

- **Agent returns shallow output**: Likely hit context limits. Relaunch with narrower scope (split in two).
- **Agent returns low confidence**: The scope may be too broad or the codebase too unfamiliar. Try a targeted follow-up with specific questions.
- **Contradictions between agents**: Don't average — investigate. Launch a verification agent scoped to the contradiction.
- **Agent finds nothing**: Before accepting "not found," check whether the scope was correct. The feature may live in a different directory than expected.
