# Goal

Deep analysis of an unknown software application using all available information: codebase, repository history, and database access. The result is an interactive HTML report for an engineering team receiving this software from a contractor. They need evidence-based assessment of the product before acceptance — every claim must be verifiable, every finding backed by specific references.

The report must enable the team to:
- Understand what the application does, who uses it, main user journeys, how data is managed and transformed
- Understand software architecture at high level and in detail
- Know the technology stack
- Assess code quality comprehensively (patterns, naming, consistency, assumptions, architecture decisions) to understand inefficiencies, maintenance cost, and technical debt
- Know health status and risks with prioritized, actionable findings
- Understand development history and contributor dynamics
- Assess data quality, sizing, schema design, and ORM alignment

# Available Information

- **Codebase**: local filesystem at the working directory where analysis executes
- **Repository**: read access only — NEVER push anything
- **Database**: read access to one or more databases/schemas — connection details in `.claude/repo-analyzer.local.md`

# Available Tools

- `gh` / `glab` for repository platform features (preferred over raw CLI)
- MCP database servers: `dbhub` (MySQL), `SQLcl` (Oracle)
- Playwright for browser-based report validation
- Context7 for library/framework documentation lookup
- Standard code analysis: file search, content search, file reading, bash

# Constraints

- All analysis outputs written to `.analysis/` — never modify repository files, git state, or anything outside `.analysis/`
- Repository and database access is strictly READ ONLY
- High-impact claims must be corroborated from multiple sources
- Educational style throughout: explain technical terms on first use
- Evidence-based: every finding references specific `file:line` locations
- Confidence threshold: only report findings with >= 80% confidence

# Analysis Phases

Complete in sequence — early phases inform later ones.

## 1. Prerequisites

**Discover**: Repository access, tooling availability, database connectivity.

**Done when**: Access and tooling confirmed. `.claude/repo-analyzer.local.md` checked for pre-configured settings.

## 2. Scope & Complexity

**Discover**: Project type, tech stack, scale (files, lines, modules), complexity rating, key entry points.

**Done when**: Project type, primary technologies, scale, and complexity rating articulated. Downstream analysis calibrated to actual complexity.

## 3. Architecture

**Discover**: System boundaries, module organization, entry points, dependency relationships, architectural patterns, design decisions.

**Expected detail**:
- Module boundaries with inter-module dependencies mapped
- Execution flows traced through call chains with data transformations and state changes
- Framework conventions distinguished from custom implementations
- Confirmed findings vs inferences clearly labeled
- Diagram data (nodes/edges) produced for visualizations

**Validation**: Findings internally consistent — if 10 entry points identified but only 2 have dependencies mapped, gap must be explained. No implausible conclusions for the tech stack.

**Done when**: A developer could understand the project's structural organization without reading every file.

## 4. Domain & Business Logic

**Discover**: Domain model, business rules, API surface, core workflows, data access patterns.

**Expected detail**:
- Domain terms, core entities, primary workflows characterized with code references
- Data access layer mapped as distinct concern: repository/DAO patterns, query construction, caching, validation boundaries
- When database available: entity volumes and activity patterns corroborate or contradict the code-level domain model
- Diagram data for domain model and key workflows

**Validation**: Cross-reference code-discovered entities against database schema when available.

**Done when**: Domain terms, entities, workflows, and data layer characterized with evidence.

## 5. Health & Risk

The deepest phase. Requires multiple focused audits across five dimensions — not one broad sweep.

### Audit Dimensions

**5.1 Code Quality & Consistency**
- Consistency analysis across peer components (highest-signal dimension): compare 3-5 similar components for error handling, input validation, logging, naming, return value patterns — document both sides of each inconsistency
- Abstraction quality: single responsibility, interface cleanliness, god objects (>10 public methods or >300 lines), layering violations
- Pattern adherence: framework idiom compliance, ecosystem-foreign patterns

**5.2 Complexity & Maintainability**
- Top complexity hotspots by cyclomatic/cognitive complexity
- Change amplification: files across layers that must change for a typical new entity
- Local comprehensibility: can a module be understood without reading transitive dependencies?
- Coupling: concrete vs abstract dependencies, fan-in/fan-out risk indicators

**5.3 Technical Debt Forensics**
- TODO/FIXME/HACK inventory with git blame dates — debt older than 1 year is likely permanent
- Incomplete migrations: coexisting patterns for same concern (two ORMs, callbacks + promises)
- Suppressed linter/compiler warnings inventory with justification assessment
- Assumption archaeology: hardcoded values, concurrency assumptions, timezone/locale handling, encoding assumptions, scale limits, platform dependencies — each encoding undocumented business assumptions
- Each finding classified by blast radius: contained, spreading, or load-bearing

**5.4 Infrastructure**
- Test coverage by criticality-weighted business-logic paths, not just line percentage
- Test depth: behavior assertions + edge cases + failure paths, or just happy-path?
- CI/CD maturity: reproducible builds, rollback capability, environment parity
- Observability gaps: where would production failures go undetected?

**5.5 Security**
- Beyond OWASP top 10: logic flaws in auth/authorization patterns
- Exposed secrets including rotated ones still in git history
- Dependency risk by age and maintainer activity, not just known CVEs
- Trust boundaries where user input reaches sensitive operations without validation
- Absence of security controls is a finding, not a pass

