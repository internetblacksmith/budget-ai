require 'rails_helper'

RSpec.describe LlmPromptBuilder do
  let(:transactions) do
    [
      build(:transaction, description: "Tesco", amount: -50.00, category: "Groceries"),
      build(:transaction, description: "Uber", amount: -15.00, category: "Transport"),
      build(:transaction, description: "Netflix", amount: -12.99, category: "Entertainment")
    ]
  end

  let(:analyzer) { TransactionAnalyzer.new(transactions) }
  let(:builder) { described_class.new(analyzer) }

  describe "#spending_analysis" do
    it "builds spending analysis prompt" do
      prompt = builder.spending_analysis
      expect(prompt).to include("Analyze the following spending data")
      expect(prompt).to include("this month")
      expect(prompt).to include("all accounts")
    end

    it "accepts period and account options" do
      prompt = builder.spending_analysis(period: "last quarter", account: "current")
      expect(prompt).to include("last quarter")
      expect(prompt).to include("current")
    end

    it "includes transaction summary in prompt" do
      prompt = builder.spending_analysis
      expect(prompt).to include("Groceries")
      expect(prompt).to include("Transport")
      expect(prompt).to include("Entertainment")
    end
  end

  describe "#budget_suggestion" do
    let(:account_stats) do
      [
        { income: 2000, expenses: 1500 },
        { income: 500, expenses: 300 }
      ]
    end

    let(:monthly_data) do
      [
        {
          month: "2026-02",
          transactions: [
            build(:transaction, amount: 1000, date: Date.new(2026, 2, 1)),
            build(:transaction, amount: -400, category: "Groceries", date: Date.new(2026, 2, 5))
          ]
        },
        {
          month: "2026-01",
          transactions: [
            build(:transaction, amount: 1200, date: Date.new(2026, 1, 1)),
            build(:transaction, amount: -600, category: "Groceries", date: Date.new(2026, 1, 10))
          ]
        }
      ]
    end

    it "builds budget suggestion prompt with monthly breakdown" do
      prompt = builder.budget_suggestion(account_stats, monthly_data: monthly_data)
      expect(prompt).to include("2 selected months")
      expect(prompt).to include("Monthly Breakdown:")
      expect(prompt).to include("Feb 2026")
      expect(prompt).to include("Jan 2026")
    end

    it "includes averages across months" do
      prompt = builder.budget_suggestion(account_stats, monthly_data: monthly_data)
      expect(prompt).to include("Average Monthly Income:")
      expect(prompt).to include("Average Monthly Expenses:")
      expect(prompt).to include("Average Monthly Net:")
    end

    it "includes average category spending" do
      prompt = builder.budget_suggestion(account_stats, monthly_data: monthly_data)
      expect(prompt).to include("Average Spending by Category:")
      expect(prompt).to include("50/30/20 rule")
    end

    it "handles empty monthly_data" do
      prompt = builder.budget_suggestion(account_stats, monthly_data: [])
      expect(prompt).to include("1 selected month")
    end
  end

  describe "#transaction_categorization" do
    let(:transaction) { build(:transaction, description: "Starbucks", amount: -5.00) }

    it "builds categorization prompt" do
      prompt = builder.transaction_categorization(transaction)
      expect(prompt).to include("Categorize this transaction")
      expect(prompt).to include("Starbucks")
      expect(prompt).to include("Groceries")
      expect(prompt).to include("Dining")
    end

    it "includes transaction details" do
      prompt = builder.transaction_categorization(transaction)
      expect(prompt).to include("£")
      expect(prompt).to include("Starbucks")
    end
  end

  describe "#pattern_explanation" do
    context "for weekend spending" do
      it "builds weekend spending pattern prompt" do
        prompt = builder.pattern_explanation(:weekend_spending)
        expect(prompt).to include("weekend vs weekday spending pattern")
        expect(prompt).to include("Weekend Spending")
        expect(prompt).to include("Weekday Spending")
      end
    end

    context "for recurring" do
      let(:recurring_transactions) do
        [
          build(:transaction, description: "Netflix", amount: -12.99, date: 1.month.ago),
          build(:transaction, description: "Netflix", amount: -12.99, date: 2.months.ago),
          build(:transaction, description: "Coffee", amount: -5)
        ]
      end

      let(:analyzer) { TransactionAnalyzer.new(recurring_transactions) }
      let(:builder) { described_class.new(analyzer) }

      it "builds recurring pattern prompt" do
        prompt = builder.pattern_explanation(:recurring)
        expect(prompt).to include("recurring payment patterns")
      end

      it "includes detected recurring payments" do
        prompt = builder.pattern_explanation(:recurring)
        expect(prompt).to include("recurring payment patterns")
      end
    end

    context "for high value" do
      let(:high_value_transactions) do
        [
          build(:transaction, description: "Laptop", amount: -1000),
          build(:transaction, description: "Coffee", amount: -5),
          build(:transaction, description: "Monitor", amount: -300)
        ]
      end

      let(:analyzer) { TransactionAnalyzer.new(high_value_transactions) }
      let(:builder) { described_class.new(analyzer) }

      it "builds high-value pattern prompt" do
        prompt = builder.pattern_explanation(:high_value)
        expect(prompt).to include("high-value spending patterns")
      end
    end

    context "for category spike" do
      it "builds category spike pattern prompt" do
        prompt = builder.pattern_explanation(:category_spike)
        expect(prompt).to include("category spending spikes")
      end
    end

    context "for unknown pattern" do
      it "builds generic pattern prompt" do
        prompt = builder.pattern_explanation(:unknown)
        expect(prompt).to include("unknown")
      end
    end
  end
end
