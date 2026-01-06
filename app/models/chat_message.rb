class ChatMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true

  default_scope { order(created_at: :asc) }

  scope :recent, -> { unscoped.order(created_at: :desc) }
end
