# Repository Analysis — Task Specification

Perform a comprehensive, evidence-based analysis of an unknown software repository. The analysis must be read-only — no repository files are modified, no git state is altered. All findings are written to `.analysis/` and culminate in a self-contained HTML report.

## Configuration Sources

Analysis settings and database connectivity are configured through several files. During prerequisites, check each source and use what is available.

### Analysis Preferences — `.claude/repo-analyzer.local.md`

Per-project settings file with YAML frontmatter. Template at `templates/repo-analyzer.local.md`.

Expected contents:
- **Repository access**: `vcs_platform` (github | gitlab | git | svn), `remote_url`
- **Database access**: `db_enabled`, `db_type` (postgres | mysql | mariadb | sqlite | sqlserver | oracle), `db_connection` (dbhub | cli), `db_host`, `db_port`, `db_name`, `db_user`
- **Analysis preferences**: `focus_areas` (array of areas to limit analysis to), `exclusions` (directories to skip), `output_format` (detailed | summary)
- **Markdown body**: Free-form project notes providing context (e.g., "monorepo with 3 services", "legacy migration in progress")

Passwords are never stored in this file — they come from environment variables or encrypted credential stores.

### Database Connectivity — MCP Servers

Two MCP database server integrations are available. Both are configured in the target project's `.mcp.json`. The analysis uses whichever is configured; both may coexist.

**DBHub** (`mcp__dbhub__*` tools)
- Configured via `.mcp.json` entry pointing to a `dbhub.toml` file
- `dbhub.toml` defines data sources with DSN connection strings and tool permissions
- Template at `templates/dbhub-oracle-example.toml`
- Supports PostgreSQL, MySQL, MariaDB, SQLite, SQL Server, and Oracle (12c+ via thin client; 11g via Docker thick-client image)
- Available tools: `execute_sql`, `search_objects`
- Setup guide: `templates/oracle-setup.md` (covers `dbhub.toml`, `.mcp.json`, CLI fallback, and verification)

**Oracle SQLcl** (`mcp__sqlcl__*` tools)
- Configured via `.mcp.json` entry pointing to the SQLcl binary with `-mcp` flag
- Credentials stored encrypted in `~/.dbtools/` (never in config files)
- Saved connections are auto-discovered by the MCP server
- Available tools: `list-connections`, `connect`, `disconnect`, `run-sql`, `run-sqlcl`
- Setup guide: `templates/oracle-sqlcl-mcp-setup.md` (covers Java prerequisites, SQLcl installation, connection saving, JDBC string conversion, troubleshooting, `.mcp.json` configuration, and security practices)

**CLI Fallback**
When no MCP database server is configured, database analysis can fall back to CLI tools (`psql`, `mysql`, `sqlplus`, etc.) with user confirmation before execution.

### Multi-repo Workspaces

For workspaces containing multiple repositories, organize `.analysis/` output by repository name to keep findings separated.

## Analysis Phases

The analysis proceeds through six knowledge dimensions. Earlier phases inform later ones, but they are not a rigid pipeline — findings from any phase may refine understanding in another.

### 1. Prerequisites

Establish access, tooling, and scope. Confirm repository access, verify database connectivity when applicable, and confirm available tooling. Present the analysis plan and wait for user confirmation before proceeding.

**Complete when**: Repository access confirmed, tooling available, database connectivity verified (if applicable), and user has confirmed scope.

### 2. Scope & Complexity

Determine what this project is — type, technology stack, scale, and complexity. Calibrate all subsequent analysis to actual project complexity.

**Complete when**: Project type, primary technologies, approximate scale, and complexity rating are articulated.

### 3. Architecture

Discover how the system is organized — boundaries, entry points, module relationships, and structural patterns.

**Complete when**: A new developer could understand the project's structural organization without reading every file.

### 4. Domain & Business Logic

Discover what the system does — domain model, business rules, API surface, and core workflows. Characterize the data access layer: repository patterns, query strategies, caching. Cross-validate findings against multiple sources; inconsistencies are findings, not errors. When database access is available, use code-identified entities and workflows to target business data profiling: entity populations, time frames, user volumes, and activity patterns — turning abstract domain concepts into quantified operational reality.

**Complete when**: Domain terms understood, core entities and relationships identified, primary workflows mapped, data access layer characterized, and (when database access exists) operational data profiled with aggregate queries.

### 5. Health & Risk

