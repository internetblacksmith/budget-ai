# frozen_string_literal: true

class UpdateBudgetTool < MCP::Tool
  description "Update an existing budget's monthly limit and/or notes."

  input_schema(
    properties: {
      id: { type: "integer", description: "Budget ID to update." },
      monthly_limit: { type: "number", description: "New monthly spending limit in GBP." },
      notes: { type: "string", description: "New notes for this budget." }
    },
    required: %w[id]
  )

  class << self
    def call(id:, server_context: nil, **params)
      budget = Budget.find_by(id: id)
      unless budget
        return MCP::Tool::Response.new([ { type: "text", text: { success: false, error: "Budget not found" }.to_json } ])
      end

      attrs = {}
      attrs[:monthly_limit] = params[:monthly_limit] if params.key?(:monthly_limit)
      attrs[:notes] = params[:notes] if params.key?(:notes)

      if budget.update(attrs)
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
