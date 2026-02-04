# Repository Analyzer Plugin

A multi-agent Claude Code plugin that performs comprehensive analysis of software repositories, optionally including database reverse-engineering.

## Overview

This plugin orchestrates specialized agents to analyze unknown codebases:

| Agent | Purpose |
|-------|---------|
| **code-explorer** | Maps structure, traces execution flows, identifies patterns |
| **database-analyst** | Reverse-engineers schemas, detects ORM drift, documents stored procedures |
| **code-auditor** | Evaluates security, quality, technical debt with confidence-based filtering |
| **git-analyst** | Extracts intelligence from version control: contributors, hotspots, bus factor |
| **documentalist** | Synthesizes findings into audience-appropriate documentation |

### Analysis Phases

| Phase | Goal |
|-------|------|
| **0. Prerequisites** | Verify access and confirm scope with user |
| **1. Scope** | Determine project type, size, complexity |
| **2. Architecture** | Map structure, boundaries, entry points |
| **3. Domain & Logic** | Understand what the system does |
| **4. Health Audit** | Evaluate quality, security, maintainability |
| **5. Documentation** | Generate actionable reports with Mermaid diagrams |

## Installation

1. Clone or copy this plugin to your Claude Code plugins directory:

   ```bash
   # Personal plugins (available in all projects)
   cp -r repo-analyzer-plugin-v2 ~/.claude/plugins/

   # Or project-specific
   cp -r repo-analyzer-plugin-v2 .claude/plugins/
   ```

2. Enable the plugin in Claude Code

## Prerequisites

### Repository Access

The plugin supports multiple repository types and hosting platforms:

| Platform | Requirements |
|----------|--------------|
| **GitHub** | `gh` CLI authenticated (`gh auth login`) — recommended |
| **GitLab** | `glab` CLI authenticated or git with SSH key |
| **Bitbucket** | Git with SSH key or HTTPS credentials |
| **Self-hosted Git** | Git with appropriate SSH/HTTPS access |
| **SVN** | `svn` CLI with credentials configured |

**For private repositories**, ensure credentials are configured before running analysis:

```bash
# GitHub (recommended - provides better rate limits and private repo access)
gh auth login

# GitLab
glab auth login

# Generic Git (SSH)
ssh-add ~/.ssh/id_rsa

# SVN
svn auth --username your_username
```

### Database Access (Optional)

Database analysis requires **read-only** access. The plugin supports two connection methods:

#### Preferred: DBHub (Universal Database MCP Server)

DBHub provides secure, managed connections to multiple databases from a single MCP server.

**Supported databases:** PostgreSQL, MySQL, MariaDB, SQL Server, SQLite, Oracle

**Features:**
- Zero dependencies, token-efficient (only 2 tools)
- Safety guardrails: read-only mode, row limits, query timeouts
- SSH tunneling and SSL/TLS support
- Connect to multiple databases simultaneously

**Installation:**

```bash
npx @bytebase/dbhub@latest --help
```

**Configuration** — Create `.dbhub.toml` in your project root:

```toml
# Read-only mode for safety
readonly = true
row_limit = 1000
timeout = 30

[[databases]]
name = "production"
type = "postgres"
host = "localhost"
port = 5432
database = "myapp"
user = "readonly_user"
password = "secure_password"

[[databases]]
name = "analytics"
type = "mysql"
host = "localhost"
port = 3306
database = "analytics"
user = "readonly_user"
password = "secure_password"

[[databases]]
name = "local"
type = "sqlite"
path = "./data/app.db"

[[databases]]
name = "oracle_prod"
type = "oracle"
host = "localhost"
port = 1521
service = "ORCL"
user = "readonly_user"
password = "secure_password"
```

**Oracle requirement:** Set `ORACLE_LIB_DIR` environment variable pointing to Oracle Instant Client.

**MCP Configuration** — Add to `.mcp.json`:

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

For sensitive credentials, use `~/.dbhub.toml` instead (not committed to repository).

#### Fallback: CLI Tools

If DBHub is unavailable, the plugin falls back to CLI tools. Ensure credentials are available:

```bash
# PostgreSQL
export PGPASSWORD="readonly_password"
# or configure ~/.pgpass

# MySQL/MariaDB — configure in ~/.my.cnf
[client]
user=readonly_user
password=readonly_password

# SQL Server — use trusted connection or environment variables
export SQLCMDUSER=readonly_user
export SQLCMDPASSWORD=readonly_password
```

