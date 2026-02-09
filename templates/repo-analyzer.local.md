---
# =============================================================================
# repo-analyzer settings — Per-project configuration
# =============================================================================
# Copy this file to: <your-project>/.claude/repo-analyzer.local.md
# The orchestrator reads it at Phase 0 to skip interactive discovery.
# Lines starting with # are comments (remove # to activate a setting).
# After editing, restart Claude Code for changes to take effect.
# =============================================================================

# -- Repository access --------------------------------------------------------
# vcs_platform: github              # github | gitlab | git | svn
# remote_url: https://github.com/org/repo

# -- Database access (optional — remove this section if no database) ----------
# db_enabled: true
# db_type: postgres                  # postgres | mysql | mariadb | sqlite | sqlserver | oracle
# db_connection: dbhub               # dbhub | cli
# db_host: localhost
# db_port: 5432
# db_name: myapp
# db_user: readonly_user
# IMPORTANT: Never put passwords here — use environment variables or .dbhub.toml

# -- Analysis preferences (optional) -----------------------------------------
# focus_areas: ["auth", "api"]       # Limit analysis to specific areas
# exclusions: ["vendor", "node_modules", "generated"]
# output_format: detailed            # detailed | summary
---

# Project Notes

<!-- Add any context that should inform the analysis. Examples: -->
<!-- - "Monorepo with 3 services under services/ directory" -->
<!-- - "Legacy migration in progress — ignore deprecated/ folder" -->
<!-- - "Primary database is PostgreSQL, Redis used only for caching" -->
