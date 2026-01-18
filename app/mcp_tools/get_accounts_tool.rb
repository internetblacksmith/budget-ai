# frozen_string_literal: true

class GetAccountsTool < MCP::Tool
  description "Get all accounts with balances, income/expense totals, and transaction counts."

  input_schema(
    properties: {}
  )

  class << self
    def call(server_context: nil, **_params)
      stats = CachedStatisticsService.new.get_account_statistics
      MCP::Tool::Response.new([ { type: "text", text: stats.to_json } ])
    end
  end
end
