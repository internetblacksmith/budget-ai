# frozen_string_literal: true

class GetTotalIncomeTool < MCP::Tool
  description "Get total income for the past N months. Returns a single number with period label. " \
              "Simple alternative to get_spending_summary when you just need the income total."

  input_schema(
    properties: {
      months_back: {
        type: "integer",
        description: "Number of months to look back (default: 1). Use 1 for current month."
      }
    }
  )

  class << self
    def call(server_context: nil, **params)
      months_back = [ (params[:months_back] || 1).to_i, 1 ].max
      start_date = (months_back - 1).months.ago.beginning_of_month.to_date
      end_date = Date.current

      transactions = Transaction.non_transfers.income
                                .by_date_range(start_date.beginning_of_day, end_date.end_of_day)

      total = transactions.sum(:amount).to_f.round(2)

      result = {
        total_income: total,
        period: format_period(start_date, end_date),
        months: months_back
      }

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end

    private

    def format_period(start_date, end_date)
      if start_date.strftime("%b %Y") == end_date.strftime("%b %Y")
        start_date.strftime("%b %Y")
      else
        "#{start_date.strftime('%b %Y')} - #{end_date.strftime('%b %Y')}"
      end
    end
  end
end
