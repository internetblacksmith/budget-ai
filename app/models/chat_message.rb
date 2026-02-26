class ChatMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true

  scope :chronological, -> { order(created_at: :asc) }
  scope :recent, -> { order(created_at: :desc) }
end
