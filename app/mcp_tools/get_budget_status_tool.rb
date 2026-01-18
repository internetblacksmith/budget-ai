# frozen_string_literal: true

class GetBudgetStatusTool < MCP::Tool
  description "Get all budgets with current month spending, remaining amount, percentage used, " \
              "and over-budget status. No parameters required."

  input_schema(
    properties: {}
  )

  class << self
    def call(server_context: nil, **_params)
      budgets = Budget.order(:category).map do |b|
        {
          id: b.id,
          category: b.category,
          monthly_limit: b.monthly_limit.to_f.round(2),
          spent_this_month: b.spent_this_month.to_f.round(2),
          remaining: b.remaining.to_f.round(2),
          percentage_used: b.percentage_used,
          over_budget: b.over_budget?,
          notes: b.notes
        }
      end

      MCP::Tool::Response.new([ { type: "text", text: budgets.to_json } ])
    end
  end
end
