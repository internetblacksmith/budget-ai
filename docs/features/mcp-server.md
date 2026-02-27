# MCP Server (Model Context Protocol)

The MCP server exposes Budget AI's financial data as tools that AI coding agents (like OpenCode) can use from the terminal.

## Prerequisites

- **Ollama** installed and running with `llama3.1:8b` pulled
- **OpenCode** installed (`npm i -g opencode`)

## Setup

1. Ensure Ollama is running with sufficient context:

```bash
# Set context window for tool calling
OLLAMA_NUM_CTX=16384 ollama serve
```

2. Launch OpenCode from the project root:

```bash
make opencode
```

OpenCode connects to the MCP server via stdio.

## Available Tools

### Read Tools

| Tool | Description |
|------|-------------|
| `query_transactions` | Filter transactions by date, category, account, type, text search |
| `get_spending_summary` | Category totals and monthly breakdown for a period |
| `get_budget_status` | All budgets with spent/remaining/percentage |
| `get_accounts` | Account balances and transaction counts |
| `get_import_status` | Recent import jobs with status and errors |
| `analyze_spending` | Pattern analysis: recurring, high_value, weekend_vs_weekday, category_spikes |

### Simple Answer Tools (optimized for local LLMs)

| Tool | Params | Description |
|------|--------|-------------|
| `get_total_expenses` | `months_back` (int, default 1) | Total expenses for past N months — single number |
| `get_total_income` | `months_back` (int, default 1) | Total income for past N months — single number |
| `get_monthly_totals` | `months_back` (int, default 3) | Income/expenses/net per month — short array |
| `get_top_categories` | `months_back` (int, default 3), `limit` (int, default 5) | Top spending categories ranked by total |
| `get_financial_overview` | none | Complete snapshot: this month summary, account balances, budget alerts |

These tools accept simple integer parameters and return pre-computed results. They are designed for local models (e.g., qwen2.5, mistral-small) that struggle with date arithmetic and large JSON responses.

### Write Tools

| Tool | Description |
|------|-------------|
| `create_budget` | Create a budget (category + monthly_limit + optional notes) |
| `update_budget` | Update budget monthly_limit and/or notes |
| `delete_budget` | Delete a budget by ID |
| `categorize_transaction` | Set/update category on a transaction |
| `add_note` | Add/update a note on a transaction |

## Testing the MCP Server

```bash
# Quick test - sends JSON-RPC initialize and checks response
make mcp-test

# Manual test
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | bundle exec ruby lib/mcp_server.rb
```

## Architecture

The MCP server (`lib/mcp_server.rb`) boots the Rails environment, loads tool classes from `app/mcp_tools/`, and communicates via JSON-RPC over stdio. Each tool is an `MCP::Tool` subclass that queries or mutates data through the existing Rails models and services.

## Troubleshooting

- **Ollama not responding**: Run `make ollama-status` and ensure `llama3.1:8b` is pulled
- **MCP server hangs**: Check stderr output - Rails boot errors appear there since stdout is reserved for JSON-RPC
- **Tool calling fails**: Increase Ollama context window with `OLLAMA_NUM_CTX=16384`
- **OpenCode not found**: Install with `npm i -g opencode`
