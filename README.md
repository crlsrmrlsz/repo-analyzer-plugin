# Repository Analyzer Plugin

A Claude Code plugin that performs deep, multi-agent analysis of any software repository. Run the `/repo-analyzer` slash command, and a team of specialized agents examines your codebase's architecture, domain logic, code health, and optionally its database — then delivers a self-contained HTML report.

## Quick Start

```bash
# 1. Clone the plugin
git clone https://github.com/ccrs70/plugin-repo-analyzer.git

# 2. Launch Claude Code in your project, loading the plugin
cd /path/to/your/project
claude --plugin-dir /path/to/plugin-repo-analyzer

# 3. Run the analyzer
/repo-analyzer
```

## Installation

### Clone the repository

```bash
git clone https://github.com/ccrs70/plugin-repo-analyzer.git
```

There is no build step. The cloned directory *is* the plugin — you point Claude Code at it directly.

### Per-session loading

Launch Claude Code with `--plugin-dir` pointing to the cloned folder:

```bash
claude --plugin-dir ~/tools/plugin-repo-analyzer
```


### Verify installation

Inside Claude Code, type `/help`. The `/repo-analyzer` command should appear in the list of available commands.

## Usage

```bash
/repo-analyzer                       # Analyze current directory
/repo-analyzer /path/to/repo         # Analyze a specific path
/repo-analyzer --focus "auth"        # Focus on a specific area
```

### What to expect

The analysis proceeds through six knowledge goals:

1. **Prerequisites** — Confirms repository access, tooling, and database connectivity. Presents its plan and pauses for your confirmation.
2. **Scope & Complexity** — Determines project type, tech stack, and scale. Pauses again so you can adjust the plan before deep analysis begins.
3. **Architecture** — Maps system boundaries, entry points, module relationships, and design patterns.
4. **Domain & Business Logic** — Identifies domain entities, business rules, API surfaces, and core workflows.
5. **Health & Risk** — Audits code quality, security posture, and technical debt with confidence-scored findings.
6. **Documentation** — Synthesizes everything into a navigable report packaged as self-contained HTML.

The analyzer pauses at two gates — after prerequisites and after scope — for your input. Between those gates it runs autonomously, and progress is visible via the task list.

### Recommended model

Use Opus for the best orchestration quality. The orchestrator and planners run on whichever model you launch Claude Code with, while specialist agents always use Sonnet.

## Per-Project Settings

You can pre-configure repository and database details so the analyzer skips interactive discovery at startup.

### Setup

```
your-project/
└── .claude/
    └── repo-analyzer.local.md       # Per-project settings
```

Copy the template into your project:

```bash
mkdir -p .claude
cp /path/to/plugin-repo-analyzer/templates/repo-analyzer.local.md .claude/repo-analyzer.local.md
```

### Tool permissions

The plugin's agents need authorization to use tools (Bash, file access, MCP servers, etc.). Copy the permissions template to skip interactive approval prompts:

```bash
cp /path/to/plugin-repo-analyzer/templates/settings.local.json .claude/settings.local.json
```

This pre-authorizes all tools the plugin uses. The file is `.local.json` so it won't be committed to your repository.

### Configuration reference

The settings file uses YAML frontmatter. Uncomment and edit the values you need:

```yaml
---
# -- Repository access --------------------------------------------------------
vcs_platform: github              # github | gitlab | git | svn
remote_url: https://github.com/org/repo

# -- Database access (optional — remove this section if no database) ----------
db_enabled: true
db_type: postgres                  # postgres | mysql | mariadb | sqlite | sqlserver | oracle
db_connection: dbhub               # dbhub | cli
db_host: localhost
db_port: 5432
db_name: myapp
db_user: readonly_user
# IMPORTANT: Never put passwords here — use environment variables or .dbhub.toml

# -- Analysis preferences (optional) -----------------------------------------
focus_areas: ["auth", "api"]       # Limit analysis to specific areas
exclusions: ["vendor", "node_modules", "generated"]
output_format: detailed            # detailed | summary
---
```

### Project notes

Below the YAML frontmatter, add free-form markdown with context that should inform the analysis:

```markdown
# Project Notes

- Monorepo with 3 services under services/ directory
- Legacy migration in progress — ignore deprecated/ folder
- Primary database is PostgreSQL, Redis used only for caching
```

### Notes

- Add `.claude/*.local.md` to your `.gitignore` — settings files contain project-specific configuration and should not be committed.
- Restart Claude Code after editing settings for changes to take effect.

## Version Control Setup

### Git

Works out of the box. No additional setup required.

### GitHub

Install the GitHub CLI and authenticate:

```bash
sudo apt install gh    # or: sudo dnf install gh
gh auth login
```

This unlocks additional metadata for the git-analyst agent: pull requests, issues, CI/CD status, releases, and contributor statistics.

### GitLab

Install the GitLab CLI and authenticate:

```bash
sudo apt install glab    # or: sudo dnf install glab
glab auth login
```

**Self-hosted GitLab**: Specify your instance hostname when authenticating:

```bash
glab auth login --hostname gitlab.example.com
```

Choose **Personal Access Token** when prompted. Generate one at `https://gitlab.example.com/-/user_settings/personal_access_tokens` with scopes `api` and `read_repository`.

### SVN

Install Subversion:

```bash
sudo apt install subversion    # or: sudo dnf install subversion
```

**Credential storage** — three options:

1. **Auto-cache (default)**: Run any SVN command that contacts the server (e.g., `svn info <url>`), enter your credentials when prompted, and they are cached automatically in `~/.subversion/auth/svn.simple/`. Subsequent commands use the cached credentials without prompting.

