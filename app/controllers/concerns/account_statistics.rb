module AccountStatistics
  extend ActiveSupport::Concern

  private

  def calculate_account_statistics
    # Single-user mode - no user parameter needed
    CachedStatisticsService.new.get_account_statistics
  end
end
