# Analyzes transaction data for insights and patterns
class TransactionAnalyzer
  def initialize(transactions)
    @transactions = transactions
  end

  def summarize
    return "No transactions to analyze." if @transactions.empty?

    by_category = @transactions.group_by(&:category)
    summary = by_category.map do |category, txs|
      total = txs.sum { |t| t.amount.abs }
      count = txs.count
      avg = total / count
      "#{category || 'Uncategorized'}: #{count} transactions, £#{total.round(2)} total, £#{avg.round(2)} average"
    end

    summary.join("\n")
  end

  def category_spending
    @transactions
      .select { |t| t.amount < 0 } # Only expenses
      .group_by { |t| t.category || "Uncategorized" }
      .transform_values { |txs| txs.sum { |t| t.amount.abs } }
      .sort_by { |_, amount| -amount }
      .to_h
  end

  def recurring_transactions
    # Simple recurring detection based on description similarity
    @transactions
      .group_by { |t| t.description.downcase.split.first(3).join(" ") }
      .select { |_, txs| txs.count >= 2 }
  end

  def weekend_vs_weekday
    weekend = @transactions.select { |t| [ 0, 6 ].include?(t.date.wday) }
    weekday = @transactions.select { |t| ![ 0, 6 ].include?(t.date.wday) }

    {
      weekend: calculate_totals(weekend),
      weekday: calculate_totals(weekday),
      weekend_transactions: weekend,
      weekday_transactions: weekday
    }
  end

  def high_value_transactions(percentile = 95)
    amounts = @transactions.map { |t| t.amount.abs }.sort
    threshold = amounts.any? ? amounts[(amounts.length * percentile / 100.0).to_i] : 0
    @transactions.select { |t| t.amount.abs >= threshold }
  end

  def category_spikes
    return {} if @transactions.empty?

    monthly_data = @transactions.group_by { |t| t.date.beginning_of_month }
                               .transform_values { |txs| txs.group_by(&:category) }

    category_patterns = {}
    all_categories = @transactions.map(&:category).uniq.compact

    all_categories.each do |category|
      monthly_amounts = monthly_data.map do |month, categories|
        amount = categories[category]&.sum { |t| t.amount.abs } || 0
        [ month, amount ]
      end.sort_by(&:first)

      next if monthly_amounts.count < 2

      amounts = monthly_amounts.map(&:last)
      avg_amount = amounts.sum / amounts.count

      # Find significant spikes (>50% above average)
      spikes = monthly_amounts.select { |_, amount| amount > avg_amount * 1.5 }

      if spikes.any?
        spike_months = spikes.map { |month, amount| "#{month.strftime('%B %Y')}: £#{amount.round(2)}" }
        category_patterns[category] = {
          description: "Spikes in #{spike_months.join(', ')} (avg: £#{avg_amount.round(2)})",
          spike_count: spikes.count,
          avg_amount: avg_amount
        }
      end
    end

    category_patterns
  end

  private

  def calculate_totals(transactions)
    return { total: 0, average: 0, count: 0 } if transactions.empty?

    total = transactions.sum { |t| t.amount.abs }
    count = transactions.count
    average = total / count

    {
      total: total,
      average: average,
      count: count
    }
  end
end
