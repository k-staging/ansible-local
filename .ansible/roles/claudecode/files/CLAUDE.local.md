# HIGHEST PRIORITY RULES (CLAUDE.local.md)

This file has the HIGHEST priority and overrides all other CLAUDE.md files.
このファイルは最優先で、他のすべてのCLAUDE.mdより優先される。

## MANDATORY - NO EXCEPTIONS

### TodoWrite
**ALWAYS use TodoWrite** for tasks involving investigation, implementation, or modification.
調査・実装・修正を伴うタスクでは**必ずTodoWriteを使用**すること。

### Skills
**ALWAYS invoke Skills BEFORE editing**:
- `.rb`, `.py`, `.sql` → `backend-dev`
- `Dockerfile`, `docker-compose*.yml`, `.ansible/`, `*.tf` → `infra-quick-check`
- ActiveRecord/SQL → `sql-helper`

### Agents
**ALWAYS run review agents** after completing all todos.
全タスク完了後、**必ずレビューAgentを実行**すること。

### Language
すべての回答は日本語で行う。
