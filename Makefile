# Budget AI - Makefile for common tasks
#
# Quick commands:
#   make help  - Show all commands with examples
#   make list  - Quick list of available commands
#   make       - Interactive menu
.PHONY: help list menu menu-simple server demo test lint fix install db-setup console opencode mcp-test

# Default target - show interactive menu
.DEFAULT_GOAL := menu

# Interactive menu - simple numbered menu
menu:
	@echo "╔══════════════════════════════════════════════════════╗"
	@echo "║              Budget AI - Command Menu                ║"
	@echo "╚══════════════════════════════════════════════════════╝"
	@echo ""
	@echo "  === Development ==="
	@echo "  1) Start Rails server"
	@echo "  2) Start worker (SolidQueue)"
	@echo "  3) Start complete dev environment (tmux)"
	@echo ""
	@echo "  === Import (Emma) ==="
	@echo "  4) Show Emma import guide"
	@echo "  5) Test Emma import service"
	@echo "  6) Check recent import status"
	@echo ""
	@echo "  === Development Tools ==="
	@echo "  7) Run all tests"
	@echo "  8) Run linter"
	@echo "  9) Auto-fix code style"
	@echo "  10) Pre-commit check"
	@echo ""
	@echo "  === AI Budgeting (Ollama) ==="
	@echo "  11) Setup Ollama (AI service)"
	@echo "  12) Start Ollama service"
	@echo "  13) Check Ollama status"
	@echo "  14) Test AI connection"
	@echo ""
	@echo "  === MCP / OpenCode ==="
	@echo "  15) Launch OpenCode (terminal AI agent)"
	@echo "  16) Test MCP server"
	@echo ""
	@echo "  === Database ==="
	@echo "  17) Setup database (first time)"
	@echo "  18) Run migrations"
	@echo ""
	@echo "  === Other ==="
	@echo "  19) Rails console"
	@echo "  20) Install dependencies"
	@echo "  h) Show help"
	@echo "  q) Quit"
	@echo ""
	@read -p "Enter your choice: " choice; \
	case $$choice in \
		1) $(MAKE) server ;; \
		2) $(MAKE) worker ;; \
		3) $(MAKE) dev ;; \
		4) $(MAKE) emma-guide ;; \
		5) $(MAKE) emma-test ;; \
		6) $(MAKE) emma-status ;; \
		7) $(MAKE) test ;; \
		8) $(MAKE) lint ;; \
		9) $(MAKE) fix ;; \
		10) $(MAKE) commit-check ;; \
		11) $(MAKE) ollama-setup ;; \
		12) $(MAKE) ollama-start ;; \
		13) $(MAKE) ollama-status ;; \
		14) $(MAKE) ollama-test ;; \
		15) $(MAKE) opencode ;; \
		16) $(MAKE) mcp-test ;; \
		17) $(MAKE) db-setup ;; \
		18) $(MAKE) migrate ;; \
		19) $(MAKE) console ;; \
		20) $(MAKE) install ;; \
		h|H) $(MAKE) help ;; \
		q|Q) echo "Goodbye!" ;; \
		*) echo "Invalid choice. Please try again." && $(MAKE) menu ;; \
	esac

