require "rails_helper"
require_relative "../../app/mcp_tools/create_budget_tool"

RSpec.describe CreateBudgetTool do
  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "creates a budget with required fields" do
      result = call(category: "Groceries", monthly_limit: 200)
      expect(result["success"]).to be true
      expect(result["budget"]["category"]).to eq("Groceries")
      expect(result["budget"]["monthly_limit"]).to eq(200.0)
      expect(Budget.count).to eq(1)
    end

    it "creates a budget with optional notes" do
      result = call(category: "Transport", monthly_limit: 100, notes: "Bus and train")
      expect(result["success"]).to be true
      expect(result["budget"]["notes"]).to eq("Bus and train")
    end

    it "returns errors for invalid data" do
      result = call(category: "", monthly_limit: 200)
      expect(result["success"]).to be false
      expect(result["errors"]).to include("Category can't be blank")
    end

    it "returns errors for duplicate category" do
      create(:budget, category: "Groceries")
      result = call(category: "Groceries", monthly_limit: 300)
      expect(result["success"]).to be false
      expect(result["errors"]).to include("Category has already been taken")
    end

    it "returns errors for invalid monthly_limit" do
      result = call(category: "Food", monthly_limit: -10)
      expect(result["success"]).to be false
      expect(result["errors"]).to include("Monthly limit must be greater than 0")
    end
  end
end
