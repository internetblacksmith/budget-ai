require "rails_helper"
require_relative "../../app/mcp_tools/get_top_categories_tool"

RSpec.describe GetTopCategoriesTool do
  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    before do
      create(:transaction, :expense, amount: -200, category: "Groceries", date: Date.current)
      create(:transaction, :expense, amount: -150, category: "Groceries", date: Date.current)
      create(:transaction, :expense, amount: -100, category: "Transport", date: Date.current)
      create(:transaction, :expense, amount: -80, category: "Entertainment", date: Date.current)
      create(:transaction, :income, amount: 3000, category: "Salary", date: Date.current)
    end

    it "returns categories ranked by total spending" do
      result = call
      expect(result.first["category"]).to eq("Groceries")
      expect(result.first["total"]).to eq(350.0)
    end

    it "includes transaction count per category" do
      result = call
      groceries = result.find { |c| c["category"] == "Groceries" }
      expect(groceries["transaction_count"]).to eq(2)
    end

    it "defaults to top 5 categories" do
      result = call
      expect(result.length).to be <= 5
    end

    it "respects custom limit" do
      result = call(limit: 2)
      expect(result.length).to eq(2)
      expect(result.first["category"]).to eq("Groceries")
    end

    it "excludes income transactions" do
      result = call
      categories = result.map { |c| c["category"] }
      expect(categories).not_to include("Salary")
    end

    it "excludes transfers" do
      create(:transaction, :expense, amount: -5000, category: "Transfer", date: Date.current, is_transfer: true)
      result = call
      categories = result.map { |c| c["category"] }
      expect(categories).not_to include("Transfer")
    end

    it "groups uncategorized transactions" do
      create(:transaction, :expense, amount: -50, category: nil, date: Date.current)
      result = call
      uncategorized = result.find { |c| c["category"] == "Uncategorized" }
      expect(uncategorized).not_to be_nil
      expect(uncategorized["total"]).to eq(50.0)
    end

    it "accepts months_back parameter" do
      create(:transaction, :expense, amount: -300, category: "Bills", date: 4.months.ago)
      result = call(months_back: 6)
      categories = result.map { |c| c["category"] }
      expect(categories).to include("Bills")
    end

    it "returns empty array when no expenses in range" do
      Transaction.expenses.update_all(date: 2.years.ago)
      result = call(months_back: 1)
      expect(result).to eq([])
    end
  end
end
