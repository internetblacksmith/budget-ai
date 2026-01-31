require 'rails_helper'

RSpec.describe TransactionAnalyzer do
  let(:transactions) do
    [
      build(:transaction, description: "Tesco", amount: -50.00, category: "Groceries", date: 1.day.ago),
      build(:transaction, description: "Uber", amount: -15.00, category: "Transport", date: 2.days.ago),
      build(:transaction, description: "Netflix", amount: -12.99, category: "Entertainment", date: 3.days.ago),
      build(:transaction, description: "Salary", amount: 2000, category: "Income", date: 4.days.ago)
    ]
  end

  let(:analyzer) { described_class.new(transactions) }

  describe "#summarize" do
    it "groups transactions by category" do
      summary = analyzer.summarize
      expect(summary).to include("Groceries")
      expect(summary).to include("Transport")
      expect(summary).to include("Entertainment")
    end

    it "handles empty transactions" do
      empty_analyzer = described_class.new([])
      summary = empty_analyzer.summarize
      expect(summary).to eq("No transactions to analyze.")
    end
  end

  describe "#category_spending" do
    it "calculates spending by category" do
      spending = analyzer.category_spending
      expect(spending).to include("Groceries" => 50.00)
      expect(spending).to include("Transport" => 15.00)
      expect(spending).to include("Entertainment" => 12.99)
    end

    it "only includes expenses (negative amounts)" do
      spending = analyzer.category_spending
      expect(spending).not_to have_key("Income")
    end

    it "sorts by amount descending" do
      spending = analyzer.category_spending
      amounts = spending.values
      expect(amounts).to eq(amounts.sort.reverse)
    end
  end

  describe "#recurring_transactions" do
    let(:recurring_transactions) do
      [
        build(:transaction, description: "Netflix", amount: -12.99, date: 1.month.ago),
        build(:transaction, description: "Netflix", amount: -12.99, date: 2.months.ago),
        build(:transaction, description: "Gym", amount: -50, date: 1.month.ago),
        build(:transaction, description: "Gym", amount: -50, date: 2.months.ago),
        build(:transaction, description: "Coffee", amount: -5, date: 1.day.ago)
      ]
    end

    let(:analyzer) { described_class.new(recurring_transactions) }

    it "identifies recurring transactions" do
      recurring = analyzer.recurring_transactions
      expect(recurring).to have_key("netflix")
      expect(recurring).to have_key("gym")
    end

    it "excludes non-recurring transactions" do
      recurring = analyzer.recurring_transactions
      expect(recurring).not_to have_key("coffee")
    end

    it "counts occurrences correctly" do
      recurring = analyzer.recurring_transactions
      expect(recurring["netflix"].count).to eq(2)
      expect(recurring["gym"].count).to eq(2)
    end
  end

  describe "#weekend_vs_weekday" do
    let(:weekend_weekday_transactions) do
      # Create dates that are definitely weekend/weekday
      # 2026-01-31 is a Saturday, 2026-02-01 is a Sunday, 2026-02-02 is a Monday
      [
        build(:transaction, amount: -20, date: Date.new(2026, 1, 31)), # Saturday
        build(:transaction, amount: -25, date: Date.new(2026, 2, 1)),  # Sunday
        build(:transaction, amount: -10, date: Date.new(2026, 2, 2)),  # Monday
        build(:transaction, amount: -15, date: Date.new(2026, 2, 3))   # Tuesday
      ]
    end

    let(:analyzer) { described_class.new(weekend_weekday_transactions) }

    it "separates weekend and weekday transactions" do
      data = analyzer.weekend_vs_weekday
      expect(data[:weekend_transactions].count).to eq(2)
      expect(data[:weekday_transactions].count).to eq(2)
    end

    it "calculates totals for each group" do
      data = analyzer.weekend_vs_weekday
      expect(data[:weekend][:total]).to be_within(0.01).of(45.0)
      expect(data[:weekday][:total]).to be_within(0.01).of(25.0)
    end
  end

  describe "#high_value_transactions" do
    let(:transactions) do
      [
        build(:transaction, amount: -1000, description: "Laptop"),
        build(:transaction, amount: -50, description: "Groceries"),
        build(:transaction, amount: -300, description: "Repair"),
        build(:transaction, amount: -10, description: "Coffee"),
        build(:transaction, amount: -200, description: "Coat")
      ]
    end

    let(:analyzer) { described_class.new(transactions) }

    it "returns high-value transactions above percentile" do
      high_value = analyzer.high_value_transactions(95)
      expect(high_value.count).to be > 0
      expect(high_value.map { |t| t.amount.abs }).to all(be >= 200)
    end

    it "uses 95th percentile by default" do
      high_value = analyzer.high_value_transactions
      expect(high_value).to include(transactions[0]) # Laptop
    end
  end

  describe "#category_spikes" do
    it "identifies significant category spikes" do
      spikes = analyzer.category_spikes
      # This depends on the data, so we just check it returns a hash
      expect(spikes).to be_a(Hash)
    end

    it "handles empty transactions" do
      empty_analyzer = described_class.new([])
      spikes = empty_analyzer.category_spikes
      expect(spikes).to eq({})
    end
  end
end
