class Account < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  def current_balance
    Transaction.where(account: name).sum(:amount)
  end
end
