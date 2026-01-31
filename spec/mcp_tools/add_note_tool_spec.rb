require "rails_helper"
require_relative "../../app/mcp_tools/add_note_tool"

RSpec.describe AddNoteTool do
  let!(:transaction) { create(:transaction, description: "Mystery Payment", notes: nil) }

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "adds a note to a transaction" do
      result = call(id: transaction.id, note: "This was for dinner")
      expect(result["success"]).to be true
      expect(result["transaction"]["notes"]).to eq("This was for dinner")
      expect(transaction.reload.notes).to eq("This was for dinner")
    end

    it "records a TransactionEdit for persistence" do
      expect {
        call(id: transaction.id, note: "This was for dinner")
      }.to change(TransactionEdit, :count).by(1)

      edit = TransactionEdit.find_by(transaction_id: transaction.transaction_id, source: transaction.source)
      expect(edit.notes).to eq("This was for dinner")
    end

    it "updates existing note" do
      transaction.update!(notes: "Old note")
      result = call(id: transaction.id, note: "New note")
      expect(result["success"]).to be true
      expect(result["transaction"]["notes"]).to eq("New note")
    end

    it "returns error for non-existent transaction" do
      result = call(id: 99999, note: "Some note")
      expect(result["success"]).to be false
      expect(result["error"]).to eq("Transaction not found")
    end
  end
end