2. **Server config file**: Edit `~/.subversion/servers` to set default credentials per server group:
   ```ini
   [groups]
   myserver = svn.example.com

   [myserver]
   username = your-username
   # Password can be stored via auto-cache (option 1) after first use
   ```

3. **Command-line** (least secure — credentials visible in process list):
   ```bash
   svn info --username user --password pass svn://svn.example.com/repo
   ```

**Cache management**:
- Cache location: `~/.subversion/auth/`
- Clear cached credentials: `rm -rf ~/.subversion/auth/svn.simple/`


## Database Setup (Optional)

Database analysis is optional. When enabled, the database-analyst agent reverse-engineers schemas, detects ORM drift, and profiles business data. Access must be **read-only**.

Two strategies are supported: MCP servers (recommended) or CLI fallback.

### DBHub

[DBHub](https://github.com/bytebase/dbhub) supports PostgreSQL, MySQL, MariaDB, SQL Server, SQLite, and Oracle.

**Single database** — create `dbhub.toml` in your project root:

```toml
[[sources]]
id = "main"
dsn = "postgres://readonly_user:${DB_PASSWORD}@localhost:5432/myapp"

[[tools]]
name = "execute_sql"
source = "main"
readonly = true
```

**Multiple databases** — add more `[[sources]]` and `[[tools]]` entries:

```toml
[[sources]]
id = "main"
dsn = "postgres://readonly_user:${DB_PASSWORD}@localhost:5432/myapp"

[[sources]]
id = "analytics"
dsn = "mysql://readonly_user:${DB_PASSWORD}@localhost:3306/analytics"

[[tools]]
name = "execute_sql"
source = "main"
readonly = true

[[tools]]
name = "execute_sql"
source = "analytics"
readonly = true
```

Add DBHub to `.mcp.json`:

```json
{
  "mcpServers": {
    "dbhub": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub@latest", "--config", "dbhub.toml"]
    }
  }
}
```

For sensitive credentials, use environment variable expansion (`${DB_URL}`) in `.mcp.json` or place the config at `~/.dbhub.toml`.

### Oracle

**SQLcl MCP Server** (recommended) — Oracle's official MCP server, built into SQLcl. No Docker needed, supports Oracle 19c–23ai. See [`templates/oracle-sqlcl-mcp-setup.md`](templates/oracle-sqlcl-mcp-setup.md) for the full setup guide.


### CLI fallback

If no MCP server is configured, agents fall back to CLI tools (`psql`, `mysql`, `sqlite3`, `sqlcmd`, `sqlplus`) with user confirmation.

### MCP access in agents

The database-analyst agent includes MCP tools for `dbhub` and `sqlcl` servers in its `tools` list. If you use a differently-named MCP server, add its tools (in `mcp__<server>__<tool>` format) to the `tools` array in `agents/database-analyst.md`.

### Where to place database files

```
your-project/
├── .mcp.json                        # MCP server config
├── dbhub.toml                       # DBHub connections
└── .claude/
    └── repo-analyzer.local.md       # db_enabled, db_type, etc.
```

## Output

Results are written to `.analysis/` in the project root:

```
.analysis/
├── orchestrator_state.md     # Orchestrator working memory
├── p1/                       # Scope findings
├── p2/                       # Architecture findings
├── p3/                       # Domain findings
├── p4/                       # Health audit findings
└── report/                   # Navigable report + self-contained HTML
    ├── *.md                  # Linked report pages (overview → detail)
    └── report.html           # Self-contained HTML report
```

The `report.html` file is fully self-contained — embedded CSS, navigation, and all content — so it can be shared, emailed, or opened in any browser without a server.

Add `.analysis/` to your `.gitignore` to keep analysis output out of version control.

## Requirements

- **Claude Code CLI** (with plugin support)
- **Node.js 18+** (for MCP servers)
- **Python 3** (for plugin hooks)
- **Git** (or `svn` for Subversion repositories)
- **Optional**: `gh` (GitHub CLI), `glab` (GitLab CLI), database CLI tools

## How It Works

The plugin uses a hierarchical agent system: an orchestrator (Opus) decomposes the analysis into knowledge goals and delegates each to a planner (Opus), which further breaks work into focused tasks for specialist agents (Sonnet). Specialists write detailed findings to `.analysis/` files, while only concise summaries flow upward — keeping each agent's context lean and focused. This architecture allows the system to analyze large, complex codebases that would overwhelm a single agent. See [`CLAUDE.md`](CLAUDE.md) for the full design documentation.

## Plugin File Structure

```
plugin-repo-analyzer/
├── .claude-plugin/
│   └── plugin.json                 # Plugin manifest
├── .gitignore
├── CLAUDE.md                       # Prompt design & orchestration rules
├── README.md
├── commands/
│   └── repo-analyzer.md            # Orchestrator command
├── agents/
│   ├── planner.md                  # Strategic planner (Opus) — decomposes objectives
│   ├── code-explorer.md            # Structure + behavior analysis
│   ├── database-analyst.md         # Data layer forensics
│   ├── code-auditor.md             # Health + security audit
│   ├── git-analyst.md              # VCS intelligence
│   └── documentalist.md            # Report synthesis
├── hooks/
│   ├── hooks.json                  # Hook configuration
│   ├── enforce-depth.sh            # Planner recursion depth guard
│   └── log-agents.py               # Agent lifecycle JSONL logger
└── templates/
    ├── repo-analyzer.local.md      # Settings template (copy to .claude/)
    ├── settings.local.json         # Permissions template (copy to .claude/)
    ├── dbhub-oracle-example.toml   # DBHub config example for Oracle
    ├── oracle-setup.md             # Oracle DBHub setup guide
    └── oracle-sqlcl-mcp-setup.md   # Oracle SQLcl MCP setup guide
```
