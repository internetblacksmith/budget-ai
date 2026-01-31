require "rails_helper"
require_relative "../../app/mcp_tools/get_total_income_tool"

RSpec.describe GetTotalIncomeTool do
  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    before do
      create(:transaction, :income, amount: 2000, date: Date.current)
      create(:transaction, :income, amount: 500, date: Date.current)
      create(:transaction, :expense, amount: -100, date: Date.current)
    end

    it "returns total income for the current month by default" do
      result = call
      expect(result["total_income"]).to eq(2500.0)
      expect(result["months"]).to eq(1)
    end

    it "includes period label" do
      result = call
      expect(result["period"]).to eq(Date.current.strftime("%b %Y"))
    end

    it "looks back multiple months" do
      create(:transaction, :income, amount: 1000, date: 2.months.ago)
      result = call(months_back: 3)
      expect(result["total_income"]).to eq(3500.0)
      expect(result["months"]).to eq(3)
    end

    it "shows period range for multiple months" do
      result = call(months_back: 3)
      start_month = 2.months.ago.beginning_of_month.to_date.strftime("%b %Y")
      end_month = Date.current.strftime("%b %Y")
      expect(result["period"]).to eq("#{start_month} - #{end_month}")
    end

    it "excludes transfers" do
      create(:transaction, :income, amount: 5000, date: Date.current, is_transfer: true)
      result = call
      expect(result["total_income"]).to eq(2500.0)
    end

    it "excludes expenses from total" do
      result = call
      expect(result["total_income"]).to eq(2500.0)
    end

    it "returns zero when no income exists in range" do
      Transaction.income.update_all(date: 2.years.ago)
      result = call(months_back: 1)
      expect(result["total_income"]).to eq(0.0)
    end

    it "treats months_back less than 1 as 1" do
      result = call(months_back: -5)
      expect(result["months"]).to eq(1)
    end
  end
end
