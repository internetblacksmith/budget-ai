class CachedStatisticsService
  CACHE_TTL = 1.hour

  def initialize(user = nil)
    @user = user
  end

  def get_account_statistics
    cache_key = cache_key_for(:account_statistics)
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      calculate_account_statistics
    end
  end

  def invalidate_all!
    invalidate!(:account_statistics)
  end

  def invalidate!(cache_type)
    cache_key = cache_key_for(cache_type)
    Rails.cache.delete(cache_key)
  end

  private

  def cache_key_for(cache_type)
    user_id = @user&.id || "single"
    "user:#{user_id}:statistics:#{cache_type}"
  end

  def calculate_account_statistics
    accounts = Account.all.index_by(&:name)

    account_stats = {}
    accounts.each do |account_name, _account|
      account_stats[account_name] = {
        name: account_name,
        income: 0,
        expenses: 0,
        transaction_count: 0
      }
    end

    Transaction.non_transfers.group(:account)
         .group("CASE WHEN amount > 0 THEN 'income' ELSE 'expenses' END")
         .sum(:amount).each do |(account_name, type), amount|
      stats = account_stats[account_name]
      next unless stats

      if type == "income"
        stats[:income] = amount
      else
        stats[:expenses] = amount.abs
      end
    end

    Transaction.group(:account).count.each do |account_name, count|
      stats = account_stats[account_name]
      next unless stats
      stats[:transaction_count] = count
    end

    account_stats.each do |account_name, stats|
      stats[:net_change] = stats[:income] - stats[:expenses]
      account = accounts[account_name]
      stats[:current_balance] = account.current_balance
    end

    account_stats.values.sort_by { |stats| stats[:name] }
  end
end
