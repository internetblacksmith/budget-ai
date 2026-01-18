# frozen_string_literal: true

class AddNoteTool < MCP::Tool
  description "Add or update a note on a transaction."

  input_schema(
    properties: {
      id: { type: "integer", description: "Transaction ID." },
      note: { type: "string", description: "Note text to set on the transaction." }
    },
    required: %w[id note]
  )

  class << self
    def call(id:, note:, server_context: nil, **_params)
      transaction = Transaction.find_by(id: id)
      unless transaction
        return MCP::Tool::Response.new(
          [ { type: "text", text: { success: false, error: "Transaction not found" }.to_json } ]
        )
      end

      transaction.update!(notes: note)
      TransactionEdit.record_edit(transaction, { notes: note })
      result = {
        success: true,
        transaction: {
          id: transaction.id,
          description: transaction.description,
          notes: transaction.notes
        }
      }

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end
  end
end
