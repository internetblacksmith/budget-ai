# frozen_string_literal: true

class GetSpendingSummaryTool < MCP::Tool
  description "Get spending totals by category and monthly breakdown for a date range. " \
              "Returns category totals and month-by-month income/expense summary."

  input_schema(
    properties: {
      start_date: { type: "string", description: "Start date (YYYY-MM-DD). Defaults to 3 months ago." },
      end_date: { type: "string", description: "End date (YYYY-MM-DD). Defaults to today." }
    }
  )

  class << self
    def call(server_context: nil, **params)
      start_date = parse_date(params[:start_date], 3.months.ago.to_date)
      end_date = parse_date(params[:end_date], Date.current)
      transactions = Transaction.non_transfers.by_date_range(start_date.beginning_of_day, end_date.end_of_day)

      summary = {
        period: { start_date: start_date.to_s, end_date: end_date.to_s },
        category_totals: category_totals(transactions),
        monthly_breakdown: monthly_breakdown(transactions),
        totals: compute_totals(transactions)
      }

      MCP::Tool::Response.new([ { type: "text", text: summary.to_json } ])
    end

    private

    def parse_date(value, fallback)
      value.present? ? Date.parse(value) : fallback
    rescue Date::Error
      fallback
    end

    def category_totals(transactions)
      transactions
        .select(&:expense?)
        .group_by { |t| t.category || "Uncategorized" }
        .transform_values { |txs| txs.sum { |t| t.amount.abs }.round(2) }
        .sort_by { |_, amount| -amount }
        .to_h
    end

    def monthly_breakdown(transactions)
      transactions.group_by { |t| t.date.strftime("%Y-%m") }.map do |month, txs|
        income = txs.select(&:income?).sum(&:amount).round(2)
        expenses = txs.select(&:expense?).sum { |t| t.amount.abs }.round(2)
        { month: month, income: income, expenses: expenses, net: (income - expenses).round(2) }
      end.sort_by { |m| m[:month] }
    end

    def compute_totals(transactions)
      income = transactions.select(&:income?).sum(&:amount).round(2)
      expenses = transactions.select(&:expense?).sum { |t| t.amount.abs }.round(2)
      { total_income: income, total_expenses: expenses, net: (income - expenses).round(2) }
    end
  end
end
