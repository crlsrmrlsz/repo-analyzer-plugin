# Repository Analyzer Plugin

Multi-agent Claude Code plugin for comprehensive analysis of software repositories with optional database reverse-engineering.

## Prompt Design Principles

All prompts — orchestrator and agents — follow three design principles:

1. **Goal-based**: Each agent receives an objective and success criteria, not a rigid procedure. Agents choose their investigation strategy based on the codebase.
2. **Constrained**: Guardrails encode safety rules and ground truth sources (e.g., "read-only DB access", "confidence >= 80%"). These are hard boundaries, not suggestions.
3. **Self-verifying**: Every agent validates findings for internal consistency as the final step of its process before producing output.

Agents also receive light procedural scaffolding — a recommended step sequence they can adapt or reorder — since Sonnet benefits from a default path while retaining flexibility.

The orchestrator uses the same pattern at the phase level: each phase has an **Objective**, **Constraints**, and **"This phase succeeds when"** criteria.

## Context Architecture

The orchestrator decomposes work across agents to exploit **context isolation** — each agent gets a fresh context window, so focused agents go deeper than a single overloaded one.

**Information flow** uses a two-tier output structure:
- Agents **write detailed findings** to `.analysis/` files (path specified by orchestrator)
- Agents **return only a concise summary** in their response — keeping the orchestrator's context lean
- Downstream agents **read directly from `.analysis/`** — no relay through the orchestrator

**Decomposition** is calibrated to project scale after Phase 1. The orchestrator chooses its decomposition strategy based on the project's actual complexity and dependency structure.

## Agents

| Agent | Model | Objective |
|-------|-------|-----------|
| **code-explorer** | sonnet | Produce evidence-based analysis of codebase structure and behavior with `file:line` evidence |
| **database-analyst** | sonnet | Reverse-engineer data architectures: schema inventory, volume analysis, ORM drift detection |
| **code-auditor** | sonnet | Assess code health with confidence-based filtering (>= 80%) and severity classification |
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

Plain `git` is sufficient for basic analysis. Platform CLI tools unlock additional metadata — PRs/MRs, issues, CI/CD status, releases, contributor statistics — that the git-analyst agent uses for richer analysis.

| Platform | Tool | Install | Auth |
|----------|------|---------|------|
| GitHub | `gh` (official) | `brew install gh` | `gh auth login` |
| GitLab | `glab` (official) | `brew install glab` | `glab auth login` |
| Bitbucket | No official CLI | — | Agent uses REST API via `curl` |
| Other Git | — | — | SSH key or HTTPS credentials |
| SVN | `svn` | `apt install subversion` | Credentials cached per-server |

### Database Access (Optional)

Database analysis requires **read-only** access via MCP server or CLI fallback.

**DBHub setup** (recommended — supports PostgreSQL, MySQL, MariaDB, SQL Server, SQLite, Oracle):

1. Add to `.mcp.json`:
```json
{
  "mcpServers": {
    "dbhub": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub@latest",
               "--dsn", "postgres://readonly_user:password@localhost:5432/myapp",
               "--readonly"]
    }
  }
}
```

For multiple databases, use a TOML config:
```toml
# dbhub.toml
[[sources]]
id = "main"
dsn = "postgres://readonly_user:password@localhost:5432/myapp"

[[sources]]
id = "analytics"
dsn = "mysql://readonly_user:password@localhost:3306/analytics"
```
```json
{
  "mcpServers": {
    "dbhub": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub@latest", "--config", "dbhub.toml", "--readonly"]
    }
  }
}
```

For sensitive credentials, use environment variable expansion (`${DB_URL}`) in `.mcp.json` or place the config at `~/.dbhub.toml`.

**Oracle**: Standard Oracle connections use `oracle://user:pass@host:1521/service_name`. For Oracle 11g or older, use the `bytebase/dbhub-oracle-thick` Docker image and set `ORACLE_LIB_DIR` pointing to Instant Client.

**MongoDB**: Use the official MongoDB MCP server (not supported by DBHub):
```json
{
  "mcpServers": {
    "mongodb": {
      "command": "npx",
      "args": ["-y", "mongodb-mcp-server@latest", "--readOnly"],
      "env": {
        "MDB_MCP_CONNECTION_STRING": "mongodb://localhost:27017/mydb"
      }
    }
  }
}
```

**CLI fallback**: If no MCP server is configured, agents fall back to CLI tools (`psql`, `mysql`, `sqlite3`, `sqlcmd`, `sqlplus`) with user confirmation.

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
│   └── repo-analyzer.md       # Orchestrator (phased analysis)
├── agents/
│   ├── code-explorer.md        # Structure + behavior analysis
│   ├── database-analyst.md     # Data layer forensics
│   ├── code-auditor.md         # Health + security audit
│   ├── git-analyst.md          # VCS intelligence
│   └── documentalist.md        # Report synthesis
└── templates/
    └── repo-analyzer.local.md  # Settings template (copy to .claude/)
```
