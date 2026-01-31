require 'rails_helper'

RSpec.describe TransactionsHelper, type: :helper do
  describe '#current_params' do
    context 'with all parameters present' do
      before do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(
          show: 'income',
          account: 'current',
          category: 'groceries',
          search: 'tesco',
          amount: '50',
          per: '25'
        ))
      end

      it 'returns all parameters' do
        result = helper.current_params

        expect(result).to include(
          show: 'income',
          account: 'current',
          category: 'groceries',
          search: 'tesco',
          amount: '50',
          per: '25'
        )
      end
    end

    context 'with some parameters present' do
      before do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(
          show: 'expenses',
          account: 'savings'
        ))
      end

      it 'returns only present parameters' do
        result = helper.current_params

        expect(result).to eq(show: 'expenses', account: 'savings')
      end

      it 'does not include nil values' do
        result = helper.current_params

        expect(result).not_to have_key(:search)
        expect(result).not_to have_key(:category)
        expect(result).not_to have_key(:amount)
        expect(result).not_to have_key(:per)
      end
    end

    context 'with no parameters' do
      before do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new({}))
      end

      it 'returns empty hash' do
        result = helper.current_params

        expect(result).to eq({})
      end
    end

    context 'with empty string parameters' do
      before do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(
          show: '',
          account: 'current'
        ))
      end

      it 'includes empty strings (compact does not remove them)' do
        result = helper.current_params

        expect(result).to include(show: '', account: 'current')
      end
    end

    context 'with extra parameters not in whitelist' do
      before do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(
          show: 'income',
          controller: 'transactions',
          action: 'index',
          extra_param: 'should_not_appear'
        ))
      end

      it 'only includes specified parameters' do
        result = helper.current_params

        expect(result).to eq(show: 'income')
        expect(result).not_to have_key(:controller)
        expect(result).not_to have_key(:action)
        expect(result).not_to have_key(:extra_param)
      end
    end
  end
end
