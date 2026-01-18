# frozen_string_literal: true

class DeleteBudgetTool < MCP::Tool
  description "Delete a budget by ID."

  input_schema(
    properties: {
      id: { type: "integer", description: "Budget ID to delete." }
    },
    required: %w[id]
  )

  class << self
    def call(id:, server_context: nil, **_params)
      budget = Budget.find_by(id: id)
      unless budget
        return MCP::Tool::Response.new([ { type: "text", text: { success: false, error: "Budget not found" }.to_json } ])
      end

      budget.destroy
      MCP::Tool::Response.new([ { type: "text", text: { success: true, deleted_category: budget.category }.to_json } ])
    end
  end
end
