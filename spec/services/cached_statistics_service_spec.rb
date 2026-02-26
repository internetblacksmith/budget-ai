require "rails_helper"

describe CachedStatisticsService do
  let(:service) { described_class.new }

  before do
    allow(Rails.cache).to receive(:fetch).and_call_original
    allow(Rails.cache).to receive(:delete).and_call_original
  end

  describe "#get_account_statistics" do
    it "returns cached account statistics" do
      create(:account, name: "Checking")
      create(:transaction, account: "Checking", amount: 100)
      create(:transaction, account: "Checking", amount: -50)

      stats = service.get_account_statistics

      expect(stats).to be_a(Array)
      expect(stats.first[:name]).to eq("Checking")
      expect(stats.first[:income]).to eq(100)
      expect(stats.first[:expenses]).to eq(50)
      expect(stats.first[:transaction_count]).to eq(2)
    end

    it "caches results" do
      create(:account, name: "Checking")
      create(:transaction, account: "Checking", amount: 100)

      stats1 = service.get_account_statistics
      stats2 = service.get_account_statistics

      expect(stats1).to eq(stats2)
    end

    it "includes current balance calculation" do
      create(:account, name: "Savings")
      create(:transaction, account: "Savings", amount: 100)

      stats = service.get_account_statistics
      account_stat = stats.find { |s| s[:name] == "Savings" }

      expect(account_stat[:current_balance]).to eq(100)
    end

    it "excludes transfer transactions from income/expense totals" do
      create(:account, name: "Checking")
      create(:transaction, account: "Checking", amount: 100)
      create(:transaction, account: "Checking", amount: -50, is_transfer: true)

      stats = service.get_account_statistics
      account_stat = stats.find { |s| s[:name] == "Checking" }

      expect(account_stat[:income]).to eq(100)
      expect(account_stat[:expenses]).to eq(0)
      expect(account_stat[:transaction_count]).to eq(2)
    end

    it "sorts accounts by name" do
      create(:account, name: "Zebra")
      create(:account, name: "Alpha")
      create(:account, name: "Beta")

      stats = service.get_account_statistics

      account_names = stats.map { |s| s[:name] }
      expect(account_names).to eq([ "Alpha", "Beta", "Zebra" ])
    end

    it "uses correct cache key" do
      service.get_account_statistics

      expect(Rails.cache).to have_received(:fetch).with(
        "statistics:account_statistics",
        expires_in: 1.hour
      )
    end
  end

  describe "#invalidate_all!" do
    it "clears account statistics cache" do
      create(:account, name: "Checking")
      create(:transaction, account: "Checking", amount: 100)

      service.get_account_statistics
      service.invalidate_all!

      expect(Rails.cache).to have_received(:delete).with("statistics:account_statistics")
    end
  end

  describe "cache expiry" do
    it "has 1 hour TTL for cached statistics" do
      expect(described_class::CACHE_TTL).to eq(1.hour)
    end
  end

  describe "with empty database" do
    it "returns empty statistics when no accounts" do
      stats = service.get_account_statistics

      expect(stats).to eq([])
    end
  end
end
