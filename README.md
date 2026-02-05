# Repository Analyzer Plugin

Multi-agent Claude Code plugin for comprehensive analysis of software repositories with optional database reverse-engineering.

## Prompt Architecture: OCV Framework

All prompts — orchestrator and agents — follow the **Objective-Constraint-Verification (OCV)** pattern:

> Define the analytical objective and the environmental constraints, then mandate a self-verification step, while leaving the discovery path and tool-chain sequence to the model's reasoning.

This means agents receive *what to achieve*, not *how to code it*. Four cross-cutting sections enforce this:

| Section | Purpose | Example |
|---------|---------|---------|
| **Strategic Guardrails** | Safety rules and ground truth sources | "Read-only DB access", "Confidence >= 80%" |
| **Analytical Objectives** | Goal + success criteria per analysis area | "This succeeds when: you can quantify drift as %" |
| **Exploration Autonomy** | Permission to pivot strategy on failure | "If initial search fails, refine and retry" |
| **Validation Loop** | Self-critique before finalizing output | "Are findings internally consistent?" |

The orchestrator uses the same pattern at the phase level: each phase has an **Objective**, **Constraints**, and **"This phase succeeds when"** criteria — without prescribing which agent handles which sub-task.

## Context Architecture

The orchestrator decomposes work across agents to exploit **context isolation** — each agent gets a fresh context window, so focused agents go deeper than a single overloaded one.

**Information flow** uses a two-tier output structure:
- Agents **write detailed findings** to `.analysis/` files (path specified by orchestrator)
- Agents **return only a concise summary** in their response — keeping the orchestrator's context lean
- Downstream agents **read directly from `.analysis/`** — no relay through the orchestrator

**Decomposition** is calibrated to project scale after Phase 1. The orchestrator chooses its decomposition strategy based on the project's actual complexity and dependency structure — narrow scope is preferred, since three focused agents outperform one overloaded agent.

## Agents

| Agent | Model | Objective |
|-------|-------|-----------|
| **code-explorer** | sonnet | Produce evidence-based analysis of codebase structure and behavior with `file:line` evidence |
| **database-analyst** | sonnet | Reverse-engineer data architectures: schema inventory, volume analysis, ORM drift detection |
| **code-auditor** | sonnet | Assess code health across 7 dimensions with confidence-based filtering (>= 80%) and severity classification |
| **git-analyst** | sonnet | Extract VCS intelligence: contributor dynamics, hotspot risk scores, bus factor, velocity trends |
| **documentalist** | sonnet | Synthesize `.analysis/` findings into audience-appropriate documentation with progressive disclosure |

The orchestrator command runs on whatever model the user launches Claude Code with (recommended: opus for best coordination).

## Analysis Phases

| Phase | Objective | Succeeds When |
|-------|-----------|---------------|
| 0. Prerequisites | Establish ground truth about the analysis environment | Access confirmed, scope agreed with user |
| 1. Scope | Determine project type, scale, and complexity | Complexity rating drives Phase 2-4 decomposition |
| 2. Architecture | Map structural organization, boundaries, and patterns | A new developer could navigate the project |
| 3. Domain & Logic | Understand what the system *does* — domain model, rules, workflows | Core entities, relationships, and workflows mapped |
| 4. Health Audit | Evaluate quality, security, and technical debt | Justified health score + prioritized risk list |
| 5. Documentation | Produce actionable, audience-layered documentation | All claims traceable, gaps explicitly flagged |

The orchestrator pauses at checkpoints (Phases 0, 1, 2, 3, 5) for user confirmation before proceeding.

## Installation

```bash
# Clone the plugin
git clone https://github.com/ccrs70/plugin-repo-analyzer.git

# Global (all projects)
cp -r plugin-repo-analyzer ~/.claude/plugins/

# Or project-specific
cp -r plugin-repo-analyzer .claude/plugins/
```

## Prerequisites

### Repository Access

| Platform | Setup |
|----------|-------|
| GitHub | `gh auth login` |
| GitLab | `glab auth login` |
| Other Git | SSH key or HTTPS credentials |
| SVN | `svn` CLI configured |

### Database Access (Optional)

Database analysis requires **read-only** access via DBHub MCP server or CLI fallback.

**DBHub setup** (recommended):

1. Create `.dbhub.toml`:
```toml
readonly = true

[[databases]]
name = "mydb"
type = "postgres"  # postgres|mysql|mariadb|sqlite|sqlserver|oracle
host = "localhost"
port = 5432
database = "myapp"
user = "readonly_user"
password = "password"
```

2. Add to `.mcp.json`:
```json
{
  "mcpServers": {
    "dbhub": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub@latest", "--config", ".dbhub.toml"]
    }
  }
}
```

For sensitive credentials, use `~/.dbhub.toml` instead.

**CLI fallback**: If DBHub unavailable, agents use `psql`, `mysql`, `sqlite3`, `sqlcmd` with credentials from environment or config files.

**Oracle**: Requires `ORACLE_LIB_DIR` pointing to Instant Client.

**MongoDB**: Use community `mongodb-mcp` server (not supported by DBHub).

## Settings (Optional)

Create `.claude/repo-analyzer.local.md` in your project root to pre-configure repository and database access. The orchestrator reads this file at Phase 0 to skip interactive discovery for already-configured values.

**Quick setup** — copy the template and uncomment the settings you need:

```bash
mkdir -p .claude
cp path/to/repo-analyzer-plugin/templates/repo-analyzer.local.md .claude/repo-analyzer.local.md
```

See [`templates/repo-analyzer.local.md`](templates/repo-analyzer.local.md) for all available settings with descriptions.

After creating or editing settings, restart Claude Code for changes to take effect.

**Important**: Add `.claude/*.local.md` to your `.gitignore` — settings files contain project-specific configuration and should not be committed.

## Usage

```bash
claude /repo-analyzer                    # Analyze current directory
claude /repo-analyzer /path/to/repo      # Analyze specific path
claude /repo-analyzer --focus "auth"     # Focus on specific area
```

## Output

Results written to `.analysis/`:

```
.analysis/
├── orchestrator_state.md     # Orchestrator working memory
├── p1/                       # Scope findings
├── p2/                       # Architecture findings
├── p3/                       # Domain findings
├── p4/                       # Health audit findings
└── report/                   # Final documentation
    └── final_report.md
```

## Requirements

- Claude Code CLI
- Node.js 18+ (for MCP servers)
- Git CLI (or `gh`/`glab` for GitHub/GitLab)
- Database CLI tools or DBHub MCP server (optional)

## File Structure

```
repo-analyzer/
├── .claude-plugin/
│   └── plugin.json            # Plugin manifest
├── .gitignore
├── README.md
├── commands/
│   └── repo-analyzer.md       # Orchestrator (OCV phases)
├── agents/
│   ├── code-explorer.md        # Structure + behavior analysis
│   ├── database-analyst.md     # Data layer forensics
│   ├── code-auditor.md         # Health + security audit
│   ├── git-analyst.md          # VCS intelligence
│   └── documentalist.md        # Report synthesis
└── templates/
    └── repo-analyzer.local.md  # Settings template (copy to .claude/)
```