Assess quality and security posture — vulnerabilities, technical debt, maintainability. Characterize maintenance burden in concrete terms (what operations are expensive and why), not just metric counts. Cross-file consistency, incomplete migrations, and change amplification are high-value signals. Report only findings with confidence >= 80%.

**Complete when**: Justified health score (0–100) assigned, prioritized risk list with evidence and remediation actions produced.

### 6. Documentation

Synthesize all prior findings into a navigable report — from system overview to implementation detail — packaged as self-contained HTML with embedded styling, navigation, and pre-rendered diagrams. No external dependencies.

**Complete when**: Reader can navigate from "what is this?" to any depth of detail, HTML is self-contained, all claims trace to evidence in `.analysis/`.

---

## Specialized Task Types

Five types of focused analytical work support the phases above. Each produces evidence-based findings written to `.analysis/`.

---

### Code Exploration

Deep structural and behavioral analysis of source code, producing evidence-grounded findings that reveal internal logic beyond surface-level summaries. Every claim references specific `file:line` locations.

**Succeeds when**: Findings provide enough evidence-grounded detail that a developer can act on them without re-reading the analyzed source code.

#### Principles

- **Source code is ground truth**: Analyze source files, not generated artifacts. If documentation contradicts code, follow the code. When encountering ambiguity, navigate to relevant definitions rather than assuming.
- **Evidence over inference**: Every claim must reference specific `file:line` locations. Distinguish confirmed findings from inferences from assumptions.
- **Systematic coverage**: Use comprehensive search strategies, not spot-checking. Do not report "not found" without exhausting reasonable alternatives — pivot directories, refine queries, try different file patterns.
- **Context-aware**: Consider project type, language idioms, and framework conventions when interpreting patterns.

#### Work Areas

**Discovery**
Identify entry points, top-level structure, and configuration. Establish what exists before diving deep.
- Succeeds when: Map of entry points, top-level directories, and configuration files is sufficient to guide deeper exploration.

**Structural Mapping**
Map module boundaries, directory organization, and dependency relationships. Identify architectural patterns and distinguish framework conventions from custom implementations.
- Succeeds when: Module boundaries, dependency relationships, and which patterns are framework-imposed vs. custom are described.

**Behavioral Tracing**
Follow execution flows through call chains. Track data transformations, state changes, side effects, and error handling paths. When the data access layer is in scope, map it as a distinct concern: repository/DAO patterns, query construction, caching strategies, and data validation boundaries.
- Succeeds when: Primary execution flows are traced with `file:line` references for each step in the chain, and when data access is in scope, data layer patterns are cataloged with entity mappings.

**Pattern Extraction**
Identify business rules, validation logic, decision points, and design decisions. Distinguish confirmed patterns from inferred ones.
- Succeeds when: Each pattern is classified as confirmed or inferred and backed by specific code references.

**Synthesis & Validation**
Cross-check findings for internal consistency before writing output:
- Are findings internally consistent? (e.g., 10 entry points identified but only 2 have dependencies mapped — explain the gap)
- Is any finding inconsistent with the overall architecture discovered?
- If a core component is absent (no tests, no config, no database layer), explain why.
- Would a developer familiar with this tech stack find any conclusion implausible?

#### Deliverables

- Structural maps: module boundaries, entry points, dependency graphs
- Execution flows: call chains with data transformations and state changes
- Patterns: architectural decisions, business rules, design rationale
- Files essential for understanding the analyzed scope
- All findings include `file:line` references and confidence levels

---

### Database Analysis

Reverse-engineer data architectures by analyzing live databases and application code. Provides a complete picture of the data layer — which may span multiple databases, schemas, or storage technologies. Maps what exists, how it's structured, where business logic lives, and how database reality compares to application models. Supports PostgreSQL, MySQL, MariaDB, SQLite, SQL Server, and Oracle.

**Succeeds when**: Findings are detailed enough to understand the data architecture without direct database access, and any drift between database and application models is quantified and explained.

#### Principles

- **Strict read-only access**: Never execute INSERT, UPDATE, DELETE, DROP, ALTER, or TRUNCATE. Use only SELECT, SHOW, DESCRIBE, EXPLAIN with LIMIT on data sampling. If write access is available, refuse to use it.
- **Source code and schema are ground truth**: If application models contradict database schema, report both — the discrepancy is a finding, not an error to resolve.
- **Credential safety**: Never log, echo, or expose database credentials in output. Sanitize connection details in all reports.

