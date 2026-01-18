# frozen_string_literal: true

class CategorizeTransactionTool < MCP::Tool
  description "Set or update the category on a transaction."

  input_schema(
    properties: {
      id: { type: "integer", description: "Transaction ID to categorize." },
      category: { type: "string", description: "Category name to assign." }
    },
    required: %w[id category]
  )

  class << self
    def call(id:, category:, server_context: nil, **_params)
      transaction = Transaction.find_by(id: id)
      unless transaction
        return MCP::Tool::Response.new(
          [ { type: "text", text: { success: false, error: "Transaction not found" }.to_json } ]
        )
      end

      transaction.update!(category: category)
      TransactionEdit.record_edit(transaction, { category: category })
      result = {
        success: true,
        transaction: {
          id: transaction.id,
          description: transaction.description,
          category: transaction.category
        }
      }

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end
  end
end
