require "rails_helper"
require_relative "../../app/mcp_tools/query_transactions_tool"

RSpec.describe QueryTransactionsTool do
  let!(:expense) { create(:transaction, :expense, date: Date.current, description: "Tesco Groceries", category: "Groceries", account: "main") }
  let!(:income) { create(:transaction, :income, date: Date.current, description: "Salary Payment", category: "Income", account: "main") }
  let!(:old_txn) { create(:transaction, :expense, date: 6.months.ago, description: "Old Purchase", account: "savings") }

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "returns transactions within default date range" do
      result = call
      ids = result.map { |t| t["id"] }
      expect(ids).to include(expense.id, income.id)
      expect(ids).not_to include(old_txn.id)
    end

    it "filters by date range" do
      result = call(start_date: 1.year.ago.to_date.to_s, end_date: Date.current.to_s)
      ids = result.map { |t| t["id"] }
      expect(ids).to include(expense.id, income.id, old_txn.id)
    end

    it "filters by account" do
      result = call(start_date: 1.year.ago.to_date.to_s, end_date: Date.current.to_s, account: "savings")
      expect(result.length).to eq(1)
      expect(result.first["id"]).to eq(old_txn.id)
    end

    it "filters by category" do
      result = call(category: "Groceries")
      expect(result.length).to eq(1)
      expect(result.first["description"]).to eq("Tesco Groceries")
    end

    it "filters by type income" do
      result = call(type: "income")
      expect(result.all? { |t| t["amount"] > 0 }).to be true
    end

    it "filters by type expense" do
      result = call(type: "expense")
      expect(result.all? { |t| t["amount"] < 0 }).to be true
    end

    it "searches by description" do
      result = call(search: "Tesco")
      expect(result.length).to eq(1)
      expect(result.first["description"]).to include("Tesco")
    end

    it "respects limit" do
      result = call(limit: 1)
      expect(result.length).to eq(1)
    end

    it "returns empty array when no matches" do
      result = call(category: "Nonexistent")
      expect(result).to eq([])
    end

    it "handles invalid date gracefully" do
      result = call(start_date: "not-a-date")
      expect(result).to be_an(Array)
    end
  end
end