# Help target - show all available commands with examples
help:
	@echo "╔══════════════════════════════════════════════════════╗"
	@echo "║              Budget AI - Available Commands          ║"
	@echo "╚══════════════════════════════════════════════════════╝"
	@echo ""
	@echo "🚀 DEVELOPMENT:"
	@echo "  make              - Show interactive menu"
	@echo "  make server       - Start Rails server"
	@echo "  make worker       - Start SolidQueue worker (for background jobs)"
	@echo "  make worker-stop  - Stop SolidQueue worker"
	@echo "  make dev          - Start tmux dev environment"
	@echo "  make console      - Start Rails console"
	@echo ""
	@echo "📥 EMMA IMPORT:"
	@echo "  make emma-guide   - Show Emma import guide"
	@echo "  make emma-test    - Test Emma import service"
	@echo "  make emma-status  - Show recent import status"
	@echo ""
	@echo "🧪 TESTING & QUALITY:"
	@echo "  make test         - Run all tests (RSpec)"
	@echo "  make lint         - Run Rubocop linter"
	@echo "  make fix          - Auto-fix Rubocop violations"
	@echo "  make commit-check - Pre-commit check (tests + lint)"
	@echo ""
	@echo "🔌 MCP / OPENCODE:"
	@echo "  make opencode     - Launch OpenCode terminal AI agent"
	@echo "  make mcp-test     - Test MCP server with JSON-RPC initialize"
	@echo ""
	@echo "🤖 AI BUDGETING (OLLAMA):"
	@echo "  make ollama-setup   - Install Ollama and download AI model"
	@echo "  make ollama-start   - Start Ollama service"
	@echo "  make ollama-stop    - Stop Ollama service"
	@echo "  make ollama-status  - Check if Ollama is running"
	@echo "  make ollama-test    - Test AI connection"
	@echo ""
	@echo "💾 DATABASE:"
	@echo "  make db-setup     - Create and migrate database"
	@echo "  make migrate      - Run database migrations"
	@echo ""
	@echo "📦 MAINTENANCE:"
	@echo "  make install      - Install dependencies"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "⚡ COMMON WORKFLOWS:"
	@echo "  📋 First time setup:"
	@echo "     make install db-setup server"
	@echo ""
	@echo "  🧪 Before committing:"
	@echo "     make commit-check"
	@echo ""
	@echo "  📥 Import transactions:"
	@echo "     make emma-guide"
	@echo ""
	@echo "💡 Tip: Run 'make' (no arguments) for an interactive menu"

# Quick list of all available targets (no descriptions)
list:
	@echo "Available make targets:"
	@echo "  help menu server worker worker-stop worker-restart console dev"
	@echo "  emma-guide emma-test emma-status"
	@echo "  ollama-setup ollama-start ollama-stop ollama-status ollama-test"
	@echo "  opencode mcp-test"
	@echo "  test lint fix commit-check"
	@echo "  install db-setup migrate"
	@echo ""
	@echo "Run 'make help' for detailed descriptions"

# Development commands
.PHONY: server
dev:
	@echo "🎨 Starting tmux development environment..."
	@./scripts/setup-dev-tmux.sh

.PHONY: server
server:
	@echo "🚀 Starting Rails server..."
	@bundle exec rails db:migrate
	@bundle exec rails server

.PHONY: worker
worker:
	@echo "⚙️ Starting SolidQueue worker..."
	@bundle exec rake solid_queue:start

.PHONY: worker-stop
worker-stop:
	@echo "🛑 Stopping SolidQueue worker..."
	@bundle exec rake solid_queue:stop

.PHONY: worker-restart
worker-restart:
	@echo "🔄 Restarting SolidQueue worker..."
	@bundle exec rake solid_queue:restart

.PHONY: demo
demo:
	@echo "🎭 Starting demo server with mock data..."
	@MOCK_DATA=true bundle exec rails server

.PHONY: console
console:
	@echo "💻 Starting Rails console..."
	@bundle exec rails console

# Testing
.PHONY: test
test:
	@echo "🧪 Running all tests..."
	@bundle exec rspec

.PHONY: lint
lint:
	@echo "🔍 Running Rubocop..."
	@bundle exec rubocop

.PHONY: fix
fix:
	@echo "🔧 Auto-fixing Rubocop violations..."
	@bundle exec rubocop -a

.PHONY: commit-check
commit-check:
	@echo "✅ Running pre-commit checks..."
	@echo "1. Running Rubocop..."
	@bundle exec rubocop
	@echo "2. Running tests..."
	@bundle exec rspec
	@echo "✅ All checks passed!"

# Database
.PHONY: db-setup
db-setup:
	@echo "💾 Setting up database..."
	@bundle exec rails db:create db:migrate

.PHONY: migrate
migrate:
	@echo "🔄 Running migrations..."
	@bundle exec rails db:migrate

# Emma Import Commands
emma-guide:
	@echo "📚 Emma Import Guide"
	@echo ""
	@echo "Quick Steps:"
	@echo "1. Open Emma app → Profile → Settings → Export to Google Sheets"
	@echo "2. In Budget AI: Import Transactions → Connect Google → Select Spreadsheet"
	@echo ""
	@echo "Full guide: docs/EMMA_INTEGRATION.md"

emma-test:
	@echo "🧪 Testing Emma import service..."
	@bundle exec rails runner "puts EmmaSpreadsheetImportService.new('test').public_methods(false).grep(/import|parse/)"

