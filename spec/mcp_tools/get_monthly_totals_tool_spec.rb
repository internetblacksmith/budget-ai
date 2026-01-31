require "rails_helper"
require_relative "../../app/mcp_tools/get_monthly_totals_tool"

RSpec.describe GetMonthlyTotalsTool do
  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    before do
      create(:transaction, :income, amount: 2000, date: Date.current)
      create(:transaction, :expense, amount: -800, date: Date.current)
      create(:transaction, :income, amount: 1500, date: 1.month.ago)
      create(:transaction, :expense, amount: -600, date: 1.month.ago)
    end

    it "returns monthly breakdown for default 3 months" do
      result = call
      expect(result).to be_an(Array)
      expect(result.length).to be <= 3
    end

    it "includes income, expenses, and net for each month" do
      result = call
      current = result.find { |m| m["month"] == Date.current.strftime("%b %Y") }
      expect(current["income"]).to eq(2000.0)
      expect(current["expenses"]).to eq(800.0)
      expect(current["net"]).to eq(1200.0)
    end

    it "sorts months chronologically" do
      result = call
      months = result.map { |m| Date.parse("1 #{m['month']}") }
      expect(months).to eq(months.sort)
    end

    it "accepts custom months_back parameter" do
      create(:transaction, :expense, amount: -200, date: 5.months.ago)
      result = call(months_back: 6)
      expect(result.length).to be >= 3
    end

    it "excludes transfers" do
      create(:transaction, :expense, amount: -5000, date: Date.current, is_transfer: true)
      result = call
      current = result.find { |m| m["month"] == Date.current.strftime("%b %Y") }
      expect(current["expenses"]).to eq(800.0)
    end

    it "returns empty array when no transactions in range" do
      Transaction.update_all(date: 2.years.ago)
      result = call(months_back: 1)
      expect(result).to eq([])
    end
  end
end
