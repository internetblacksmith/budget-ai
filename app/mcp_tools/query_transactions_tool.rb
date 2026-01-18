# frozen_string_literal: true

class QueryTransactionsTool < MCP::Tool
  description "Filter and search transactions by date range, category, account, type (income/expense), " \
              "and text search. Returns a JSON array of matching transactions."

  input_schema(
    properties: {
      start_date: { type: "string", description: "Start date (YYYY-MM-DD). Defaults to 3 months ago." },
      end_date: { type: "string", description: "End date (YYYY-MM-DD). Defaults to today." },
      category: { type: "string", description: "Filter by category name (exact match)." },
      account: { type: "string", description: "Filter by account name." },
      type: { type: "string", enum: %w[income expense], description: "Filter by income or expense." },
      search: { type: "string", description: "Text search in transaction descriptions." },
      limit: { type: "integer", description: "Max results to return. Defaults to 50." }
    }
  )

  class << self
    def call(server_context: nil, **params)
      scope = Transaction.all

      start_date = parse_date(params[:start_date], 3.months.ago.to_date)
      end_date = parse_date(params[:end_date], Date.current)
      scope = scope.by_date_range(start_date.beginning_of_day, end_date.end_of_day)

      scope = scope.by_account(params[:account]) if params[:account].present?
      scope = scope.where(category: params[:category]) if params[:category].present?

      case params[:type]
      when "income" then scope = scope.income
      when "expense" then scope = scope.expenses
      end

      scope = scope.where("description LIKE ?", "%#{params[:search]}%") if params[:search].present?

      limit = (params[:limit] || 50).to_i.clamp(1, 500)
      transactions = scope.order(date: :desc).limit(limit)

      json = transactions.map { |t| serialize_transaction(t) }
      MCP::Tool::Response.new([ { type: "text", text: json.to_json } ])
    end

    private

    def parse_date(value, fallback)
      value.present? ? Date.parse(value) : fallback
    rescue Date::Error
      fallback
    end

    def serialize_transaction(t)
      {
        id: t.id,
        date: t.date.to_s,
        description: t.description,
        amount: t.amount.to_f,
        category: t.category,
        account: t.account,
        is_transfer: t.is_transfer
      }
    end
  end
end
