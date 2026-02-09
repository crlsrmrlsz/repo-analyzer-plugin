# Oracle SQLcl MCP Server Setup

Oracle SQLcl includes a built-in MCP server, making it the recommended way to connect Claude Code to Oracle databases. No Docker or third-party tools required.

Supports Oracle 19c through 23ai, on-premises or cloud.

## Prerequisites

- **Linux** (tested on Ubuntu/WSL2)
- **Java 17+**
- **Oracle SQLcl 25.2+**
- Network access to your Oracle database

## Step 1: Install Java

SQLcl requires Java 17 or higher. Check if you already have it:

```bash
java --version
```

If not installed:

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install openjdk-21-jre-headless

# Fedora/RHEL
sudo dnf install java-21-openjdk-headless
```

## Step 2: Install SQLcl

Download and unzip Oracle SQLcl:

```bash
mkdir -p ~/tools
curl -L -o /tmp/sqlcl.zip https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip
unzip /tmp/sqlcl.zip -d ~/tools/
```

Verify the installation:

```bash
~/tools/sqlcl/bin/sql -v
```

You should see `SQLcl: Release 25.x.x`.

## Step 3: Save database connections

SQLcl stores credentials encrypted in `~/.dbtools/`. Each saved connection becomes available to the MCP server automatically.

Launch SQLcl without connecting:

```bash
~/tools/sqlcl/bin/sql /nolog
```

At the `SQL>` prompt, save each connection using `-save` and `-savepwd`:

```sql
conn -save <name> -savepwd <user>/<password>@//<host>:<port>/<service_name>
```

### Examples

**Standard connection:**

```sql
conn -save mydb -savepwd readonly_user/mypassword@//dbhost.example.com:1521/MYSERVICE
```

**Multiple schemas on the same database:**

```sql
conn -save schema_a -savepwd user_a/pass_a@//dbhost.example.com:1521/MYSERVICE
conn -save schema_b -savepwd user_b/pass_b@//dbhost.example.com:1521/MYSERVICE
```

**Oracle RAC / failover (full TNS descriptor):**

```sql
conn -save mydb_rac -savepwd user/password@"(DESCRIPTION=(LOAD_BALANCE=ON)(FAILOVER=ON)(ADDRESS=(PROTOCOL=TCP)(HOST=node1.example.com)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=node2.example.com)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=MYSERVICE)(FAILOVER_MODE=(TYPE=select)(METHOD=basic))))"
```

Each command should print `Connected.` if the database is reachable. Type `exit` when done.

### Converting JDBC connection strings

If you have JDBC connection strings like:

```
jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=myhost.example.com)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=MYSERVICE)))
```

Extract the HOST, PORT, and SERVICE_NAME and use the simple format:

```sql
conn -save mydb -savepwd user/password@//myhost.example.com:1521/MYSERVICE
```

### Troubleshooting

- **ORA-01017** (invalid username/password): Double-check credentials with your DBA.
- **ORA-12541** (no listener): The database host or port is unreachable. Check network/VPN access.
- **ORA-12514** (service not found): Verify the SERVICE_NAME is correct.

## Step 4: Configure Claude Code

Add the SQLcl MCP server to `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "sqlcl": {
      "command": "/home/your_user/tools/sqlcl/bin/sql",
      "args": ["-mcp"]
    }
  }
}
```

Replace `/home/your_user/tools/sqlcl/bin/sql` with the actual path where you installed SQLcl.

Restart Claude Code after creating or editing this file.

### Where to place `.mcp.json`

| Location | Scope |
|----------|-------|
| `~/.claude.json` | Global — available in all projects |
| `<project>/.mcp.json` | Project-specific — only when working in that directory |

### Security

- Credentials are stored encrypted in `~/.dbtools/`, never in `.mcp.json`
- Add `.mcp.json` to your `.gitignore` to avoid committing server paths
- SQLcl logs all MCP activity to the `DBTOOLS$MCP_LOG` table in each database
- Use database users with **minimum required privileges** (ideally read-only)

## Step 5: Verify

Open Claude Code in your project directory. The SQLcl MCP server starts automatically and all saved connections are available. Run the repo-analyzer:

```bash
claude /repo-analyzer
```

The orchestrator will verify database connectivity during Phase 0.

## References

- [Introducing MCP Server for Oracle Database](https://blogs.oracle.com/database/introducing-mcp-server-for-oracle-database)
- [Getting Started with Oracle SQLcl MCP Server](https://www.thatjeffsmith.com/archive/2025/07/getting-started-with-our-mcp-server-for-oracle-database/)
- [Official Oracle SQLcl MCP Documentation](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/25.2/sqcug/using-oracle-sqlcl-mcp-server.html)
