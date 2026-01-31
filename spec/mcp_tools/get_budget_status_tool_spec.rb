require "rails_helper"
require_relative "../../app/mcp_tools/get_budget_status_tool"

RSpec.describe GetBudgetStatusTool do
  before do
    create(:budget, category: "Groceries", monthly_limit: 200, notes: "Weekly shop")
    create(:budget, category: "Transport", monthly_limit: 100)
    create(:transaction, :expense, amount: -75, category: "Groceries", date: Date.current)
  end

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "returns all budgets ordered by category" do
      result = call
      expect(result.length).to eq(2)
      expect(result.first["category"]).to eq("Groceries")
    end

    it "includes spending data for each budget" do
      result = call
      groceries = result.find { |b| b["category"] == "Groceries" }
      expect(groceries["monthly_limit"]).to eq(200.0)
      expect(groceries["spent_this_month"]).to eq(75.0)
      expect(groceries["remaining"]).to eq(125.0)
      expect(groceries["percentage_used"].to_f).to eq(37.5)
      expect(groceries["over_budget"]).to be false
    end

    it "shows zero spending when no transactions" do
      result = call
      transport = result.find { |b| b["category"] == "Transport" }
      expect(transport["spent_this_month"]).to eq(0.0)
      expect(transport["remaining"]).to eq(100.0)
    end

    it "includes notes" do
      result = call
      groceries = result.find { |b| b["category"] == "Groceries" }
      expect(groceries["notes"]).to eq("Weekly shop")
    end

    it "returns empty array when no budgets exist" do
      Budget.destroy_all
      result = call
      expect(result).to eq([])
    end
  end
end
