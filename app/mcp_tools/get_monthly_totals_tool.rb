# frozen_string_literal: true

class GetMonthlyTotalsTool < MCP::Tool
  description "Get income, expenses, and net for each of the past N months. " \
              "Returns a short array with one entry per month, pre-computed."

  input_schema(
    properties: {
      months_back: {
        type: "integer",
        description: "Number of months to include (default: 3)."
      }
    }
  )

  class << self
    def call(server_context: nil, **params)
      months_back = [ (params[:months_back] || 3).to_i, 1 ].max
      start_date = (months_back - 1).months.ago.beginning_of_month.to_date
      end_date = Date.current

      transactions = Transaction.non_transfers
                                .by_date_range(start_date.beginning_of_day, end_date.end_of_day)
                                .to_a

      result = transactions.group_by { |t| t.date.strftime("%b %Y") }
                           .map { |month, txs| build_month(month, txs) }
                           .sort_by { |m| Date.parse("1 #{m[:month]}") }

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end

    private

    def build_month(month, txs)
      income = txs.select(&:income?).sum(&:amount).to_f.round(2)
      expenses = txs.select(&:expense?).sum { |t| t.amount.abs }.to_f.round(2)
      {
        month: month,
        income: income,
        expenses: expenses,
        net: (income - expenses).round(2)
      }
    end
  end
end
