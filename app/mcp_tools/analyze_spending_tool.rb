# frozen_string_literal: true

class AnalyzeSpendingTool < MCP::Tool
  description "Analyze spending patterns using TransactionAnalyzer. Supports analysis types: " \
              "recurring, high_value, weekend_vs_weekday, category_spikes, and category_spending."

  input_schema(
    properties: {
      analysis_type: {
        type: "string",
        enum: %w[recurring high_value weekend_vs_weekday category_spikes category_spending],
        description: "Type of analysis to perform."
      },
      start_date: { type: "string", description: "Start date (YYYY-MM-DD). Defaults to 3 months ago." },
      end_date: { type: "string", description: "End date (YYYY-MM-DD). Defaults to today." }
    },
    required: [ "analysis_type" ]
  )

  class << self
    def call(analysis_type:, server_context: nil, **params)
      start_date = parse_date(params[:start_date], 3.months.ago.to_date)
      end_date = parse_date(params[:end_date], Date.current)
      transactions = Transaction.non_transfers.by_date_range(start_date.beginning_of_day, end_date.end_of_day).to_a
      analyzer = TransactionAnalyzer.new(transactions)

      result = case analysis_type
      when "recurring" then format_recurring(analyzer.recurring_transactions)
      when "high_value" then format_transactions(analyzer.high_value_transactions)
      when "weekend_vs_weekday" then format_weekend(analyzer.weekend_vs_weekday)
      when "category_spikes" then analyzer.category_spikes
      when "category_spending" then analyzer.category_spending
      end

      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end

    private

    def parse_date(value, fallback)
      value.present? ? Date.parse(value) : fallback
    rescue Date::Error
      fallback
    end

    def format_recurring(grouped)
      grouped.map do |key, txs|
        { pattern: key, count: txs.count, total: txs.sum { |t| t.amount.abs }.round(2) }
      end
    end

    def format_transactions(txs)
      txs.map do |t|
        { id: t.id, date: t.date.to_s, description: t.description, amount: t.amount.to_f }
      end
    end

    def format_weekend(data)
      {
        weekend: data[:weekend].except(:weekend_transactions, :weekday_transactions),
        weekday: data[:weekday].except(:weekend_transactions, :weekday_transactions)
      }
    end
  end
end
