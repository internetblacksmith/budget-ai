require "rails_helper"
require_relative "../../app/mcp_tools/categorize_transaction_tool"

RSpec.describe CategorizeTransactionTool do
  let!(:transaction) { create(:transaction, description: "Tesco Store", category: nil) }

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "sets category on a transaction" do
      result = call(id: transaction.id, category: "Groceries")
      expect(result["success"]).to be true
      expect(result["transaction"]["category"]).to eq("Groceries")
      expect(transaction.reload.category).to eq("Groceries")
    end

    it "records a TransactionEdit for persistence" do
      expect {
        call(id: transaction.id, category: "Groceries")
      }.to change(TransactionEdit, :count).by(1)

      edit = TransactionEdit.find_by(transaction_id: transaction.transaction_id, source: transaction.source)
      expect(edit.category).to eq("Groceries")
    end

    it "updates existing category" do
      transaction.update!(category: "Food")
      result = call(id: transaction.id, category: "Groceries")
      expect(result["success"]).to be true
      expect(result["transaction"]["category"]).to eq("Groceries")
    end

    it "returns error for non-existent transaction" do
      result = call(id: 99999, category: "Groceries")
      expect(result["success"]).to be false
      expect(result["error"]).to eq("Transaction not found")
    end
  end
end