emma-status:
	@echo "📊 Recent Emma Imports:"
	@bundle exec rails runner "
		imports = ImportJob.where(source: 'emma_export').order(created_at: :desc).limit(5);
		if imports.any?;
			imports.each { |i| puts \"#{i.created_at.strftime('%Y-%m-%d')} - #{i.imported_count} transactions (#{i.status})\" };
		else;
			puts 'No Emma imports found';
		end;
	"

# Installation
.PHONY: install
install:
	@echo "📦 Installing dependencies..."
	@bundle install

# AI Budgeting - Ollama Integration
.PHONY: ollama-setup ollama-start ollama-stop ollama-status ollama-test

ollama-setup:
	@echo "🤖 Setting up Ollama for AI budgeting..."
	@echo ""
	@echo "Step 1: Checking if Ollama is installed..."
	@if ! command -v ollama >/dev/null 2>&1; then \
		echo "❌ Ollama not found. Installing..."; \
		curl -fsSL https://ollama.com/install.sh | sh; \
		echo "Waiting for Ollama service to start..."; \
		for i in 1 2 3 4 5 6 7 8 9 10; do \
			curl -sf http://localhost:11434/ >/dev/null 2>&1 && break; \
			sleep 2; \
		done; \
	else \
		echo "✅ Ollama already installed"; \
	fi
	@echo ""
	@if ! curl -sf http://localhost:11434/ >/dev/null 2>&1; then \
		echo "Starting Ollama service..."; \
		ollama serve &>/dev/null & \
		sleep 3; \
	fi
	@echo "Step 2: Pulling llama2 model (this may take a few minutes)..."
	@ollama pull llama2
	@echo ""
	@echo "✅ Ollama setup complete!"
	@echo "   Run 'make ollama-start' to start the service"

ollama-start:
	@echo "🚀 Starting Ollama service..."
	@if pgrep -x "ollama" >/dev/null; then \
		echo "✅ Ollama is already running"; \
	else \
		ollama serve & \
		sleep 2; \
		echo "✅ Ollama started!"; \
	fi
	@echo ""
	@echo "💡 You can now use AI features in the Budget AI app"
	@echo "   The AI will analyze your transactions and provide insights"

ollama-stop:
	@echo "🛑 Stopping Ollama service..."
	@pkill -x ollama 2>/dev/null || true
	@echo "✅ Ollama stopped"

ollama-status:
	@echo "🔍 Checking Ollama status..."
	@echo ""
	@if pgrep -x "ollama" >/dev/null; then \
		echo "✅ Ollama is running"; \
		ollama list 2>/dev/null || echo "   No models downloaded yet. Run 'make ollama-setup'"; \
	else \
		echo "❌ Ollama is not running"; \
		echo "   Run 'make ollama-start' to start it"; \
	fi

ollama-test:
	@echo "🧪 Testing AI connection..."
	@if ! pgrep -x "ollama" >/dev/null; then \
		echo "❌ Ollama is not running. Starting it now..."; \
		$(MAKE) ollama-start; \
		sleep 3; \
	fi
	@echo ""
	@echo "Testing AI with a simple prompt..."
	@curl -s http://localhost:11434/api/generate -d '{"model":"llama2","prompt":"Hello!","stream":false}' | grep -q "response" && echo "✅ AI is working!" || echo "❌ AI test failed"
	@echo ""
	@echo "💡 Your transactions can now be analyzed by AI"
	@echo "   Import data and visit the Insights page to see AI analysis"

# MCP / OpenCode
.PHONY: opencode mcp-test

opencode:
	@echo "🔌 Launching OpenCode with Budget AI MCP tools..."
	@if ! command -v opencode >/dev/null 2>&1; then \
		echo "❌ OpenCode not found. Install it first:"; \
		echo "   npm i -g opencode"; \
		exit 1; \
	fi
	@opencode

mcp-test:
	@echo "🧪 Testing MCP server..."
	@echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | bundle exec ruby mcp_server.rb 2>/dev/null | head -1 | ruby -rjson -e 'r = JSON.parse(STDIN.read); puts r["result"] ? "✅ MCP server responding (#{r["result"]["serverInfo"]["name"]})" : "❌ Unexpected response"'
