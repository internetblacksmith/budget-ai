require 'rails_helper'

RSpec.describe LlmService do
  let(:service) { described_class.new }
  let(:mock_transactions) do
    [
      build(:transaction, description: "Tesco", amount: -50.00, category: "Groceries", date: 1.day.ago),
      build(:transaction, description: "Uber", amount: -15.00, category: "Transport", date: 2.days.ago),
      build(:transaction, description: "Netflix", amount: -12.99, category: "Entertainment", date: 3.days.ago)
    ]
  end

  describe "#initialize" do
    it "loads configuration from llm.yml" do
      config = service.instance_variable_get(:@config)
      expect(config[:provider]).to eq("mock")
      expect(config[:model]).to eq("sonnet")
    end

    it "builds LlmClient with configuration" do
      expect(service.instance_variable_get(:@client)).to be_a(LlmClient)
    end
  end

  describe "#analyze_spending" do
    it "generates spending analysis" do
      result = service.analyze_spending(mock_transactions)
      expect(result).to be_a(String)
      expect(result).to include("mock response")
    end

    it "accepts period and account options" do
      result = service.analyze_spending(mock_transactions, period: "last week", account: "current")
      expect(result).to be_a(String)
    end

    it "handles empty transactions" do
      result = service.analyze_spending([])
      expect(result).to be_a(String)
    end
  end

  describe "#suggest_budget" do
    let(:account_stats) do
      [
        { income: 2000, expenses: 1500 },
        { income: 500, expenses: 300 }
      ]
    end

    let(:monthly_data) do
      [
        { month: "2026-02", transactions: mock_transactions },
        { month: "2026-01", transactions: mock_transactions }
      ]
    end

    it "generates budget suggestions" do
      result = service.suggest_budget(account_stats, monthly_data)
      expect(result).to be_a(String)
      expect(result).to include("mock response")
    end

    it "accepts monthly_data with multiple months" do
      result = service.suggest_budget(account_stats, monthly_data)
      expect(result).to be_a(String)
    end
  end

  describe "#categorize_transaction" do
    let(:transaction) { build(:transaction, description: "Starbucks", amount: -5.00) }

    it "categorizes a transaction" do
      result = service.categorize_transaction(transaction)
      expect(result).to be_a(String)
    end

    it "uses lower temperature for categorization" do
      expect_any_instance_of(LlmClient).to receive(:generate).with(
        instance_of(String),
        temperature: 0.3,
        max_tokens: 50
      ).and_return("Dining")

      service.categorize_transaction(transaction)
    end
  end

  describe "#explain_spending_pattern" do
    it "explains weekend spending pattern" do
      transactions = [
        build(:transaction, date: 1.day.ago, amount: -20),
        build(:transaction, date: 2.days.ago, amount: -15)
      ]

      result = service.explain_spending_pattern(transactions, :weekend_spending)
      expect(result).to be_a(String)
    end

    it "explains recurring pattern" do
      transactions = [
        build(:transaction, description: "Netflix", amount: -12.99, date: 1.month.ago),
        build(:transaction, description: "Netflix", amount: -12.99, date: 2.months.ago)
      ]

      result = service.explain_spending_pattern(transactions, :recurring)
      expect(result).to be_a(String)
    end

    it "explains high-value pattern" do
      transactions = [
        build(:transaction, description: "Laptop", amount: -1000),
        build(:transaction, description: "Monitor", amount: -300),
        build(:transaction, description: "Coffee", amount: -5)
      ]

      result = service.explain_spending_pattern(transactions, :high_value)
      expect(result).to be_a(String)
    end

    it "explains category spike pattern" do
      transactions = [
        build(:transaction, category: "Groceries", amount: -100),
        build(:transaction, category: "Groceries", amount: -150)
      ]

      result = service.explain_spending_pattern(transactions, :category_spike)
      expect(result).to be_a(String)
    end
  end

  describe "error handling" do
    describe "when LlmClient raises ConnectionError" do
      it "propagates ConnectionError" do
        allow_any_instance_of(LlmClient).to receive(:generate).and_raise(
          LlmClient::ConnectionError,
          "Failed to connect"
        )

        expect {
          service.analyze_spending(mock_transactions)
        }.to raise_error(LlmClient::ConnectionError)
      end
    end

    describe "when LlmClient raises TimeoutError" do
      it "propagates TimeoutError" do
        allow_any_instance_of(LlmClient).to receive(:generate).and_raise(
          LlmClient::TimeoutError,
          "timed out"
        )

        expect {
          service.analyze_spending(mock_transactions)
        }.to raise_error(LlmClient::TimeoutError)
      end
    end
  end
end
