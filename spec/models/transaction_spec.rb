require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validations' do
    it 'validates presence of date' do
      transaction = build(:transaction, date: nil)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:date]).to include("can't be blank")
    end

    it 'validates presence of description' do
      transaction = build(:transaction, description: nil)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:description]).to include("can't be blank")
    end

    it 'validates presence and numericality of amount' do
      transaction = build(:transaction, amount: nil)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to include("can't be blank")

      transaction.amount = 'not_a_number'
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to include('is not a number')
    end

    it 'validates presence of account' do
      transaction = build(:transaction, account: nil)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:account]).to include("can't be blank")
    end

    it 'validates presence of transaction_id' do
      transaction = build(:transaction, transaction_id: nil)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:transaction_id]).to include("can't be blank")
    end

    it 'validates inclusion of source' do
      transaction = build(:transaction, source: 'invalid_source')
      expect(transaction).not_to be_valid
      expect(transaction.errors[:source]).to include('is not included in the list')
    end

    it 'validates uniqueness of transaction_id scoped to source' do
      create(:transaction, transaction_id: 'unique123', source: 'emma_export')
      transaction = build(:transaction, transaction_id: 'unique123', source: 'emma_export')

      expect(transaction).not_to be_valid
      expect(transaction.errors[:transaction_id]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    let!(:income1) { create(:transaction, amount: 100, date: 1.day.ago) }
    let!(:income2) { create(:transaction, amount: 200, date: 2.days.ago) }
    let!(:expense1) { create(:transaction, amount: -50, date: 1.day.ago) }
    let!(:expense2) { create(:transaction, amount: -75, date: 3.days.ago) }

    describe '.income' do
      it 'returns only transactions with positive amounts' do
        expect(Transaction.income).to contain_exactly(income1, income2)
      end
    end

    describe '.expenses' do
      it 'returns only transactions with negative amounts' do
        expect(Transaction.expenses).to contain_exactly(expense1, expense2)
      end
    end

    describe '.by_date_range' do
      it 'returns transactions within date range' do
        start_date = 2.days.ago.to_date
        end_date = Date.current

        transactions = Transaction.by_date_range(start_date, end_date)
        expect(transactions).to contain_exactly(income1, income2, expense1)
      end
    end

    describe '.distinct_months' do
      before do
        create(:transaction, date: Date.new(2026, 2, 15))
        create(:transaction, date: Date.new(2026, 2, 1))
        create(:transaction, date: Date.new(2026, 1, 10))
        create(:transaction, date: Date.new(2025, 12, 5))
      end

      it 'returns unique months in descending order' do
        months = Transaction.distinct_months(limit: 6)
        expect(months).to eq(%w[2026-02 2026-01 2025-12])
      end

      it 'respects the limit parameter' do
        months = Transaction.distinct_months(limit: 2)
        expect(months).to eq(%w[2026-02 2026-01])
      end
    end

    describe '.by_account' do
      let!(:account1_transaction) { create(:transaction, account: 'account1', source: 'emma_export') }

      it 'returns transactions for specific account' do
        expect(Transaction.by_account('account2')).not_to include(account1_transaction)
        expect(Transaction.by_account('account1')).to contain_exactly(account1_transaction)
      end
    end
  end

  describe 'instance methods' do
    describe '#income?' do
      it 'correctly identifies income transactions' do
        income = build(:transaction, amount: 100)
        expense = build(:transaction, amount: -100)
        zero = build(:transaction, amount: 0)

        expect(income.income?).to be true
        expect(expense.income?).to be false
        expect(zero.income?).to be false
      end
    end

    describe '#expense?' do
      it 'correctly identifies expense transactions' do
        income = build(:transaction, amount: 100)
        expense = build(:transaction, amount: -100)
        zero = build(:transaction, amount: 0)

        expect(income.expense?).to be false
        expect(expense.expense?).to be true
        expect(zero.expense?).to be false
      end
    end

    describe '#formatted_amount' do
      it 'formats positive amounts with £ symbol' do
        transaction = build(:transaction, amount: 100.50)
        expect(transaction.formatted_amount).to eq('£100.50')
      end

      it 'formats negative amounts as positive with £ symbol' do
        transaction = build(:transaction, amount: -50.99)
        expect(transaction.formatted_amount).to eq('£50.99')
      end

      it 'handles zero amounts' do
        transaction = build(:transaction, amount: 0)
        expect(transaction.formatted_amount).to eq('£0.00')
      end
    end
  end

  describe 'bank-specific fields' do
    it 'stores bank-specific data' do
      transaction = create(:transaction,
        transaction_type: 'DEB',
        sort_code: '12-34-56',
        account_number: '12345678',
        balance: 1234.56
      )

      expect(transaction.reload).to have_attributes(
        transaction_type: 'DEB',
        sort_code: '12-34-56',
        account_number: '12345678',
        balance: 1234.56
      )
    end
  end
end
