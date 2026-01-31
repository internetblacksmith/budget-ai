require 'rails_helper'

RSpec.describe EmmaSpreadsheetImportService, type: :service do
  let(:oauth_tokens) { { access_token: 'test_token' } }
  let(:spreadsheet_id) { 'test_spreadsheet_id' }
  let(:service) { described_class.new(spreadsheet_id, oauth_tokens) }

  let(:mock_google_service) { instance_double(GoogleDriveService) }
  let(:sample_emma_data) do
    [
      {
        'ID' => 'f9bb6f7e33c6dd9a554f4e904b62c2ff',
        'Date' => '3/28/2024',
        'Amount' => '4637.56',
        'Account' => 'Current Account',
        'Bank' => 'Halifax',
        'Currency' => 'GBP',
        'Category' => 'Income',
        'Subcategory' => '',
        'Type' => 'Credit',
        'Tags' => '',
        'Counterparty' => 'BOXT LIMITED',
        'Custom Name' => '',
        'Merchant' => '',
        'Additional details' => '',
        'Notes' => '',
        'Linked transaction ID' => ''
      },
      {
        'ID' => '8e734a1e0b1f0270b06ef87403e58d9a',
        'Date' => '3/28/2024',
        'Amount' => '-21',
        'Account' => 'Current Account',
        'Bank' => 'Halifax',
        'Currency' => 'GBP',
        'Category' => 'Bills',
        'Subcategory' => '',
        'Type' => 'Direct Debit',
        'Tags' => '',
        'Counterparty' => 'THAMES WATER',
        'Custom Name' => '',
        'Merchant' => 'Thames Water',
        'Additional details' => '',
        'Notes' => '',
        'Linked transaction ID' => ''
      },
      {
        'ID' => '73f0fc6c0b061a42426efe2f928e8abd',
        'Date' => '3/28/2024',
        'Amount' => '-8.95',
        'Account' => 'Personal Account',
        'Bank' => 'Monzo',
        'Currency' => 'GBP',
        'Category' => 'General',
        'Subcategory' => 'Eating Out',
        'Type' => 'Purchase',
        'Tags' => 'lunch,work',
        'Counterparty' => 'MAUI POKE - RED LI London GBR',
        'Custom Name' => 'Friday Lunch',
        'Merchant' => 'Maui Poke - Red Li',
        'Additional details' => 'Card ending 1234',
        'Notes' => '',
        'Linked transaction ID' => 'linked-abc-123'
      }
    ]
  end

  before do
    allow(GoogleDriveService).to receive(:new).and_return(mock_google_service)
    allow(mock_google_service).to receive(:fetch_emma_transactions).and_return(sample_emma_data)
  end

  describe '#import' do
    it 'fetches data from Google Sheets' do
      expect(mock_google_service).to receive(:fetch_emma_transactions)
        .with(spreadsheet_id, nil)
        .and_return(sample_emma_data)

      service.import
    end

    it 'creates transactions from Emma data' do
      expect {
        service.import
      }.to change(Transaction, :count).by(3)
    end

    it 'returns true on success' do
      result = service.import
      expect(result).to be true
    end

    it 'sets imported_count' do
      service.import
      expect(service.imported_count).to eq(3)
    end

    context 'with empty spreadsheet' do
      before do
        allow(mock_google_service).to receive(:fetch_emma_transactions).and_return([])
      end

      it 'returns true with 0 imports' do
        result = service.import
        expect(result).to be true
        expect(service.imported_count).to eq(0)
      end
    end

    context 'when Google API fails' do
      before do
        allow(mock_google_service).to receive(:fetch_emma_transactions)
          .and_raise(StandardError, 'API Error')
      end

      it 'returns false' do
        result = service.import
        expect(result).to be false
      end

      it 'adds error message' do
        service.import
        expect(service.errors).to include('Import failed: API Error')
      end
    end
  end

  describe 'transaction parsing' do
    before { service.import }

    it 'creates transactions with correct IDs' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction).to be_present
    end

    it 'parses dates correctly (MM/DD/YYYY format)' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.date).to eq(Date.new(2024, 3, 28))
    end

    it 'parses positive amounts as income' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.amount).to eq(4637.56)
      expect(transaction.income?).to be true
    end

    it 'parses negative amounts as expenses' do
      transaction = Transaction.find_by(transaction_id: '8e734a1e0b1f0270b06ef87403e58d9a')
      expect(transaction.amount).to eq(-21.0)
      expect(transaction.expense?).to be true
    end

    it 'builds account name from Bank and Account fields' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.account).to eq('Halifax Current Account')
    end

    it 'uses merchant name for description when available' do
      transaction = Transaction.find_by(transaction_id: '8e734a1e0b1f0270b06ef87403e58d9a')
      expect(transaction.description).to include('Thames Water')
    end

    it 'uses counterparty when merchant not available' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.description).to include('BOXT LIMITED')
    end

    it 'maps categories' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.category).to eq('Income')
    end

    it 'stores bank as a column' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.bank).to eq('Halifax')
    end

    it 'stores currency as a column' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.currency).to eq('GBP')
    end

    it 'stores counterparty as a column' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.counterparty).to eq('BOXT LIMITED')
    end

    it 'stores merchant as a column' do
      transaction = Transaction.find_by(transaction_id: '8e734a1e0b1f0270b06ef87403e58d9a')
      expect(transaction.merchant).to eq('Thames Water')
    end

    it 'stores nil for blank optional fields' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.subcategory).to be_nil
      expect(transaction.tags).to be_nil
      expect(transaction.custom_name).to be_nil
      expect(transaction.additional_details).to be_nil
      expect(transaction.linked_transaction_id).to be_nil
    end

    it 'stores non-blank optional fields' do
      transaction = Transaction.find_by(transaction_id: '73f0fc6c0b061a42426efe2f928e8abd')
      expect(transaction.subcategory).to eq('Eating Out')
      expect(transaction.tags).to eq('lunch,work')
      expect(transaction.custom_name).to eq('Friday Lunch')
      expect(transaction.additional_details).to eq('Card ending 1234')
      expect(transaction.linked_transaction_id).to eq('linked-abc-123')
    end

    it 'stores account_name as a column' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.account_name).to eq('Current Account')
    end

    it 'stores emma_category as a column' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.emma_category).to eq('Income')
    end

    it 'sets source as emma_export' do
      transaction = Transaction.find_by(transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff')
      expect(transaction.source).to eq('emma_export')
    end
  end

  describe 'on_progress callback' do
    it 'calls on_progress with 0 and total before processing rows' do
      progress_calls = []
      on_progress = ->(imported, total) { progress_calls << [ imported, total ] }
      service_with_progress = described_class.new(spreadsheet_id, oauth_tokens, nil, on_progress: on_progress)

      service_with_progress.import

      expect(progress_calls.first).to eq([ 0, 3 ])
    end

    it 'calls on_progress after each successfully imported row' do
      progress_calls = []
      on_progress = ->(imported, total) { progress_calls << [ imported, total ] }
      service_with_progress = described_class.new(spreadsheet_id, oauth_tokens, nil, on_progress: on_progress)

      service_with_progress.import

      expect(progress_calls).to eq([
        [ 0, 3 ],
        [ 1, 3 ],
        [ 2, 3 ],
        [ 3, 3 ]
      ])
    end

    it 'works without on_progress callback' do
      expect { service.import }.not_to raise_error
    end
  end

  describe 'handling existing transactions' do
    before do
      # Create existing transaction with same source
      create(:transaction, transaction_id: 'f9bb6f7e33c6dd9a554f4e904b62c2ff', source: 'emma_export')
    end

    it 'logs error for duplicate transaction_id' do
      service.import
      # Emma data should be clean, but if there are duplicates, they're logged as errors
      expect(service.errors).not_to be_empty
    end
  end

  describe 'row skipping' do
    let(:data_with_bad_rows) do
      [
        {
          'ID' => '',
          'Date' => '3/28/2024',
          'Amount' => '100',
          'Account' => 'Test',
          'Bank' => 'Test',
          'Counterparty' => 'Test'
        },
        {
          'ID' => 'valid-id',
          'Date' => '',
          'Amount' => '100',
          'Account' => 'Test',
          'Bank' => 'Test',
          'Counterparty' => 'Test'
        },
        {
          'ID' => 'valid-id-2',
          'Date' => '3/28/2024',
          'Amount' => '',
          'Account' => 'Test',
          'Bank' => 'Test',
          'Counterparty' => 'Test'
        },
        {
          'ID' => 'good-id',
          'Date' => '3/28/2024',
          'Amount' => '100',
          'Account' => 'Test',
          'Bank' => 'Test',
          'Counterparty' => 'Good Transaction'
        }
      ]
    end

    before do
      allow(mock_google_service).to receive(:fetch_emma_transactions)
        .and_return(data_with_bad_rows)
    end

    it 'skips rows with missing essential fields' do
      service.import
      expect(service.imported_count).to eq(1)
    end
  end

  describe 'transfer detection' do
    let(:transfer_data) do
      [
        {
          'ID' => 'transfer-id',
          'Date' => '3/28/2024',
          'Amount' => '-100',
          'Account' => 'Current',
          'Bank' => 'Halifax',
          'Counterparty' => 'Transfer to Savings',
          'Merchant' => '',
          'Type' => 'Transfer',
          'Category' => 'General',
          'Notes' => ''
        }
      ]
    end

    before do
      allow(mock_google_service).to receive(:fetch_emma_transactions)
        .and_return(transfer_data)
    end

    it 'detects transfers from description keywords' do
      service.import
      transaction = Transaction.find_by(transaction_id: 'transfer-id')
      expect(transaction.is_transfer).to be true
    end

    it 'detects transfers from Emma Transfer category' do
      transfer_data.first['Counterparty'] = 'Some Payment'
      transfer_data.first['Category'] = 'Transfer'
      service.import
      transaction = Transaction.find_by(transaction_id: 'transfer-id')
      expect(transaction.is_transfer).to be true
    end

    it 'detects transfers from Emma Excluded category' do
      transfer_data.first['Counterparty'] = 'Credit Card Payment'
      transfer_data.first['Category'] = 'Excluded'
      service.import
      transaction = Transaction.find_by(transaction_id: 'transfer-id')
      expect(transaction.is_transfer).to be true
    end

    context 'with Monzo Flex repayments' do
      let(:flex_data) do
        [
          {
            'ID' => 'flex-repay-id',
            'Date' => '3/28/2024',
            'Amount' => '325.46',
            'Account' => 'Monzo Flex',
            'Bank' => 'Monzo',
            'Counterparty' => '',
            'Merchant' => 'Flex',
            'Type' => 'Other',
            'Category' => 'Income',
            'Notes' => ''
          }
        ]
      end

      before do
        allow(mock_google_service).to receive(:fetch_emma_transactions)
          .and_return(flex_data)
      end

      it 'detects Flex repayments as transfers' do
        service.import
        transaction = Transaction.find_by(transaction_id: 'flex-repay-id')
        expect(transaction.is_transfer).to be true
      end
    end

    context 'with PayPal Credit movements' do
      let(:paypal_credit_data) do
        [
          {
            'ID' => 'paypal-credit-id',
            'Date' => '3/28/2024',
            'Amount' => '89.99',
            'Account' => 'PayPal GBP',
            'Bank' => 'PayPal',
            'Counterparty' => 'PayPal Credit',
            'Merchant' => 'PayPal',
            'Type' => 'Other',
            'Category' => 'Income',
            'Notes' => ''
          }
        ]
      end

      before do
        allow(mock_google_service).to receive(:fetch_emma_transactions)
          .and_return(paypal_credit_data)
      end

      it 'detects PayPal Credit movements as transfers' do
        service.import
        transaction = Transaction.find_by(transaction_id: 'paypal-credit-id')
        expect(transaction.is_transfer).to be true
      end
    end
  end

  describe 'error handling' do
    context 'with invalid date format' do
      let(:bad_date_data) do
        [
          {
            'ID' => 'test-id',
            'Date' => 'invalid-date',
            'Amount' => '100',
            'Account' => 'Test',
            'Bank' => 'Test',
            'Counterparty' => 'Test'
          }
        ]
      end

      before do
        allow(mock_google_service).to receive(:fetch_emma_transactions)
          .and_return(bad_date_data)
      end

      it 'skips rows with invalid dates' do
        service.import
        expect(service.imported_count).to eq(0)
      end
    end

    context 'with invalid amount' do
      let(:bad_amount_data) do
        [
          {
            'ID' => 'test-id',
            'Date' => '3/28/2024',
            'Amount' => 'not-a-number',
            'Account' => 'Test',
            'Bank' => 'Test',
            'Counterparty' => 'Test'
          }
        ]
      end

      before do
        allow(mock_google_service).to receive(:fetch_emma_transactions)
          .and_return(bad_amount_data)
      end

      it 'converts invalid amounts to 0.0' do
        service.import
        transaction = Transaction.find_by(transaction_id: 'test-id')
        expect(transaction.amount).to eq(0.0)
      end
    end
  end
end