#### Work Areas

**Establish Database Access**
Identify all database technologies in use and establish read-only connectivity to each. Prefer MCP database tools (DBHub or SQLcl) when configured in `.mcp.json`. Fall back to CLI tools only with user confirmation. Connection details come from `.claude/repo-analyzer.local.md`, `dbhub.toml`, or SQLcl saved connections in `~/.dbtools/` (see Configuration Sources above).
- Succeeds when: Every database and schema is identified, with a read-only query path established — or specific guidance documented for why access failed.

**Schema Discovery & Cataloging**
Produce a complete inventory of database structure — schemas, tables, views, columns, constraints, indexes, foreign keys, stored procedures, functions, and triggers.
- Succeeds when: Every database object is cataloged and relationships between objects are mapped.

**Volume & Distribution Analysis**
Assess the scale and shape of the data — how much exists, how it's distributed, and where temporal patterns indicate growth or activity.
- Succeeds when: Data volume is characterized, largest and most active tables are identified, and date ranges for temporal data are estimated.

**Business Data Profiling**
Characterize data from a business perspective — entity counts, user volumes, date ranges, activity levels, and data completeness. Use read-only aggregate queries (COUNT, MIN/MAX dates, DISTINCT values) on key business tables. When prior code analysis findings are available, use code-identified entities, workflows, and data access patterns to prioritize profiling targets — validate code assumptions against live data.
- Succeeds when: The following questions are answered: How many users/customers? What time period does the data cover? What are the volumes of core business entities? What is the activity level (recent vs. historical)? When code analysis is available, do entity volumes and activity patterns corroborate or contradict the domain model found in code?

**Application Model Analysis**
Build a parallel inventory of the data layer as the application sees it — model definitions, declared types, validations, associations, and migration history.
- Succeeds when: Every application model is cataloged with its table mapping, `file:line` reference, validations, and associations.

**Drift Detection & Validation**
Compare database reality against application models to surface discrepancies — missing tables, extra tables, column mismatches, constraint gaps, and database objects unknown to the application.

Before finalizing, verify:
- Are findings internally consistent? (e.g., 50 tables but only 3 application models — explain the discrepancy)
- Does the schema structure make sense for the application type?
- If no stored procedures or triggers exist, is that consistent with the tech stack?
- Do drift findings have plausible explanations?
- If multiple databases exist, are findings organized per-source with cross-database relationships documented?

- Succeeds when: A three-column comparison (DB-only | Matched | App-only) per database is produced, drift is quantified as a percentage, and each discrepancy is explained.

#### Deliverables

- Connection summary: per-database type, version, host (sanitized), connection method
- Schema inventory: all tables with column count, row count, size — organized by schema
- Entity relationship map: foreign key and inferred relationships with confidence levels
- Volume analysis: largest tables, date ranges for temporal tables, growth indicators
- Business data profile: entity counts, user volumes, date ranges, activity levels
- Application model inventory: each model with table mapping, `file:line`, validations, associations
- Drift report: three-column comparison with specific mismatches
- Business logic catalog: stored procedures, triggers, constraints with purpose
- Query log: every query executed with purpose, execution time, rows returned
- Files essential for understanding the data layer

---

### Code Auditing

Systematic health assessment across multiple dimensions of code quality. Produces a prioritized assessment that distinguishes critical risks from noise, backed by specific `file:line` references and quantified evidence. Never speculates — reports only what can be proven.

**Succeeds when**: A justified health score (0–100) is assigned and a prioritized risk list is produced where every finding has evidence, severity, and actionable remediation.

#### Principles

- **Source code is ground truth**: Audit source files, not generated artifacts or documentation claims.
- **Evidence over inference**: Every finding must reference specific `file:line` locations.
- **Context-aware**: Assess against the project's own conventions, not abstract ideals.
- **Exhaust alternatives**: If standard patterns don't apply (e.g., tests in unconventional locations, custom CI systems), investigate alternative directories and project-specific conventions before reporting "not found."

#### Confidence & Severity Framework

**Confidence filtering**: Rate each finding 0–100. Only report findings >= 80. Below 50: discard. 50–79: gather more evidence or omit.

**Severity**: Critical (security, data loss, production-breaking) > High (performance, major maintainability) > Medium (quality, debt) > Low (style, optimization). Weight by blast radius: widespread > localized > isolated. Prioritize Critical + Widespread first.

