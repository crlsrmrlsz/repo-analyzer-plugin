# Oracle Database Setup

Step-by-step configuration for analyzing repositories that use Oracle databases.

## 1. DBHub connection — `dbhub.toml`

Place this file in your project root (or at `~/.dbhub.toml` for shared use).

**Single database:**
```toml
[[sources]]
id = "main"
dsn = "oracle://readonly_user:${ORACLE_PASSWORD}@dbhost.example.com:1521/service_name"

[[tools]]
name = "execute_sql"
source = "main"
readonly = true
```

**Multiple Oracle databases:**
```toml
[[sources]]
id = "production"
dsn = "oracle://readonly_user:${ORACLE_PASSWORD}@prod-db.example.com:1521/prodservice"

[[sources]]
id = "reporting"
dsn = "oracle://readonly_user:${ORACLE_PASSWORD}@report-db.example.com:1521/rptservice"

[[tools]]
name = "execute_sql"
source = "production"
readonly = true

[[tools]]
name = "execute_sql"
source = "reporting"
readonly = true
```

Set the password as an environment variable — never hardcode it:
```bash
export ORACLE_PASSWORD="<replace_with_actual_password>"
```

### Oracle 11g or older

Standard DBHub uses the OCI thin client, which only supports Oracle 12c+. For older versions, use the thick-client Docker image:

```bash
docker run -p 8080:8080 \
  -e ORACLE_LIB_DIR=/opt/oracle/instantclient \
  -e DSN="oracle://readonly_user:${ORACLE_PASSWORD}@dbhost:1521/service_name" \
  bytebase/dbhub-oracle-thick
```

Then configure `.mcp.json` to connect via SSE (see step 2 below).

## 2. MCP server — `.mcp.json`

Add to your project's `.mcp.json` so Claude Code launches DBHub automatically.

**Standard (Oracle 12c+):**
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

**Docker thick client (Oracle 11g or older):**
```json
{
  "mcpServers": {
    "dbhub": {
      "type": "sse",
      "url": "http://localhost:8080/sse"
    }
  }
}
```

## 3. Plugin settings — `.claude/repo-analyzer.local.md`

Copy this to your project at `.claude/repo-analyzer.local.md`:

```yaml
---
vcs_platform: gitlab
remote_url: https://gitlab.example.com/org/repo

db_enabled: true
db_type: oracle
db_connection: dbhub
db_host: dbhost.example.com
db_port: 1521
db_name: service_name
db_user: readonly_user
---
```

Add `.claude/*.local.md` to your `.gitignore`.

## 4. Verify

Restart Claude Code, then run:

```bash
claude /repo-analyzer
```

The orchestrator verifies database connectivity during Phase 0 as part of scope confirmation.

## CLI fallback

If you cannot use DBHub, the plugin falls back to `sqlplus`. Ensure it is installed and on your `PATH`:

```bash
sqlplus readonly_user@//dbhost.example.com:1521/service_name
```

The orchestrator will ask for confirmation before running any CLI commands.
