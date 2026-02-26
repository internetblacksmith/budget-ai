# Budget AI

Rails 8 personal finance app with Emma spreadsheet import, encrypted per-user databases, and local LLM insights.

## Build Commands

```bash
make commit-check   # REQUIRED before any commit (tests + lint)
make test           # RSpec
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
| Emma import | [docs/features/emma-import.md](docs/features/emma-import.md) |
| Chat / AI | [docs/features/chat.md](docs/features/chat.md) |
| Budgets | [docs/features/budgets.md](docs/features/budgets.md) |
| MCP Server | [docs/features/mcp-server.md](docs/features/mcp-server.md) |
| Persistent edits | [docs/features/persistent-edits.md](docs/features/persistent-edits.md) |
