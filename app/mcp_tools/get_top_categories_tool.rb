# frozen_string_literal: true

class GetTopCategoriesTool < MCP::Tool
  description "Get top spending categories ranked by total amount for the past N months. " \
              "Returns a short ranked list with totals and transaction counts."

  input_schema(
    properties: {
      months_back: {
        type: "integer",
        description: "Number of months to look back (default: 3)."
      },
      limit: {
        type: "integer",
        description: "Maximum number of categories to return (default: 5)."
      }
    }
  )

  class << self
    def call(server_context: nil, **params)
      months_back = [ (params[:months_back] || 3).to_i, 1 ].max
      limit = [ (params[:limit] || 5).to_i, 1 ].max
      start_date = (months_back - 1).months.ago.beginning_of_month.to_date
      end_date = Date.current

      transactions = Transaction.non_transfers.expenses
                                .by_date_range(start_date.beginning_of_day, end_date.end_of_day)
                                .to_a

      result = transactions
               .group_by { |t| t.category || "Uncategorized" }
               .map { |category, txs| build_category(category, txs) }
               .sort_by { |c| -c[:total] }
               .first(limit)

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end

    private

    def build_category(category, txs)
      {
        category: category,
        total: txs.sum { |t| t.amount.abs }.to_f.round(2),
        transaction_count: txs.size
      }
    end
  end
end