#### Work Areas

**Infrastructure Scan**
Establish the project's quality infrastructure before auditing code quality.

- *Test Coverage*: Determine testing posture — infrastructure, coverage level, critical path gaps. Use coverage reports and test files as primary evidence; when absent, infer from test file presence and assertion density. Distinguish "untested" from "unable to determine." Assess test depth: do tests assert specific behavior and cover edge cases and failure paths, or only confirm happy-path execution?
- *CI/CD & Deployment*: Evaluate build, test, and deployment pipeline — automation coverage, test integration, deployment safeguards, secrets management. Use pipeline definitions and deployment scripts as evidence, not external CI platform state.
- *Observability*: Assess monitoring and production readiness — logging coverage, error handling patterns, metrics instrumentation. Identify blind spots where failures would be difficult to diagnose.

Succeeds when: The project's quality infrastructure — test coverage level, CI/CD maturity, and observability gaps — is characterized with specific file references.

**Deep Audit**
Use infrastructure context from the scan to focus on areas with weakest coverage and highest risk.

- *Code Quality*: Evaluate code organization, naming consistency, abstraction quality, error handling patterns, separation of concerns, and adherence to language/framework idioms. Assess function complexity, parameter counts, return value clarity, and test-to-code correspondence. Identify patterns that increase cognitive load for maintainers — inconsistent conventions, unclear control flow, or responsibilities split across unrelated modules. Compare the same concern (error handling, validation, logging) across peer components — inconsistency is a stronger signal than any individual issue. Check for suppressed linter warnings (eslint-disable, @SuppressWarnings, # noqa, noinspection) as evidence of systematic shortcutting.
- *Security Posture*: Identify vulnerabilities, exposed secrets, dependency risks, and weak auth patterns. Assess input boundaries, authentication flows, cryptographic usage, and dependency manifests. Distinguish confirmed vulnerabilities from potential risks.
- *Complexity & Maintainability*: Identify areas hardest to understand and modify — complexity hotspots, duplication, coupling. Measure from code (nesting depth, function length, file size, cross-module dependencies). Assess against the project's own conventions, not abstract ideals. Estimate change amplification: how many files across how many layers must change for a typical new entity or endpoint? Assess local comprehensibility — whether a module can be understood without reading its transitive dependencies.
- *Technical Debt*: Inventory maintenance burden — explicit markers (TODO/FIXME/HACK), deprecated API usage, dead code, pattern inconsistencies. Distinguish intentional tradeoffs from unintentional drift. Look for incomplete migrations — coexisting patterns for the same concern (two ORMs, callbacks alongside promises) indicate abandoned transitions. Characterize significant debt as concrete maintenance scenarios, not counts. Use git blame on debt markers to date them.
- *Documentation Accuracy*: Assess whether existing docs (README, API docs, setup guides) accurately reflect the codebase. Identify specific discrepancies with file references for both documentation and source.

Succeeds when: Every audit dimension has findings with confidence scores, severity ratings, and `file:line` evidence — or a justified explanation for why no issues were found.

**Validation**
Before finalizing, verify:
- Are findings internally consistent? (e.g., high test coverage reported alongside critical untested paths — reconcile)
- Is any finding inconsistent with the architecture? (e.g., flagging "no input validation" in a framework that handles it automatically)
- If no security issues found, is that plausible for this application type?
- Would a security engineer or senior developer find any conclusion implausible?

#### Deliverables

- Overall health score (0–100) with scoring rationale
- Per-dimension findings with severity and evidence
- Test coverage summary (files tested vs. untested)
- Security issues with severity classification
- Complexity hotspots (top 5–10 files/functions)
- Change amplification estimate (files/directories touched for a typical new feature)
- Technical debt inventory with narrative characterization of highest-burden items
- Code quality assessment
- Prioritized action items
- Files essential for understanding codebase health

---

### Git History Analysis

Extract actionable intelligence from version control metadata — the human and temporal dimensions of a codebase. Quantify who built it, how it evolved, where knowledge is concentrated, and which areas carry the highest maintenance risk. Supports Git, GitHub, GitLab, and SVN.

**Succeeds when**: A quantified risk profile is produced with specific files/modules, bus factor scores, hotspot rankings, and actionable recommendations for maintainers.

#### Principles

- **Metadata only**: Operate exclusively on version control metadata — logs, diffs, blame, remote info. Never read full source file contents or assess code quality from file contents.
- **Quantify everything**: Every finding must be backed by specific metrics, commit references, date ranges, and file paths. No qualitative claims without quantitative support.
- **Platform awareness**: Detect and adapt to the hosting platform (GitHub, GitLab, Bitbucket, plain Git, SVN) and use platform-appropriate tooling for enhanced metadata.
- **Adapt to anomalies**: If the repository uses unconventional branching, squashed merges, or sparse history, adapt methodology. If metrics produce implausible results (e.g., bus factor of 1 for a 50-contributor project), investigate rather than reporting at face value.

#### Work Areas

**Repository Profile**
Characterize the repository's age, activity patterns, and development velocity — establishing baseline context for all other analysis.
- Metrics: Total commits, active timespan, commit frequency timeline, active/dormant periods, velocity trend (acceleration or deceleration).
- Succeeds when: The repository's lifecycle is described and its overall scale is quantified.

**Contributor Dynamics**
Map the human dimension — who built what, how knowledge is distributed, and where single-maintainer risk exists.
- Metrics: Authorship distribution, bus factor per critical area, contributor concentration, contributor churn patterns.
- Succeeds when: Authorship distribution is quantified, bus factor for critical areas is calculated, and knowledge concentration risks are flagged.

**Hotspots & Change Coupling**
Identify files and file-pairs with highest maintenance risk — concentrated change, overlapping ownership, and implicit coupling.
- Metrics: Change frequency (normalized churn rate relative to repo age), hotspot risk score (composite: churn + ownership breadth + recency), change coupling (co-occurrence > 70% correlation).
- Succeeds when: Top risk files are ranked with quantified scores and coupled file-pairs suggesting hidden architectural dependencies are identified.

**Temporal Intelligence**
Detect major evolutionary events — migrations, refactoring cycles, dependency shifts, and periods of rapid change or stability. Flag transitions that appear incomplete — a new pattern introduced but the old one persisting in recent commits — with approximate start date and completion percentage.
- Succeeds when: Key inflection points are identified and organic growth is distinguished from deliberate restructuring.

**Risk Assessment & Validation**
Synthesize all findings into a quantified risk profile — single points of failure, abandoned code areas, commit quality patterns, and maintainability trajectory.

Before finalizing, verify:
- Are metrics internally consistent? (e.g., velocity increasing + contributor count declining — explain the dynamic)
- Do hotspot rankings make sense given the project's architecture?
- If bus factor is extremely low or high, does the explanation hold up?
- Would a project maintainer recognize the characterization?

- Succeeds when: A prioritized risk list with quantified scores and actionable recommendations is produced.

#### Deliverables

- Repository profile: age, total commits, commit frequency timeline, active/dormant periods
- Velocity analysis: commits per week/month trend, acceleration/deceleration
- Contributor dynamics: authorship distribution, bus factor methodology, contributor timeline
- Hotspots: high-churn files with change frequency, contributor count, risk score
- Change coupling: file pairs with correlation scores
- Risk assessment: single-maintainer files, abandoned areas, high-risk zones
- Recommendations: prioritized actions based on findings
- Files essential for repository health: top 5–10 by risk/activity

---

### Documentation Synthesis

Transform raw analysis findings into structured, navigable documentation that guides readers from system overview to implementation detail. Organize by knowledge depth — readers understand what the system does before how it's built, and how it's built before its health status.

**Succeeds when**: A reader can start from "what is this system?" and navigate to any level of detail they need, with each level self-contained and linked to deeper exploration.

#### Principles

- **`.analysis/` is the sole source**: Never read source code. Never invent details not in analysis files. Cross-reference across `.analysis/` before flagging gaps — only flag after confirming no other file addresses the missing information.
- **Flag gaps, don't fill them**: When information is missing, mark it with "Analysis Gap:" prefix. Never speculate to fill holes.
- **Terminology consistency**: Use the same names for components, modules, and entities that analysis files use. Do not rename or reinterpret.

#### Progressive Disclosure

Structure content by topic depth — readers navigate from overview to detail, stopping wherever they have enough understanding. Each page is self-contained.

- **Overview level**: Purpose, context, key takeaways — scannable in 2–3 minutes
- **Structural level**: Diagrams, patterns, relationships, boundaries — navigable via visuals and headers
- **Detail level**: Specific files, configurations, metrics, evidence — searchable via tables and references

#### Navigation & Linking

Every page participates in a navigation structure:
- **Downward links**: Point to pages with more detail on subtopics
- **Upward links**: Return to the parent overview or report index
- **Cross-references**: Link to related topics at the same depth level
- **Evidence links**: Link to summaries for context and to detailed files for evidence, at the point in the report where each is relevant

Keep page sizes manageable — split rather than scroll. Use clear section headers as navigation anchors.

#### Diagrams

Use Mermaid diagrams for visual communication. Select appropriate types (C4 for architecture, ER for domain models, sequence for workflows, flowcharts for decisions).

Constraints: 5–12 nodes per diagram (max 20), all elements labeled with names from analysis files, consistent naming throughout, valid syntax, brief annotations for non-obvious relationships.

#### Report Sections

Include only sections where relevant findings exist.

**System Overview**
- What the system does (1–2 paragraphs)
- High-level architecture snapshot (diagram or description)
- Key technologies and scale indicators
- Health assessment summary (Green/Yellow/Red with rationale)

**Domain & Workflows**
- Core entities and relationships (ER or domain diagram)
- Data access layer patterns (repositories, query strategies, caching)
- User-facing capabilities and API surface
- Key workflows from entry to output
- Business rules extracted from code
- Operational profile — when data profiling exists: entity counts, user volumes, activity levels, and date ranges that ground domain concepts in quantified reality

**Architecture**
- C4 Context + Container diagrams
- Module boundaries and patterns identified
- Key design decisions with rationale
- Entry points and component relationships

**Data Architecture** — *when database was analyzed*
- Schema documentation (tables, relationships, types)
- Data flow diagram
- Storage patterns, volume indicators
- Application model drift summary (if applicable)

**Integration Map** — *when significant integrations exist*
- External dependencies table (name, purpose, version)
- Integration diagram with communication patterns
- Authentication approaches per integration

**Infrastructure & Deployment** — *when deployment info exists*
- Deployment topology and environments
- CI/CD pipeline overview
- Runtime configuration and dependencies

**Health & Risk Register**
- Prioritized risk table: Risk, Category, Severity, Blast radius, Remediation, Effort
- Top risks with business impact
- Quick wins vs. strategic improvements
- Maintenance burden narrative: what concrete development operations are expensive and why

**Technical Debt Roadmap** — *when significant debt identified*
- Quick wins (high impact, low effort)
- Strategic improvements (medium-term)
- Long-term investments

**Developer Quickstart** — *when onboarding is a goal*
- Prerequisites, setup steps, how to run tests
- Entry points with file paths, code conventions

**Open Questions**
- Analysis gaps with impact assessment
- Ambiguities and recommendations for deeper investigation

#### HTML Packaging

The final report is a single self-contained HTML file:
- Embedded CSS, no external dependencies
- Navigation sidebar or index reflecting the report hierarchy
- All Mermaid diagrams pre-rendered as inline SVG — no Mermaid JS library included
- All internal links as anchor navigation
- Must render fully when opened offline

#### Validation

Before finalizing, verify:
- Content is synthesized for humans, not restated raw findings
- All claims traceable to specific `.analysis/` files
- Depth matches project complexity
- All Mermaid diagrams render with valid syntax
- Navigation links are valid (targets exist)
- Risk items have actionable remediation, not just description
- Gaps flagged with "Analysis Gap:" prefix
- Pages are manageable size — split if too long

---

## Cross-Cutting Standards

These standards apply to all analytical work:

- **Read-only**: Never modify repository files. All output goes to `.analysis/`.
- **Evidence-based**: Every claim references specific locations (`file:line`, commit hash, table name). Distinguish confirmed findings from inferences.
- **Confidence-gated**: Store only findings with confidence >= 80%. Investigate contradictions rather than ignoring them.
- **Self-validating**: Every work area validates findings for internal consistency before producing output.
- **Context-calibrated**: Assess against the project's own conventions and scale, not abstract ideals.

## User Gates

Two mandatory confirmation points:

1. **After prerequisites**: Present the analysis plan and ask for user context, data sources, or scope adjustments. Wait for confirmation.
2. **After scope assessment**: Update the plan if scope changed significantly. Wait for confirmation.

Between gates, proceed autonomously. Pause only for decisions affecting scope or quality.