### Cross-Correlation with Git History
- Contributor concentration risk and bus factor per module
- Correlate complexity hotspots with churn frequency (fragile + frequently touched = highest risk)
- Critical-path code owned by single contributor or never multi-reviewed

### Quality Requirements
- Severity: Critical > High > Medium > Low, weighted by blast radius (widespread > localized > isolated)
- Every finding answers: what is wrong, where (`file:line`), why it matters, what should have been done, how hard to fix
- Health score 0-100 with explicit scoring rationale
- Anti-rationalization: "no issues found" in any dimension requires documented search strategy; "best practices followed" requires comparison evidence; clean security on web apps is suspicious

**Validation**: Findings internally consistent (e.g., high test coverage + critical untested paths must be reconciled). No finding inconsistent with discovered architecture. A senior engineer would find no conclusion implausible.

**Done when**: Justified health score assigned, prioritized risk list with remediation actions produced. Maintenance burden characterized concretely — what operations are expensive and why.

## 6. Development History

**Discover**: Commit patterns, contributor dynamics, code evolution, change coupling, temporal intelligence.

**Expected detail**:
- Repository profile: age, total commits, velocity trend (acceleration/deceleration), active/dormant periods
- Contributor dynamics: authorship distribution, bus factor per critical area, knowledge concentration risks
- Hotspots: high-churn files with composite risk score (churn + ownership breadth + recency)
- Change coupling: file pairs co-changing with >70% correlation
- Temporal intelligence: migrations, refactoring cycles, incomplete transitions with start date and completion percentage
- All findings quantified with specific metrics, commit references, date ranges

**Validation**: Metrics internally consistent — if velocity increasing + contributors declining, explain the dynamic. Bus factor values plausible for project size.

**Done when**: Quantified risk profile with file/module specificity, bus factor scores, and hotspot rankings produced.

## 7. Data Layer

*Skip if no database access available.*

**Discover**: Schema structure, data volumes, business data profile, ORM alignment.

**Expected detail**:
- Complete schema inventory: tables, views, columns, constraints, indexes, foreign keys, stored procedures, triggers — organized per schema
- Volume analysis: largest tables, date ranges for temporal data, growth indicators
- Business data profiling via aggregate queries only (COUNT, MIN/MAX, DISTINCT): entity counts, user volumes, activity levels, data completeness
- ORM drift detection: three-column comparison (DB-only | Matched | ORM-only) per database, drift quantified as percentage
- Entity relationship map with foreign key and inferred relationships
- Credential safety: never log or expose database credentials in output

**Validation**: Findings consistent with application type (e.g., 50 tables but 3 ORM models — discrepancy explained). Multiple databases have cross-source relationships documented.

**Done when**: Data architecture understood without direct database access; ORM drift quantified and explained.

# Final Report

## Deliverable

Interactive HTML report at `.analysis/report/report.html`. All intermediate analysis in `.analysis/` feeds into this single deliverable.

## Tab Navigation

| Tab | Content |
|-----|---------|
| **Overview** | Executive summary, health indicator, key metrics, top risks — synthesized from all tabs |
| **Architecture** | System boundaries, module organization, dependency graphs, design patterns |
| **Domain** | Domain model, business rules, API surface, core workflows |
| **Data** | Schema documentation, ER diagrams, ORM drift, volume analysis |
| **Health** | Quality assessment, security posture, complexity, technical debt, consistency |
| **History** | Contributor dynamics, hotspots, change coupling, velocity trends |

Omit tab if its knowledge area was not analyzed (e.g., Data tab when no database access).

## Progressive Disclosure

Every tab uses three layers:

1. **Executive** (always visible): 2-3 sentence summary, health indicator (Green/Yellow/Red), key metric. Scanning executive layers across all tabs = complete overview in 2 minutes.
2. **Structural** (collapsible "Patterns & Diagrams"): Diagrams, pattern tables, relationship maps. Developer understands architecture without reading source.
3. **Evidence** (collapsible "Detailed Findings"): Full `file:line` reference tables, raw metrics, per-component findings, confidence scores, severity ratings. Technician can act on specific issues.

## Interactive Visualizations

**Mermaid** (CDN v11 + svg-pan-zoom 3.6.1):
- Architecture diagrams (C4), ER diagrams, sequence diagrams, flowcharts
- Zoomable and pannable

**Cytoscape.js** (CDN v3.30.4, COSE force-directed layout):
- Module dependency graphs, change coupling graphs, contributor knowledge maps, data volume graphs
- Draggable nodes, 500px container height, responsive width
- 5-15 nodes per diagram — split larger graphs

## Style

- Educational: every technical term explained on first use
- Severity color coding: Critical=red, High=orange, Medium=yellow, Low=blue
- Striped table rows, monospace for code paths and `file:line`
- Responsive layout (stack tabs on mobile)
- Print-friendly (expand all collapsible sections, hide tab bar)

## Report Validation

Browser-based validation required:
- Tab navigation renders and switches content correctly
- All diagrams render without errors
- No console errors
- All sections accessible with content visible
