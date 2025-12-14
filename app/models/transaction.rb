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
    ActionController::Base.helpers.number_to_currency(amount.abs, unit: "£")
  end

  def transaction_edit
    TransactionEdit.find_by(transaction_id: transaction_id, source: source)
  end
end
