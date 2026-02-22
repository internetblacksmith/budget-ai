# Budget AI

Personal finance app that imports transactions from Emma budget app via Google Sheets and provides AI-powered insights.

## What It Does

- **Import**: Connect Google Drive, select your Emma spreadsheet, import all transactions
- **View**: Browse and filter transactions by account, type, search
- **Analyze**: AI-powered insights using Ollama (local LLM)

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

## Usage

1. Visit http://localhost:3000
2. Connect Google account
3. Select Emma spreadsheet → Select sheet → Import
4. View transactions at /transactions
5. Get AI insights at /insights

## Tech Stack

- Rails 8
- SolidQueue for background jobs
- SQLite (local only)
- Ollama for AI insights

## Commands

| Command | Description |
|---------|-------------|
| `make server` | Start Rails server |
| `make worker` | Start SolidQueue worker |
| `make test` | Run tests |
| `make lint` | Run Rubocop |
| `make console` | Open Rails console |

## Architecture

Single-user app. No authentication. All data local.

- `EmmaSpreadsheetImportService` - parses Emma exports
- `CachedStatisticsService` - caches transaction stats
- `LlmService` - AI insights via Ollama
