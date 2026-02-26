class Transaction < ApplicationRecord
  validates :date, presence: true
  validates :description, presence: true
  validates :amount, presence: true, numericality: true
  validates :account, presence: true
  validates :transaction_id, presence: true, uniqueness: { scope: :source }
  validates :source, inclusion: { in: %w[emma_export] }

  attribute :source, default: "emma_export"

  scope :by_date_range, ->(start_date, end_date) { where(date: start_date.beginning_of_day..end_date.end_of_day) }
  scope :by_account, ->(account) { where(account:) }
  scope :income, -> { where(amount: 0..) }
  scope :expenses, -> { where(amount: ...0) }
  scope :recent, -> { order(created_at: :desc) }

  scope :actual_income, -> { income.where(is_transfer: false) }
  scope :actual_expenses, -> { expenses.where(is_transfer: false) }
  scope :transfers, -> { where(is_transfer: true) }
  scope :non_transfers, -> { where(is_transfer: false) }

  scope :for_period, ->(period, account: nil) {
    scope = account.present? ? where(account: account) : all
    case period
    when "today"
      scope.where(date: Date.current.all_day)
    when "this_week"
      scope.where(date: Date.current.beginning_of_week..)
    when "last_week"
      scope.where(date: 1.week.ago.beginning_of_week..1.week.ago.end_of_week)
    when "this_month"
      scope.where(date: Date.current.beginning_of_month..)
    when "last_month"
      scope.where(date: 1.month.ago.beginning_of_month.beginning_of_day..1.month.ago.end_of_month.end_of_day)
    when "last_3_months"
      scope.where(date: 3.months.ago..)
    else
      scope.where(date: 1.month.ago..)
    end
  }

  def self.financial_context
    recent = non_transfers.where(date: 3.months.ago..).to_a
    analyzer = TransactionAnalyzer.new(recent)
    months = recent.map { |t| t.date.beginning_of_month }.uniq.count
    months = [ months, 1 ].max

    {
      transaction_count: count,
      date_range: { earliest: minimum(:date), latest: maximum(:date) },
      monthly_breakdown: monthly_breakdown(recent),
      category_spending_by_month: category_spending_by_month(recent),
      budgets: Budget.status_summary,
      totals: totals(recent, months),
      recurring_transactions: recurring_summary(analyzer, months)
    }
  end

  def self.distinct_months(limit: 6)
    order(date: :desc)
      .pluck(Arel.sql("DISTINCT strftime('%Y-%m', date)"))
      .first(limit)
  end

  def income?
    amount > 0
  end

  def expense?
    amount < 0
  end

  def formatted_amount
    "£#{'%.2f' % amount.abs}"
  end

  def transaction_edit
    TransactionEdit.find_by(transaction_id: transaction_id, source: source)
  end

  class << self
    private

    def monthly_breakdown(transactions)
      transactions.group_by { |t| t.date.strftime("%B %Y") }.map do |month, txs|
        expenses = txs.select(&:expense?)
        income = txs.select(&:income?)
        {
          month: month,
          total_income: income.sum(&:amount).round(2),
          total_expenses: expenses.sum { |t| t.amount.abs }.round(2),
          net: txs.sum(&:amount).round(2),
          transaction_count: txs.count
        }
      end
    end

    def category_spending_by_month(transactions)
      transactions
        .select(&:expense?)
        .group_by { |t| t.date.strftime("%B %Y") }
        .transform_values do |txs|
          txs.group_by { |t| t.category || "Uncategorized" }
             .transform_values { |cat_txs| cat_txs.sum { |t| t.amount.abs }.round(2) }
             .sort_by { |_, amount| -amount }
             .to_h
        end
    end

    def totals(transactions, months)
      expenses = transactions.select(&:expense?)
      income = transactions.select(&:income?)

      {
        total_income: income.sum(&:amount).round(2),
        total_expenses: expenses.sum { |t| t.amount.abs }.round(2),
        avg_monthly_income: (income.sum(&:amount) / months).round(2),
        avg_monthly_expenses: (expenses.sum { |t| t.amount.abs } / months).round(2),
        months_of_data: months
      }
    end

    def recurring_summary(analyzer, months)
      analyzer.recurring_transactions
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
  end
end
