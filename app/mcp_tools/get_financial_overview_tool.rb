# frozen_string_literal: true

class GetFinancialOverviewTool < MCP::Tool
  description "Get a complete financial overview in a single call. Includes this month's income, " \
              "expenses, net, account balances, and budget alerts. No parameters needed."

  input_schema(
    properties: {}
  )

  class << self
    def call(server_context: nil, **_params)
      result = {
        this_month: this_month_summary,
        accounts: account_balances,
        budget_alerts: budget_alerts
      }

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end

    private

    def this_month_summary
      start_date = Date.current.beginning_of_month.beginning_of_day
      end_date = Date.current.end_of_day
      transactions = Transaction.non_transfers.by_date_range(start_date, end_date.to_date)

      income = transactions.income.sum(:amount).to_f.round(2)
      expenses = transactions.expenses.sum(:amount).abs.to_f.round(2)

      {
        month: Date.current.strftime("%b %Y"),
        income: income,
        expenses: expenses,
        net: (income - expenses).round(2)
      }
    end

    def account_balances
      Transaction.distinct.pluck(:account).map do |account|
        txs = Transaction.where(account: account)
        {
          account: account,
          balance: txs.sum(:amount).to_f.round(2),
          transaction_count: txs.count
        }
      end
    end

    def budget_alerts
      Budget.order(:category).filter_map do |b|
        next unless b.percentage_used >= 80

        {
          category: b.category,
          monthly_limit: b.monthly_limit.to_f.round(2),
          spent: b.spent_this_month.to_f.round(2),
          percentage_used: b.percentage_used,
          over_budget: b.over_budget?
        }
      end
    end
  end
end
