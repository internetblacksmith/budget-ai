require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      account = build(:account, name: nil)
      expect(account).not_to be_valid
      expect(account.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      create(:account, name: 'Current Account')
      duplicate = build(:account, name: 'Current Account')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
  end

  describe '#current_balance' do
    let(:account) { create(:account, name: 'TestAccount') }

    before do
      create(:transaction, account: 'TestAccount', amount: 200)
      create(:transaction, account: 'TestAccount', amount: -150)
      create(:transaction, account: 'OtherAccount', amount: 100)
    end

    it 'calculates current balance from all transactions' do
      expect(account.current_balance).to eq(50) # 200 - 150
    end
  end
end
