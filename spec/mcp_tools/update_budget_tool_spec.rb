require "rails_helper"
require_relative "../../app/mcp_tools/update_budget_tool"

RSpec.describe UpdateBudgetTool do
  let!(:budget) { create(:budget, category: "Groceries", monthly_limit: 200, notes: "Original") }

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "updates monthly_limit" do
      result = call(id: budget.id, monthly_limit: 300)
      expect(result["success"]).to be true
      expect(result["budget"]["monthly_limit"]).to eq(300.0)
      expect(budget.reload.monthly_limit).to eq(300)
    end

    it "updates notes" do
      result = call(id: budget.id, notes: "Updated notes")
      expect(result["success"]).to be true
      expect(result["budget"]["notes"]).to eq("Updated notes")
    end

    it "updates both fields at once" do
      result = call(id: budget.id, monthly_limit: 500, notes: "Big budget")
      expect(result["success"]).to be true
      expect(result["budget"]["monthly_limit"]).to eq(500.0)
      expect(result["budget"]["notes"]).to eq("Big budget")
    end

    it "returns error for non-existent budget" do
      result = call(id: 99999)
      expect(result["success"]).to be false
      expect(result["error"]).to eq("Budget not found")
    end

    it "returns errors for invalid monthly_limit" do
      result = call(id: budget.id, monthly_limit: -10)
      expect(result["success"]).to be false
      expect(result["errors"]).to include("Monthly limit must be greater than 0")
    end
  end
end
