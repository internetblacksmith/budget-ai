# Budget AI

Rails 8 personal finance app with Emma spreadsheet import, encrypted per-user databases, and local LLM insights.

## Build Commands

```bash
make commit-check   # REQUIRED before any commit (tests + lint + coverage)
make test           # RSpec + Cucumber
make lint           # Rubocop (zero violations required)
```

## Critical Rules

- **Tests required** with all code changes - 80% minimum coverage
- **Never start the dev server** - I manage it myself, you have access via browser
- **Documentation required** - update `/docs/` for any feature changes
- **Keep Makefile updated** - both menus and help text when adding commands
- **Pin dependencies** in Gemfile (e.g., `gem "rails", "8.0.2"`)

## Detailed Guides

| Topic | Guide |
|-------|-------|
| Code conventions | [docs/code-style.md](docs/code-style.md) |
| Testing patterns | [docs/testing.md](docs/testing.md) |
| Error handling | [docs/error-handling.md](docs/error-handling.md) |
| Git workflow | [docs/git-workflow.md](docs/git-workflow.md) |
| Architecture | [docs/architecture.md](docs/architecture.md) |
| CLI commands | [docs/cli-commands.md](docs/cli-commands.md) |
| Import notifications | [docs/IMPORT_NOTIFICATIONS.md](docs/IMPORT_NOTIFICATIONS.md) |
| MCP Server | [docs/features/mcp-server.md](docs/features/mcp-server.md) |
| Persistent edits | [docs/features/persistent-edits.md](docs/features/persistent-edits.md) |
