require 'rails_helper'
require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'

RSpec.describe GoogleDriveService do
  let(:oauth_tokens) { { access_token: "fake_token", refresh_token: "fake_refresh" } }
  let(:service) { described_class.new(oauth_tokens) }
  let(:spreadsheet_id) { "fake_spreadsheet_id" }

  describe "#initialize" do
    it "accepts OAuth tokens" do
      expect(service.instance_variable_get(:@oauth_tokens)).to eq(oauth_tokens)
    end
  end

  describe "#fetch_emma_transactions" do
    let(:mock_sheets_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }
    let(:mock_authorization) { double("authorization") }
    let(:mock_response) { double("response") }

    before do
      allow(service).to receive(:authorize).and_return(nil)
      allow(service).to receive(:instance_variable_get).with(:@authorization).and_return(mock_authorization)
      allow(Google::Apis::SheetsV4::SheetsService).to receive(:new).and_return(mock_sheets_service)
      allow(mock_sheets_service).to receive(:authorization=)
    end

    context "when spreadsheet has data" do
      let(:headers) { [ "Transaction ID", "Date", "Time", "Type", "Name", "Emoji", "Category", "Amount", "Currency", "Local amount", "Local currency", "Notes and #tags", "Address", "Receipt", "Description", "Category split" ] }
      let(:data_row1) { [ "tx_001", "2025-01-15", "14:30", "Card payment", "Tesco", "🛒", "Groceries", "-45.50", "GBP", "-45.50", "GBP", "#weekly-shop", "123 High St", nil, "Tesco Express", nil ] }
      let(:data_row2) { [ "tx_002", "2025-01-14", "09:00", "Transfer", "Salary", "💰", "Income", "2500.00", "GBP", "2500.00", "GBP", "#salary", nil, nil, "Monthly salary", nil ] }

      before do
        allow(mock_response).to receive(:values).and_return([ headers, data_row1, data_row2 ])
        allow(mock_sheets_service).to receive(:get_spreadsheet_values).with(spreadsheet_id, "A:Q").and_return(mock_response)
      end

      it "returns array of transaction hashes" do
        result = service.fetch_emma_transactions(spreadsheet_id)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)

        expect(result[0]["Transaction ID"]).to eq("tx_001")
        expect(result[0]["Amount"]).to eq("-45.50")
        expect(result[0]["Category"]).to eq("Groceries")

        expect(result[1]["Transaction ID"]).to eq("tx_002")
        expect(result[1]["Amount"]).to eq("2500.00")
        expect(result[1]["Category"]).to eq("Income")
      end

      it "handles rows with missing columns" do
        short_row = [ "tx_003", "2025-01-13", "10:00" ]
        allow(mock_response).to receive(:values).and_return([ headers, short_row ])
        allow(mock_sheets_service).to receive(:get_spreadsheet_values).with(spreadsheet_id, "A:Q").and_return(mock_response)

        result = service.fetch_emma_transactions(spreadsheet_id)

        expect(result.length).to eq(1)
        expect(result[0]["Transaction ID"]).to eq("tx_003")
        expect(result[0]["Amount"]).to be_nil
      end

      it "uses custom sheet when provided" do
        sheet_name = "Sheet1"
        expected_range = "'Sheet1'!A:Q"
        allow(mock_sheets_service).to receive(:get_spreadsheet_values).with(spreadsheet_id, expected_range).and_return(mock_response)

        service.fetch_emma_transactions(spreadsheet_id, sheet_name)

        expect(mock_sheets_service).to have_received(:get_spreadsheet_values).with(spreadsheet_id, expected_range)
      end
    end

    context "when spreadsheet is empty" do
      before do
        allow(mock_response).to receive(:values).and_return(nil)
        allow(mock_sheets_service).to receive(:get_spreadsheet_values).and_return(mock_response)
      end

      it "raises error" do
        expect { service.fetch_emma_transactions(spreadsheet_id) }.to raise_error("No data found in sheet default")
      end
    end

    context "when Google API returns error" do
      before do
        allow(mock_sheets_service).to receive(:get_spreadsheet_values).and_raise(Google::Apis::Error.new("API error"))
      end

      it "raises error with message" do
        expect { service.fetch_emma_transactions(spreadsheet_id) }.to raise_error("Failed to fetch spreadsheet: API error")
      end
    end
  end

  describe "#authorize" do
    context "with OAuth tokens" do
      let(:oauth_tokens) { { access_token: "test_token", refresh_token: "refresh_token" } }
      let(:service) { described_class.new(oauth_tokens) }
      let(:mock_client) { instance_double(Signet::OAuth2::Client) }

      before do
        allow(Signet::OAuth2::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:expired?).and_return(false)
      end

      it "creates OAuth2 client with tokens" do
        service.send(:authorize)

        expect(Signet::OAuth2::Client).to have_received(:new).with(
          hash_including(
            access_token: "test_token",
            refresh_token: "refresh_token"
          )
        )
      end

      it "refreshes expired tokens" do
        allow(mock_client).to receive(:expired?).and_return(true)
        allow(mock_client).to receive(:client_id=)
        allow(mock_client).to receive(:client_secret=)
        allow(mock_client).to receive(:token_credential_uri=)
        allow(mock_client).to receive(:refresh!)

        service.send(:authorize)

        expect(mock_client).to have_received(:refresh!)
      end
    end

    context "without OAuth tokens" do
      let(:service) { described_class.new(nil) }

      it "raises error" do
        expect { service.send(:authorize) }.to raise_error("No Google OAuth tokens provided. Please authenticate with Google first.")
      end
    end
  end

  describe "#list_sheets" do
    let(:spreadsheet_id) { "test_spreadsheet_123" }
    let(:mock_sheets_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }
    let(:mock_spreadsheet) { instance_double(Google::Apis::SheetsV4::Spreadsheet) }
    let(:mock_sheet) { instance_double(Google::Apis::SheetsV4::Sheet) }
    let(:mock_properties) { instance_double(Google::Apis::SheetsV4::SheetProperties) }
    let(:mock_grid_properties) { instance_double(Google::Apis::SheetsV4::GridProperties) }

    before do
      allow(service).to receive(:authorize)
      allow(Google::Apis::SheetsV4::SheetsService).to receive(:new).and_return(mock_sheets_service)
      allow(mock_sheets_service).to receive(:authorization=)

      allow(mock_properties).to receive(:sheet_id).and_return(123)
      allow(mock_properties).to receive(:title).and_return("Sheet1")
      allow(mock_properties).to receive(:index).and_return(0)
      allow(mock_properties).to receive(:grid_properties).and_return(mock_grid_properties)
      allow(mock_grid_properties).to receive(:row_count).and_return(100)
      allow(mock_grid_properties).to receive(:column_count).and_return(10)
      allow(mock_sheet).to receive(:properties).and_return(mock_properties)
      allow(mock_spreadsheet).to receive(:sheets).and_return([ mock_sheet ])

      allow(mock_sheets_service).to receive(:get_spreadsheet).and_return(mock_spreadsheet)
    end

    it "returns array of sheet information" do
      result = service.list_sheets(spreadsheet_id)

      expect(result).to be_an(Array)
      expect(result.first).to include(
        id: 123,
        title: "Sheet1",
        index: 0,
        row_count: 100,
        column_count: 10
      )
    end
  end

  describe "#get_account_info" do
    context "with OAuth tokens including user info" do
      let(:oauth_tokens) {
        {
          access_token: "fake_token",
          user_email: "user@example.com",
          user_name: "Test User"
        }
      }
      let(:service) { described_class.new(oauth_tokens) }

      it "returns OAuth user info" do
        allow(service).to receive(:authorize)

        result = service.get_account_info

        expect(result).to eq({
          email: "user@example.com",
          name: "Test User",
          type: "oauth2"
        })
      end

      context "without user_name" do
        let(:oauth_tokens) {
          {
            access_token: "fake_token",
            user_email: "user@example.com"
          }
        }

        it "defaults to 'Google User'" do
          allow(service).to receive(:authorize)

          result = service.get_account_info

          expect(result[:name]).to eq("Google User")
        end
      end
    end

    context "with Signet::OAuth2::Client authorization" do
      let(:oauth_tokens) { { access_token: "test_token", refresh_token: "refresh" } }
      let(:service) { described_class.new(oauth_tokens) }
      let(:mock_client) { instance_double(Signet::OAuth2::Client) }
      let(:mock_drive_service) { instance_double(Google::Apis::DriveV3::DriveService) }
      let(:mock_about) { double("about") }
      let(:mock_user) { double("user") }

      before do
        allow(Signet::OAuth2::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:expired?).and_return(false)
        allow(mock_client).to receive(:is_a?).with(Signet::OAuth2::Client).and_return(true)

        allow(Google::Apis::DriveV3::DriveService).to receive(:new).and_return(mock_drive_service)
        allow(mock_drive_service).to receive(:authorization=)
        allow(mock_drive_service).to receive(:get_about).and_return(mock_about)
        allow(mock_about).to receive(:user).and_return(mock_user)
        allow(mock_user).to receive(:email_address).and_return("oauth_user@example.com")
        allow(mock_user).to receive(:display_name).and_return("OAuth User")
      end

      it "returns user info from Drive API" do
        result = service.get_account_info

        expect(result).to eq({
          email: "oauth_user@example.com",
          name: "OAuth User",
          type: "oauth2"
        })
      end
    end

    context "without OAuth tokens" do
      let(:service) { described_class.new(nil) }

      it "returns error info when no auth available" do
        result = service.get_account_info

        expect(result).to eq({
          email: "error@example.com",
          name: "Error loading account",
          type: "error"
        })
      end
    end
  end

  describe "#list_spreadsheets" do
    let(:mock_drive_service) { instance_double(Google::Apis::DriveV3::DriveService) }
    let(:mock_response) { double("response") }
    let(:mock_file) { double("file") }
    let(:mock_owner) { double("owner") }

    before do
      allow(service).to receive(:authorize)
      allow(Google::Apis::DriveV3::DriveService).to receive(:new).and_return(mock_drive_service)
      allow(mock_drive_service).to receive(:authorization=)
    end

    context "when spreadsheets exist" do
      before do
        allow(mock_owner).to receive(:display_name).and_return("Test Owner")
        allow(mock_file).to receive(:id).and_return("spreadsheet_123")
        allow(mock_file).to receive(:name).and_return("Budget 2025")
        allow(mock_file).to receive(:modified_time).and_return(Time.parse("2025-01-15 10:00:00"))
        allow(mock_file).to receive(:owners).and_return([ mock_owner ])
        allow(mock_file).to receive(:web_view_link).and_return("https://docs.google.com/spreadsheets/d/spreadsheet_123")
        allow(mock_response).to receive(:files).and_return([ mock_file ])
        allow(mock_drive_service).to receive(:list_files).and_return(mock_response)
      end

      it "returns array of spreadsheet information" do
        result = service.list_spreadsheets

        expect(result).to be_an(Array)
        expect(result.first).to include(
          id: "spreadsheet_123",
          name: "Budget 2025",
          owner: "Test Owner"
        )
      end

      it "accepts limit parameter" do
        expect(mock_drive_service).to receive(:list_files).with(
          hash_including(page_size: 10)
        ).and_return(mock_response)

        service.list_spreadsheets(10)
      end

      context "when file has no owners" do
        before do
          allow(mock_file).to receive(:owners).and_return(nil)
        end

        it "defaults owner to 'Unknown'" do
          result = service.list_spreadsheets

          expect(result.first[:owner]).to eq("Unknown")
        end
      end
    end

    context "when API error occurs" do
      before do
        allow(mock_drive_service).to receive(:list_files).and_raise(Google::Apis::Error.new("API error"))
      end

      it "raises error with message" do
        expect { service.list_spreadsheets }.to raise_error("Failed to list spreadsheets: API error")
      end
    end
  end

  describe "#list_sheets error handling" do
    let(:spreadsheet_id) { "test_spreadsheet_123" }
    let(:mock_sheets_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }

    before do
      allow(service).to receive(:authorize)
      allow(Google::Apis::SheetsV4::SheetsService).to receive(:new).and_return(mock_sheets_service)
      allow(mock_sheets_service).to receive(:authorization=)
    end

    context "when API error occurs" do
      before do
        allow(mock_sheets_service).to receive(:get_spreadsheet).and_raise(Google::Apis::Error.new("Access denied"))
      end

      it "raises error with message" do
        expect { service.list_sheets(spreadsheet_id) }.to raise_error("Failed to list sheets: Access denied")
      end
    end
  end

  describe "#fetch_emma_transactions edge cases" do
    let(:mock_sheets_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }
    let(:mock_response) { double("response") }

    before do
      allow(service).to receive(:authorize)
      allow(service).to receive(:instance_variable_get).with(:@authorization).and_return(double("authorization"))
      allow(Google::Apis::SheetsV4::SheetsService).to receive(:new).and_return(mock_sheets_service)
      allow(mock_sheets_service).to receive(:authorization=)
    end

    context "when values array is empty" do
      before do
        allow(mock_response).to receive(:values).and_return([])
        allow(mock_sheets_service).to receive(:get_spreadsheet_values).and_return(mock_response)
      end

      it "raises error for empty data" do
        expect { service.fetch_emma_transactions(spreadsheet_id) }.to raise_error("No data found in sheet default")
      end
    end

    context "with custom sheet name when empty" do
      before do
        allow(mock_response).to receive(:values).and_return(nil)
        allow(mock_sheets_service).to receive(:get_spreadsheet_values).and_return(mock_response)
      end

      it "includes sheet name in error message" do
        expect { service.fetch_emma_transactions(spreadsheet_id, "MySheet") }.to raise_error("No data found in sheet MySheet")
      end
    end
  end
end
