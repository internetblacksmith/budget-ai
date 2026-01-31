require "rails_helper"

RSpec.describe "Imports", type: :request do
  describe "GET /imports" do
    it "renders the imports page" do
      get imports_path
      expect(response).to have_http_status(:ok)
    end

    context "when Google is connected" do
      before do
        # Set session values via a preliminary request
        post "/google_auth/fake_session",
             params: { access_token: "fake", email: "test@example.com" }
      rescue ActionController::RoutingError
        # Route doesn't exist; use controller-level stubbing instead
      end

      it "shows the spreadsheet selector with Stimulus controller" do
        # Stub the controller to simulate a connected Google session
        allow_any_instance_of(ImportsController).to receive(:index).and_wrap_original do |method, *args|
          controller = method.receiver
          controller.session[:google_access_token] = "fake_token"
          controller.session[:google_user_email] = "test@example.com"
          method.call(*args)
        end

        get imports_path
        expect(response.body).to include('data-controller="import-form"')
        expect(response.body).to include('data-import-form-target="spreadsheetSelect"')
      end
    end
  end

  describe "GET /imports/list_spreadsheets" do
    context "when not connected to Google" do
      it "returns unauthorized" do
        get list_spreadsheets_imports_path
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Not connected to Google")
      end
    end
  end

  describe "GET /imports/list_spreadsheet_sheets" do
    context "when not connected to Google" do
      it "returns unauthorized" do
        get list_spreadsheet_sheets_imports_path, params: { spreadsheet_id: "abc" }
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Not connected to Google")
      end
    end
  end

  describe "DELETE /imports/reset_database" do
    it "deletes all transactions and import jobs and redirects" do
      create(:transaction)
      create(:import_job, :completed)

      expect { delete reset_database_imports_path }.to change(Transaction, :count).to(0)
        .and change(ImportJob, :count).to(0)

      expect(response).to redirect_to(imports_path)
      follow_redirect!
      expect(response.body).to include("All transactions and import history have been cleared")
    end
  end

  describe "POST /imports/import_emma" do
    context "without a spreadsheet_id" do
      it "redirects with an alert" do
        post import_emma_imports_path, params: { spreadsheet_id: "", sheet_name: "Sheet1" }
        expect(response).to redirect_to(imports_path)
        follow_redirect!
        expect(response.body).to include("Please select a spreadsheet")
      end
    end
  end
end
