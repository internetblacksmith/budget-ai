require "rails_helper"
require_relative "../../app/mcp_tools/get_spending_summary_tool"

RSpec.describe GetSpendingSummaryTool do
  before do
    create(:transaction, :expense, amount: -50, category: "Groceries", date: Date.current)
    create(:transaction, :expense, amount: -30, category: "Groceries", date: Date.current)
    create(:transaction, :expense, amount: -20, category: "Transport", date: Date.current)
    create(:transaction, :income, amount: 200, category: "Salary", date: Date.current)
  end

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "returns category totals sorted by amount descending" do
      result = call
      totals = result["category_totals"]
      expect(totals["Groceries"].to_f).to eq(80.0)
      expect(totals["Transport"].to_f).to eq(20.0)
      expect(totals.keys.first).to eq("Groceries")
    end

    it "returns monthly breakdown with income and expenses" do
      result = call
      month = result["monthly_breakdown"].first
      expect(month["income"].to_f).to eq(200.0)
      expect(month["expenses"].to_f).to eq(100.0)
      expect(month["net"].to_f).to eq(100.0)
    end

    it "returns totals" do
      result = call
      totals = result["totals"]
      expect(totals["total_income"].to_f).to eq(200.0)
      expect(totals["total_expenses"].to_f).to eq(100.0)
    end

    it "returns period information" do
      result = call(start_date: "2026-01-01", end_date: "2026-12-31")
      expect(result["period"]["start_date"]).to eq("2026-01-01")
      expect(result["period"]["end_date"]).to eq("2026-12-31")
    end

    it "returns empty data when no transactions in range" do
      result = call(start_date: "2020-01-01", end_date: "2020-01-31")
      expect(result["category_totals"]).to eq({})
      expect(result["monthly_breakdown"]).to eq([])
    end
  end
end
