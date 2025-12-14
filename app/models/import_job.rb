class ImportJob < ApplicationRecord
  has_many :import_notifications, dependent: :destroy

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    completed_with_errors: "completed_with_errors",
    failed: "failed"
  }, default: :pending, validate: true

  enum :source, {
    emma_export: "emma_export"
  }, default: :emma_export, validate: true

  attribute :error_messages, :json, default: -> { [] }

  validates :total_files, numericality: { greater_than: 0 }
  validates :imported_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(status: [ :pending, :processing ]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :completed_recently, -> { where(status: [ :completed, :completed_with_errors, :failed ]).where(updated_at: 10.minutes.ago..) }

  def display_status
    case status
    in "completed" | "completed_with_errors" if imported_count > 0
      "Successfully imported #{imported_count} transactions"
    in "completed" | "completed_with_errors"
      "Import completed with no new transactions"
    in "failed"
      "Import failed: #{error_messages.join(', ')}"
    in "processing"
      "Processing..."
    in "pending"
      "Waiting to start..."
    else
      status.humanize
    end
  end
end
