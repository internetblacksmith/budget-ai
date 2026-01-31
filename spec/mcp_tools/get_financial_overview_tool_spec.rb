require "rails_helper"
require_relative "../../app/mcp_tools/get_financial_overview_tool"

RSpec.describe GetFinancialOverviewTool do
  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    before do
      create(:transaction, :income, amount: 2500, date: Date.current, account: "current-account")
      create(:transaction, :expense, amount: -800, date: Date.current, account: "current-account")
      create(:transaction, :expense, amount: -200, date: Date.current, account: "credit-card")
    end

    it "returns this month summary" do
      result = call
      month = result["this_month"]
      expect(month["month"]).to eq(Date.current.strftime("%b %Y"))
      expect(month["income"]).to eq(2500.0)
      expect(month["expenses"]).to eq(1000.0)
      expect(month["net"]).to eq(1500.0)
    end

    it "returns account balances" do
      result = call
      accounts = result["accounts"]
      expect(accounts.length).to eq(2)

      current = accounts.find { |a| a["account"] == "current-account" }
      expect(current["balance"]).to eq(1700.0)
      expect(current["transaction_count"]).to eq(2)
    end

    it "returns budget alerts for budgets at or over 80%" do
      create(:budget, category: "Entertainment", monthly_limit: 100)
      create(:transaction, :expense, amount: -90, category: "Entertainment", date: Date.current)
      create(:budget, category: "Groceries", monthly_limit: 500)

      result = call
      alerts = result["budget_alerts"]
      expect(alerts.length).to eq(1)
      expect(alerts.first["category"]).to eq("Entertainment")
      expect(alerts.first["percentage_used"].to_f).to eq(90.0)
    end

    it "returns empty budget alerts when no budgets are near limit" do
      create(:budget, category: "Groceries", monthly_limit: 500)
      result = call
      expect(result["budget_alerts"]).to eq([])
    end

    it "returns empty data when no transactions exist" do
      Transaction.destroy_all
      result = call
      expect(result["this_month"]["income"]).to eq(0.0)
      expect(result["this_month"]["expenses"]).to eq(0.0)
      expect(result["accounts"]).to eq([])
    end

    it "excludes transfers from this month summary" do
      create(:transaction, :expense, amount: -5000, date: Date.current, is_transfer: true)
      result = call
      expect(result["this_month"]["expenses"]).to eq(1000.0)
    end
  end
end
