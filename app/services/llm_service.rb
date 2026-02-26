# Orchestrates LLM interactions: prompt building, context assembly, and client calls
class LlmService
  delegate :LlmError, :ConnectionError, :TimeoutError, to: :class

  def self.LlmError
    LlmClient::LlmError
  end

  def self.ConnectionError
    LlmClient::ConnectionError
  end

  def self.TimeoutError
    LlmClient::TimeoutError
  end

  def initialize
    @config = self.class.cached_config
    @client = LlmClient.new(@config)
  end

  def self.cached_config
    @cached_config ||= load_config
  end

  def self.load_config
    config_file = Rails.root.join("config", "llm.yml")
    erb_content = ERB.new(File.read(config_file)).result
    config = YAML.safe_load(erb_content, aliases: true)[Rails.env]
    config.deep_symbolize_keys
  end

  def self.reset_config!
    @cached_config = nil
  end

  def analyze_spending(transactions, options = {})
    analyzer = TransactionAnalyzer.new(transactions)
    prompt = spending_analysis_prompt(analyzer, options)
    @client.generate(prompt)
  end

  def suggest_budget(account_stats, monthly_data, options = {})
    all_transactions = monthly_data.flat_map { |m| m[:transactions].to_a }
    analyzer = TransactionAnalyzer.new(all_transactions)
    prompt = budget_suggestion_prompt(analyzer, account_stats, monthly_data: monthly_data)
    @client.generate(prompt)
  end

  def categorize_transaction(transaction)
    prompt = transaction_categorization_prompt(transaction)
    @client.generate(prompt, temperature: 0.3, max_tokens: 50)
  end

  def chat(message)
    context = Transaction.financial_context
    prompt = chat_prompt(message, context)
    @client.generate(prompt)
  end

  def explain_spending_pattern(transactions, pattern_type)
    analyzer = TransactionAnalyzer.new(transactions)
    prompt = pattern_explanation_prompt(analyzer, pattern_type)
    @client.generate(prompt)
  end

  def stream_analyze_spending(transactions, options = {}, &block)
    analyzer = TransactionAnalyzer.new(transactions)
    prompt = spending_analysis_prompt(analyzer, options)
    @client.generate_stream(prompt, &block)
  end

  def stream_suggest_budget(account_stats, monthly_data, &block)
    all_transactions = monthly_data.flat_map { |m| m[:transactions].to_a }
    analyzer = TransactionAnalyzer.new(all_transactions)
    prompt = budget_suggestion_prompt(analyzer, account_stats, monthly_data: monthly_data)
    @client.generate_stream(prompt, &block)
  end

  def stream_explain_pattern(transactions, pattern_type, &block)
    analyzer = TransactionAnalyzer.new(transactions)
    prompt = pattern_explanation_prompt(analyzer, pattern_type)
    @client.generate_stream(prompt, &block)
  end

  private

  # -- Prompt builders --

  PERIOD_LABELS = {
    "today" => "today",
    "this_week" => "this week",
    "last_week" => "last week",
    "this_month" => "this month",
    "last_month" => "last month",
    "last_3_months" => "the last 3 months"
  }.freeze

  def spending_analysis_prompt(analyzer, options)
    period = PERIOD_LABELS[options[:period]] || "this month"
    account = options[:account].present? ? options[:account].to_s.truncate(50) : "all accounts"

    <<~PROMPT
      Analyze the following spending data for #{period} from #{account}:

      #{analyzer.summarize}

      Please provide:
      1. Key spending patterns and trends
      2. Unusual or concerning expenses
      3. Opportunities to reduce spending
      4. Positive financial behaviors to maintain

      Keep the analysis concise and actionable.
    PROMPT
  end

  def budget_suggestion_prompt(analyzer, account_stats, monthly_data:)
    month_count = [ monthly_data.size, 1 ].max

    monthly_breakdown = monthly_data.map do |m|
      txns = m[:transactions].to_a
      income = txns.select { |t| t.amount > 0 }.sum(&:amount)
      expenses = txns.select { |t| t.amount < 0 }.sum(&:amount).abs
      { month: m[:month], income: income, expenses: expenses, net: income - expenses }
    end

    avg_income = monthly_breakdown.sum { |m| m[:income] } / month_count
    avg_expenses = monthly_breakdown.sum { |m| m[:expenses] } / month_count
    avg_net = avg_income - avg_expenses

    category_spending = analyzer.category_spending
    avg_category = category_spending.transform_values { |v| (v.abs / month_count).round(2) }

    breakdown_lines = monthly_breakdown.map do |m|
      label = Date.parse("#{m[:month]}-01").strftime("%b %Y")
      "- #{label}: Income £#{m[:income].round(2)}, Expenses £#{m[:expenses].round(2)}, Net £#{m[:net].round(2)}"
    end

    <<~PROMPT
      Based on financial data across #{month_count} selected month#{"s" if month_count != 1}:

      Monthly Breakdown:
      #{breakdown_lines.join("\n")}

      Averages (across #{month_count} month#{"s" if month_count != 1}):
        Average Monthly Income: £#{avg_income.round(2)}
        Average Monthly Expenses: £#{avg_expenses.round(2)}
        Average Monthly Net: £#{avg_net.round(2)}

      Average Spending by Category:
      #{avg_category.map { |cat, amount| "- #{cat}: £#{amount}/month" }.join("\n")}

      Please suggest:
      1. A realistic monthly budget allocation
      2. Areas where spending could be optimized
      3. Recommended savings target
      4. Priority areas for budget adjustments

      Consider the 50/30/20 rule but adapt to this person's situation.
    PROMPT
  end

  def transaction_categorization_prompt(transaction)
    <<~PROMPT
      Categorize this transaction:

      Description: #{transaction.description}
      Amount: £#{transaction.amount.abs}
      Date: #{transaction.date}

      Choose the most appropriate category from:
      - Groceries
      - Transport
      - Bills
      - Entertainment
      - Dining
      - Shopping
      - Health
      - Savings
      - Other

      Respond with just the category name.
    PROMPT
  end

  def chat_prompt(user_message, context)
    <<~PROMPT
      You are a helpful financial assistant for a personal budgeting app.
      All figures below are PRE-CALCULATED and CORRECT — report them as-is, do NOT recalculate.
      Use £ for currency. Be concise and helpful.

      === OVERVIEW ===
      Total transactions: #{context[:transaction_count] || 0}
      Date range: #{format_date(context.dig(:date_range, :earliest))} to #{format_date(context.dig(:date_range, :latest))}

      #{format_totals(context[:totals])}

      #{format_monthly_breakdown(context[:monthly_breakdown])}

      #{format_category_spending_by_month(context[:category_spending_by_month])}

      #{format_budgets(context[:budgets])}

      #{format_recurring_transactions(context[:recurring_transactions])}

      === USER MESSAGE ===
      #{user_message}

      IMPORTANT: All numbers above are exact. Use them directly in your response. Do not estimate or recalculate. If the user asks about creating or adjusting budgets, suggest specific amounts based on the spending data above.
    PROMPT
  end

  def pattern_explanation_prompt(analyzer, pattern_type)
    case pattern_type
    when :weekend_spending
      weekend_spending_prompt(analyzer)
    when :recurring
      recurring_prompt(analyzer)
    when :high_value
      high_value_prompt(analyzer)
    when :category_spike
      category_spike_prompt(analyzer)
    else
      raise ArgumentError, "Unknown pattern type: #{pattern_type.inspect}"
    end
  end

  # -- Pattern-specific prompt builders --

  def weekend_spending_prompt(analyzer)
    data = analyzer.weekend_vs_weekday
    weekend = data[:weekend_transactions]
    weekday = data[:weekday_transactions]

    weekend_total = data[:weekend][:total]
    weekend_avg = data[:weekend][:average]
    weekday_total = data[:weekday][:total]
    weekday_avg = data[:weekday][:average]

    <<~PROMPT
      Analyze the weekend vs weekday spending pattern:

      **Weekend Spending:**
      - Total: £#{weekend_total.round(2)} (#{weekend.count} transactions)
      - Average per transaction: £#{weekend_avg.round(2)}
      - Top categories: #{weekend.group_by(&:category).transform_values(&:count).sort_by { |_, v| -v }.first(3).map { |k, v| "#{k}: #{v}" }.join(", ")}

      **Weekday Spending:**
      - Total: £#{weekday_total.round(2)} (#{weekday.count} transactions)
      - Average per transaction: £#{weekday_avg.round(2)}
      - Top categories: #{weekday.group_by(&:category).transform_values(&:count).sort_by { |_, v| -v }.first(3).map { |k, v| "#{k}: #{v}" }.join(", ")}

      Please analyze:
      1. Key differences between weekend and weekday spending
      2. What drives higher weekend spending (if applicable)
      3. Opportunities to optimize weekend spending
      4. Strategies to balance weekend enjoyment with financial goals
    PROMPT
  end

  def recurring_prompt(analyzer)
    recurring = analyzer.recurring_transactions

    if recurring.any?
      recurring_summary = recurring.map do |desc, txs|
        total = txs.sum { |t| t.amount.abs }
        avg = total / txs.count
        "#{desc}: #{txs.count} times, £#{total.round(2)} total, £#{avg.round(2)} average"
      end.join("\n")

      <<~PROMPT
        Analyze these recurring payment patterns:

        #{recurring_summary}

        Please provide:
        1. Essential vs optional recurring payments
        2. Opportunities to reduce recurring costs
        3. Missing subscriptions that might not be captured
        4. Recommendations for subscription management
        5. Potential savings from canceling or downgrading services
      PROMPT
    else
      <<~PROMPT
        No clear recurring transaction patterns detected in the data.

        This could mean:
        1. Most transactions are one-off purchases
        2. Recurring payments vary in description/amount
        3. The time period analyzed is too short

        Consider reviewing a longer time period or checking for subscriptions that might be using different transaction descriptions.
      PROMPT
    end
  end

  def high_value_prompt(analyzer)
    high_value = analyzer.high_value_transactions
    threshold = high_value.any? ? high_value.map { |t| t.amount.abs }.min : 0

    if high_value.any?
      high_value_summary = high_value.map do |t|
        "£#{t.amount.abs.round(2)} - #{t.description} (#{t.date.strftime('%d/%m/%Y')})"
      end.join("\n")

      <<~PROMPT
        Analyze high-value spending patterns (transactions £#{threshold.round(2)} and above):

        #{high_value_summary}

        Total high-value spending: £#{high_value.sum { |t| t.amount.abs }.round(2)}
        Number of high-value transactions: #{high_value.count}
        Categories involved: #{high_value.map(&:category).uniq.compact.join(", ")}

        Please analyze:
        1. Are these high-value purchases planned or impulsive?
        2. Which categories drive the largest expenses?
        3. Patterns in timing (monthly, seasonal, etc.)
        4. Strategies to better plan for large expenses
        5. Potential alternatives or ways to reduce these costs
      PROMPT
    else
      "No significant high-value transactions detected. Most spending appears to be consistent with regular patterns."
    end
  end

  def category_spike_prompt(analyzer)
    spikes = analyzer.category_spikes

    if spikes.any?
      spike_summary = spikes.map do |category, data|
        "#{category}: #{data[:description]}"
      end.join("\n")

      <<~PROMPT
        Analyze category spending spikes and unusual patterns:

        #{spike_summary}

        Please provide:
        1. Explanation for each category spike or unusual pattern
        2. Whether these spikes are seasonal, one-off, or concerning trends
        3. Categories that show healthy spending stability
        4. Recommendations for managing volatile spending categories
        5. Early warning signs to watch for future spikes
      PROMPT
    else
      "No significant category spending spikes detected. Spending patterns appear relatively stable across categories."
    end
  end

  # -- Chat prompt formatters --

  def format_date(date)
    date&.strftime("%d/%m/%Y") || "N/A"
  end

  def format_totals(totals)
    return "No transaction data available." unless totals

    <<~SECTION.strip
      === AVERAGES (#{totals[:months_of_data]} months of data) ===
      Average monthly income: £#{totals[:avg_monthly_income]}
      Average monthly expenses: £#{totals[:avg_monthly_expenses]}
      Total income (period): £#{totals[:total_income]}
      Total expenses (period): £#{totals[:total_expenses]}
    SECTION
  end

  def format_monthly_breakdown(breakdown)
    return "No monthly data available." unless breakdown&.any?

    lines = breakdown.map do |m|
      "#{m[:month]}: income £#{m[:total_income]}, expenses £#{m[:total_expenses]}, net £#{m[:net]} (#{m[:transaction_count]} transactions)"
    end

    "=== MONTHLY BREAKDOWN ===\n#{lines.join("\n")}"
  end

  def format_category_spending_by_month(data)
    return "No category spending data." unless data&.any?

    sections = data.map do |month, categories|
      cats = categories.map { |cat, amount| "  - #{cat}: £#{amount}" }.join("\n")
      "#{month}:\n#{cats}"
    end

    "=== SPENDING BY CATEGORY PER MONTH ===\n#{sections.join("\n")}"
  end

  def format_recurring_transactions(recurring)
    return "=== RECURRING TRANSACTIONS ===\nNo recurring transactions detected." unless recurring&.any?

    lines = recurring.map do |r|
      "- #{r[:description]}: £#{r[:avg_per_month]}/month (#{r[:occurrences]}x, category: #{r[:category]})"
    end

    "=== RECURRING TRANSACTIONS ===\n#{lines.join("\n")}"
  end

  def format_budgets(budgets)
    return "=== BUDGETS ===\nNo budgets set up yet." unless budgets&.any?

    lines = budgets.map do |b|
      status = b[:over_budget] ? "OVER BUDGET" : "on track"
      "- #{b[:category]}: £#{b[:monthly_limit]} limit, £#{b[:spent_this_month]} spent, £#{b[:remaining]} remaining, #{b[:percentage_used]}% used (#{status})"
    end

    "=== BUDGETS (current month) ===\n#{lines.join("\n")}"
  end
end
