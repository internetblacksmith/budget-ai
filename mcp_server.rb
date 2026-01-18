# frozen_string_literal: true

# MCP Server entry point for Budget AI
#
# Boots Rails environment and exposes financial data tools via
# the Model Context Protocol (JSON-RPC over stdio).
#
# Usage:
#   bundle exec ruby mcp_server.rb
#
# Stdout must remain clean JSON-RPC, so redirect all Rails logging to stderr.

require_relative "config/environment"

Rails.logger = ActiveSupport::Logger.new($stderr)
ActiveRecord::Base.logger = nil

# Load all MCP tool classes
Dir[Rails.root.join("app/mcp_tools/**/*.rb")].each { |f| require f }

MCP_TOOLS = [
  QueryTransactionsTool,
  GetSpendingSummaryTool,
  GetBudgetStatusTool,
  GetAccountsTool,
  GetImportStatusTool,
  AnalyzeSpendingTool,
  GetTotalExpensesTool,
  GetTotalIncomeTool,
  GetMonthlyTotalsTool,
  GetTopCategoriesTool,
  GetFinancialOverviewTool,
  CreateBudgetTool,
  UpdateBudgetTool,
  DeleteBudgetTool,
  CategorizeTransactionTool,
  AddNoteTool
].freeze

server = MCP::Server.new(
  name: "budget-ai",
  version: "1.0.0",
  tools: MCP_TOOLS
)

transport = MCP::Server::Transports::StdioTransport.new(server)
transport.open
