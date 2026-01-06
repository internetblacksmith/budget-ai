# Handles chat interactions with the LLM, providing financial context
class ChatService
  def initialize
    @llm_service = LlmService.new
  end

  def process_message(user_input)
    context = build_system_context
    prompt = LlmPromptBuilder.new(transaction_analyzer).chat_prompt(user_input, context)
    @llm_service.chat(prompt)
  end

  private

  def build_system_context
    {
      transaction_count: Transaction.count,
      date_range: {
        earliest: Transaction.minimum(:date),
        latest: Transaction.maximum(:date)
      },
      monthly_breakdown: compute_monthly_breakdown,
      category_spending_by_month: compute_category_spending_by_month,
      budgets: compute_budgets,
      totals: compute_totals,
      recurring_transactions: compute_recurring_transactions
    }
  end

  def compute_monthly_breakdown
    recent_transactions.group_by { |t| t.date.strftime("%B %Y") }.map do |month, txs|
      expenses = txs.select(&:expense?)
      income = txs.select(&:income?)
      {
        month: month,
        total_income: income.sum { |t| t.amount }.round(2),
        total_expenses: expenses.sum { |t| t.amount.abs }.round(2),
        net: txs.sum { |t| t.amount }.round(2),
        transaction_count: txs.count
      }
    end
  end

  def compute_category_spending_by_month
    recent_transactions
      .select(&:expense?)
      .group_by { |t| t.date.strftime("%B %Y") }
      .transform_values do |txs|
        txs.group_by { |t| t.category || "Uncategorized" }
           .transform_values { |cat_txs| cat_txs.sum { |t| t.amount.abs }.round(2) }
           .sort_by { |_, amount| -amount }
           .to_h
      end
  end

  def compute_budgets
    Budget.order(:category).map do |b|
      {
        category: b.category,
        monthly_limit: b.monthly_limit.round(2),
        spent_this_month: b.spent_this_month.round(2),
        remaining: b.remaining.round(2),
        percentage_used: b.percentage_used,
        over_budget: b.over_budget?
      }
    end
  end

  def compute_totals
    expenses = recent_transactions.select(&:expense?)
    income = recent_transactions.select(&:income?)
    months = recent_transactions.map { |t| t.date.beginning_of_month }.uniq.count
    months = [ months, 1 ].max

    {
      total_income: income.sum { |t| t.amount }.round(2),
      total_expenses: expenses.sum { |t| t.amount.abs }.round(2),
      avg_monthly_income: (income.sum { |t| t.amount } / months).round(2),
      avg_monthly_expenses: (expenses.sum { |t| t.amount.abs } / months).round(2),
      months_of_data: months
    }
  end

  def compute_recurring_transactions
    recurring = transaction_analyzer.recurring_transactions
    months = recent_transactions.map { |t| t.date.beginning_of_month }.uniq.count
    months = [ months, 1 ].max

    recurring
      .select { |_, txs| txs.any?(&:expense?) }
      .map do |desc, txs|
        expenses = txs.select(&:expense?)
        total = expenses.sum { |t| t.amount.abs }
        {
          description: desc,
          occurrences: expenses.count,
          total: total.round(2),
          avg_per_month: (total / months).round(2),
          category: expenses.first.category || "Uncategorized"
        }
      end
      .sort_by { |r| -r[:total] }
  end

  def transaction_analyzer
    @transaction_analyzer ||= TransactionAnalyzer.new(recent_transactions)
  end

  def recent_transactions
    @recent_transactions ||= Transaction.non_transfers.where(date: 3.months.ago..).to_a
  end
end
