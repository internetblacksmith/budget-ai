class ImportNotification < ApplicationRecord
  belongs_to :import_job

  validates :notification_type, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current)
  end
end
