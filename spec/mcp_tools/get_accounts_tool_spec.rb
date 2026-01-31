require "rails_helper"
require_relative "../../app/mcp_tools/get_accounts_tool"

RSpec.describe GetAccountsTool do
  before do
    create(:account, name: "Main Account")
    create(:transaction, :income, amount: 500, account: "Main Account")
    create(:transaction, :expense, amount: -100, account: "Main Account")
  end

  def call(**params)
    response = described_class.call(**params)
    JSON.parse(response.content.first[:text])
  end

  describe ".call" do
    it "returns account statistics" do
      result = call
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
    end

    it "includes balance and transaction data" do
      result = call
      account = result.first
      expect(account["name"]).to eq("Main Account")
      expect(account["current_balance"].to_f).to eq(400.0)
    end

    it "returns empty array when no accounts" do
      Account.destroy_all
      result = call
      expect(result).to eq([])
    end
  end
end
