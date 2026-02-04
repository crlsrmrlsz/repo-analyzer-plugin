# Repository Analyzer Plugin

Multi-agent Claude Code plugin for comprehensive analysis of software repositories with optional database reverse-engineering.

## Agents

| Agent | Purpose |
|-------|---------|
| **code-explorer** | Maps structure, traces execution flows, identifies patterns |
| **database-analyst** | Reverse-engineers schemas, detects ORM drift, documents stored procedures |
| **code-auditor** | Evaluates security, quality, technical debt (confidence-based filtering) |
| **git-analyst** | Extracts VCS intelligence: contributors, hotspots, bus factor |
| **documentalist** | Synthesizes findings into audience-appropriate documentation |

## Analysis Phases

| Phase | Goal |
|-------|------|
| 0. Prerequisites | Verify access, confirm scope |
| 1. Scope | Project type, size, complexity |
| 2. Architecture | Structure, boundaries, entry points |
| 3. Domain & Logic | What the system does |
| 4. Health Audit | Quality, security, maintainability |
| 5. Documentation | Final report with Mermaid diagrams |

## Installation

```bash
# Global (all projects)
cp -r repo-analyzer-plugin ~/.claude/plugins/

# Or project-specific
cp -r repo-analyzer-plugin .claude/plugins/
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

## Usage

```bash
claude /repo-analyzer                    # Analyze current directory
claude /repo-analyzer /path/to/repo      # Analyze specific path
claude /repo-analyzer --focus "auth"     # Focus on specific area
```

The orchestrator pauses at checkpoints for user confirmation before proceeding.

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
repo-analyzer-plugin/
├── README.md
├── command/
│   └── repo-analyzer.md      # Main orchestrator
└── agents/
    ├── code-explorer.md
    ├── database-analyst.md
    ├── code-auditor.md
    ├── git-analyst.md
    └── documentalist.md
```
