class DataGap < ApplicationRecord
  validates :account, :source, :gap_start, :gap_end, presence: true

  scope :unresolved, -> { where(resolved: false) }
  scope :resolved, -> { where(resolved: true) }
  scope :for_account, ->(account) { where(account: account) }

  def resolve!
    update!(resolved: true)
  end
end
