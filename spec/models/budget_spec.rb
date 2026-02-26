require 'rails_helper'

RSpec.describe Budget, type: :model do
  describe 'validations' do
    it 'validates presence of category' do
      budget = build(:budget, category: nil)
      expect(budget).not_to be_valid
      expect(budget.errors[:category]).to include("can't be blank")
    end

    it 'validates uniqueness of category' do
      create(:budget, category: "Groceries")
      budget = build(:budget, category: "Groceries")
      expect(budget).not_to be_valid
      expect(budget.errors[:category]).to include("has already been taken")
    end

    it 'validates presence of monthly_limit' do
      budget = build(:budget, monthly_limit: nil)
      expect(budget).not_to be_valid
      expect(budget.errors[:monthly_limit]).to include("can't be blank")
    end

    it 'validates monthly_limit is greater than 0' do
      budget = build(:budget, monthly_limit: 0)
      expect(budget).not_to be_valid
      expect(budget.errors[:monthly_limit]).to include("must be greater than 0")

      budget.monthly_limit = -10
      expect(budget).not_to be_valid
    end

    it 'is valid with valid attributes' do
      budget = build(:budget)
      expect(budget).to be_valid
    end
  end

  describe '.status_summary' do
    it 'returns budget status for all budgets' do
      create(:budget, category: "Groceries", monthly_limit: 200)
      create(:budget, category: "Bills", monthly_limit: 500)
      create(:transaction, category: "Groceries", amount: -75, date: Date.current)

      summary = Budget.status_summary
      expect(summary.length).to eq(2)

      bills = summary.find { |b| b[:category] == "Bills" }
      expect(bills[:monthly_limit]).to eq(500.0)
      expect(bills[:spent_this_month]).to eq(0.0)
      expect(bills[:over_budget]).to be false

      groceries = summary.find { |b| b[:category] == "Groceries" }
      expect(groceries[:spent_this_month]).to eq(75.0)
      expect(groceries[:remaining]).to eq(125.0)
    end

    it 'returns empty array when no budgets exist' do
      expect(Budget.status_summary).to eq([])
    end
  end

  describe '#spent_this_month' do
    let(:budget) { create(:budget, category: "Groceries", monthly_limit: 200) }

    it 'returns total spending for category this month' do
      create(:transaction, category: "Groceries", amount: -50, date: Date.current)
      create(:transaction, category: "Groceries", amount: -30, date: Date.current)

      expect(budget.spent_this_month).to eq(80)
    end

    it 'excludes transactions from other categories' do
      create(:transaction, category: "Groceries", amount: -50, date: Date.current)
      create(:transaction, category: "Bills", amount: -100, date: Date.current)

      expect(budget.spent_this_month).to eq(50)
    end

    it 'excludes transactions from other months' do
      create(:transaction, category: "Groceries", amount: -50, date: Date.current)
      create(:transaction, category: "Groceries", amount: -30, date: 2.months.ago)

      expect(budget.spent_this_month).to eq(50)
    end

    it 'excludes income transactions' do
      create(:transaction, category: "Groceries", amount: -50, date: Date.current)
      create(:transaction, category: "Groceries", amount: 20, date: Date.current)

      expect(budget.spent_this_month).to eq(50)
    end

    it 'returns 0 when no transactions exist' do
      expect(budget.spent_this_month).to eq(0)
    end
  end

  describe '#remaining' do
    it 'returns the remaining budget' do
      budget = create(:budget, category: "Groceries", monthly_limit: 200)
      create(:transaction, category: "Groceries", amount: -75, date: Date.current)

      expect(budget.remaining).to eq(125)
    end

    it 'returns negative when over budget' do
      budget = create(:budget, category: "Groceries", monthly_limit: 50)
      create(:transaction, category: "Groceries", amount: -75, date: Date.current)

      expect(budget.remaining).to eq(-25)
    end
  end

  describe '#percentage_used' do
    it 'returns the percentage of budget used' do
      budget = create(:budget, category: "Groceries", monthly_limit: 200)
      create(:transaction, category: "Groceries", amount: -100, date: Date.current)

      expect(budget.percentage_used).to eq(50.0)
    end

    it 'returns 0 when no spending' do
      budget = create(:budget, category: "Groceries", monthly_limit: 200)
      expect(budget.percentage_used).to eq(0)
    end

    it 'can exceed 100%' do
      budget = create(:budget, category: "Groceries", monthly_limit: 100)
      create(:transaction, category: "Groceries", amount: -150, date: Date.current)

      expect(budget.percentage_used).to eq(150.0)
    end
  end

  describe '#over_budget?' do
    it 'returns true when spending exceeds limit' do
      budget = create(:budget, category: "Groceries", monthly_limit: 50)
      create(:transaction, category: "Groceries", amount: -75, date: Date.current)

      expect(budget.over_budget?).to be true
    end

    it 'returns false when under budget' do
      budget = create(:budget, category: "Groceries", monthly_limit: 200)
      create(:transaction, category: "Groceries", amount: -75, date: Date.current)

      expect(budget.over_budget?).to be false
    end

    it 'returns false when no spending' do
      budget = create(:budget, category: "Groceries", monthly_limit: 200)
      expect(budget.over_budget?).to be false
    end
  end
end
