# Budget AI

Personal finance app that imports transactions from Emma budget app via Google Sheets and provides AI-powered insights using a local LLM.

## What It Does

- **Import**: Connect Google Drive, select your Emma spreadsheet, import all transactions
- **View**: Browse and filter transactions by account, type, search
- **Chat**: Ask questions about your finances via AI chat at `/chat`
- **Analyze**: AI-powered insights using Ollama (local LLM) at `/insights`
- **Budget**: Track spending against category-based budgets
- **MCP Server**: Expose financial data as tools for AI coding agents

## Setup

```bash
# Install dependencies
make install

# Setup database
make db-setup

# Start Rails server (terminal 1)
make server

# Start worker for background jobs (terminal 2)
make worker
```

### Google OAuth

You need Google OAuth credentials to access Sheets. Create a project at
[console.cloud.google.com](https://console.cloud.google.com), enable the
Sheets API, and add your client ID/secret to `.env.local`:

```bash
cp .env.local.example .env.local
# Edit with your Google OAuth credentials
```

### Ollama (for AI features)

```bash
ollama pull llama3.1:8b
ollama serve
```

## Usage

1. Visit http://localhost:3000
2. Connect Google account
3. Select Emma spreadsheet, choose sheet, import
4. View transactions at /transactions
5. Chat with the AI at /chat or get insights at /insights

## Tech Stack

- Rails 8 with Hotwire (Turbo + Stimulus)
- SolidQueue for background jobs
- SQLite (local only, single-user)
- Ollama for local LLM insights
- Material Design 3 dark theme

## Commands

| Command | Description |
|---------|-------------|
| `make server` | Start Rails server |
| `make worker` | Start SolidQueue worker |
| `make test` | Run tests |
| `make lint` | Run RuboCop |
| `make console` | Open Rails console |
| `make mcp-test` | Test MCP server |
| `make` | Show interactive command menu |

## Architecture

Single-user app. No authentication. All data local.

- `EmmaSpreadsheetImportService` - parses Emma Google Sheets exports
- `CachedStatisticsService` - caches transaction stats for dashboard
- `LlmService` - AI insights via Ollama
- `script/mcp_server.rb` - MCP server exposing 17 financial tools

## Documentation

| Topic | Guide |
|-------|-------|
| Emma import | [docs/features/emma-import.md](docs/features/emma-import.md) |
| AI chat | [docs/features/chat.md](docs/features/chat.md) |
| Budgets | [docs/features/budgets.md](docs/features/budgets.md) |
| MCP server | [docs/features/mcp-server.md](docs/features/mcp-server.md) |
| Persistent edits | [docs/features/persistent-edits.md](docs/features/persistent-edits.md) |

## License

MIT