**Note:** For Oracle databases, DBHub requires Oracle Instant Client:
```bash
export ORACLE_LIB_DIR=/path/to/instantclient
```
For MongoDB (not supported by DBHub), use community mongodb-mcp server.


## Usage

```bash
# Analyze current directory
claude /repo-analyzer

# Analyze specific path
claude /repo-analyzer /path/to/repository

# Analyze with focus area
claude /repo-analyzer --focus "authentication system"
```

### Interactive Checkpoints

The plugin pauses at key decision points to confirm with you:

1. **After prerequisites** — Confirm repository/database access status
2. **After scope analysis** — Confirm focus areas and complexity assessment
3. **After domain analysis** — Verify understanding before health audit
4. **After documentation** — Review final report

## Output Structure

Analysis results are written to `.analysis/` directory:

```
.analysis/
├── orchestrator_state.md    # Orchestrator working memory
├── p1/                      # Phase 1: Scope
│   ├── explorer_tech-stack.md
│   ├── git_repo-profile.md
│   └── scope_summary.md
├── p2/                      # Phase 2: Architecture
│   ├── explorer_structure.md
│   ├── explorer_dependencies.md
│   └── architecture_summary.md
├── p3/                      # Phase 3: Domain
│   ├── explorer_api-surface.md
│   ├── explorer_business-logic.md
│   └── domain_summary.md
├── p4/                      # Phase 4: Health
│   ├── auditor_security.md
│   ├── auditor_quality.md
│   ├── git_hotspots.md
│   └── health_summary.md
└── report/                  # Phase 5: Final documentation
    ├── executive-summary.md
    ├── system-architecture.md
    ├── risk-register.md
    ├── domain-model.md      # (if applicable)
    ├── data-architecture.md # (if DB analyzed)
    └── final_report.md
```

## Configuration

### Project-Specific Settings

Create `.claude/CLAUDE.md` to customize behavior:

```markdown
# Repository Analyzer Configuration

## Database
- Primary database: PostgreSQL (use postgres-mcp)
- Skip MongoDB analysis (test database only)

## Focus Areas
- Prioritize authentication and authorization code
- Include CI/CD pipeline analysis

## Exclusions
- Ignore `/vendor` and `/node_modules`
- Skip archived feature branches
```

### MCP Server Configuration

**Project-wide** (committed to repository) — `.mcp.json` + `.dbhub.toml`:
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

**Personal/sensitive credentials** (not committed) — use `~/.dbhub.toml`:
```bash
# Point to personal config
npx @bytebase/dbhub@latest --config ~/.dbhub.toml
```

Or in `~/.claude.json`:
```json
{
  "mcpServers": {
    "dbhub": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub@latest", "--config", "~/.dbhub.toml"]
    }
  }
}
```

### Optional MCP Servers

| Server | Purpose | When needed |
|--------|---------|-------------|
| **dbhub** | Universal database access (Postgres, MySQL, MariaDB, SQL Server, SQLite, Oracle) | Database analysis requested |
| **context7** | Library documentation lookup | Accurate framework analysis |
| **mongodb-mcp** | MongoDB access | MongoDB databases |

## Security Considerations

1. **Read-only access only**: All database connections must be read-only. The plugin refuses to execute any data modification commands (INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE).

2. **Credential storage**:
   - Never commit credentials to repository
   - Use environment variables or `~/.claude.json` for sensitive values
   - MCP servers support `${VAR}` syntax for environment variable expansion

3. **Output sanitization**: Connection strings and credentials are sanitized in all output files.

4. **Repository scope**: The plugin only analyzes code in the specified directory and its subdirectories.

5. **Production credentials warning**: If production database credentials are detected in configuration files, the plugin warns before proceeding.

## Requirements

- Claude Code CLI
- For GitHub analysis: `gh` CLI (recommended)
- For GitLab analysis: `glab` CLI (optional)
- For SVN analysis: `svn` CLI
- For database analysis: Appropriate MCP server or CLI tool
- Node.js 18+ (for MCP servers via npx)

## File Structure

```
repo-analyzer-plugin-v2/
├── README.md                    # This file
├── command/
│   └── repo-analyzer-v2.md      # Main orchestrator command
├── agents/
│   ├── code-explorer.md         # Code structure and flow analysis
│   ├── database-analyst.md      # Database reverse-engineering
│   ├── code-auditor.md          # Quality and security audit
│   ├── git-analyst.md           # Version control intelligence
│   └── documentalist.md         # Documentation synthesis
└── repo-analysis-report/
    └── SKILL.md                 # Documentation generation skill
```
