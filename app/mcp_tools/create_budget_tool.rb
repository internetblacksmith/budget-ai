# frozen_string_literal: true

class CreateBudgetTool < MCP::Tool
  description "Create a new monthly budget for a spending category."

  input_schema(
    properties: {
      category: { type: "string", description: "Spending category name (e.g. Groceries, Transport)." },
      monthly_limit: { type: "number", description: "Monthly spending limit in GBP." },
      notes: { type: "string", description: "Optional notes about this budget." }
    },
    required: %w[category monthly_limit]
  )

  class << self
    def call(category:, monthly_limit:, server_context: nil, **params)
      budget = Budget.new(category: category, monthly_limit: monthly_limit, notes: params[:notes])

      if budget.save
        result = { success: true, budget: serialize(budget) }
      else
        result = { success: false, errors: budget.errors.full_messages }
      end

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end

    private

    def serialize(b)
      { id: b.id, category: b.category, monthly_limit: b.monthly_limit.to_f.round(2), notes: b.notes }
    end
  end
end
