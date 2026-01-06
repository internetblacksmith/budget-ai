class Budget < ApplicationRecord
  validates :category, presence: true, uniqueness: true
  validates :monthly_limit, presence: true, numericality: { greater_than: 0 }

  def spent_this_month
    Transaction.non_transfers.expenses
               .where(category: category)
               .where(date: Date.current.beginning_of_month.beginning_of_day..Date.current.end_of_month.end_of_day)
               .sum(:amount)
               .abs
  end

  def remaining
    monthly_limit - spent_this_month
  end

  def percentage_used
    return 0 if monthly_limit.zero?

    ((spent_this_month / monthly_limit) * 100).round(1)
  end

  def over_budget?
    spent_this_month > monthly_limit
  end
end
