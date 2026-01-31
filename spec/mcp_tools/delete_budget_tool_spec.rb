require "rails_helper"
require_relative "../../app/mcp_tools/delete_budget_tool"

RSpec.describe DeleteBudgetTool do
  let!(:budget) { create(:budget, category: "Groceries", monthly_limit: 200) }

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "deletes the budget" do
      result = call(id: budget.id)
      expect(result["success"]).to be true
      expect(result["deleted_category"]).to eq("Groceries")
      expect(Budget.find_by(id: budget.id)).to be_nil
    end

    it "returns error for non-existent budget" do
      result = call(id: 99999)
      expect(result["success"]).to be false
      expect(result["error"]).to eq("Budget not found")
    end
  end
end
