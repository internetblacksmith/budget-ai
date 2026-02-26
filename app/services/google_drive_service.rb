require "google/apis/sheets_v4"
require "google/apis/drive_v3"
require "googleauth"

class GoogleDriveService
  class Error < StandardError; end
  class AuthenticationError < Error; end

  def initialize(oauth_tokens = nil)
    @oauth_tokens = oauth_tokens
  end

  def list_spreadsheets(limit = 20)
    authorize

    drive_service = Google::Apis::DriveV3::DriveService.new
    drive_service.authorization = @authorization

    begin
      # Query for Google Sheets files only
      query = "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false"

      response = drive_service.list_files(
        q: query,
        page_size: limit,
        fields: "files(id,name,modifiedTime,owners,webViewLink)",
        order_by: "modifiedTime desc"
      )

      response.files.map do |file|
        {
          id: file.id,
          name: file.name,
          modified_time: file.modified_time,
          owner: file.owners&.first&.display_name || "Unknown",
          web_link: file.web_view_link
        }
      end
    rescue Google::Apis::Error => e
      raise Error, "Failed to list spreadsheets: #{e.message}"
    end
  end

  def list_sheets(spreadsheet_id)
    authorize

    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = @authorization

    begin
      spreadsheet = service.get_spreadsheet(spreadsheet_id, fields: "sheets.properties")

      spreadsheet.sheets.map do |sheet|
        {
          id: sheet.properties.sheet_id,
          title: sheet.properties.title,
          index: sheet.properties.index,
          row_count: sheet.properties.grid_properties.row_count,
          column_count: sheet.properties.grid_properties.column_count
        }
      end
    rescue Google::Apis::Error => e
      raise Error, "Failed to list sheets: #{e.message}"
    end
  end

  # Fetch Emma budget app export from Google Sheets
  def fetch_emma_transactions(spreadsheet_id, sheet_name = nil)
    fetch_spreadsheet_data(spreadsheet_id, sheet_name)
  end

  private

  # Generic method to fetch spreadsheet data and convert to array of hashes
  def fetch_spreadsheet_data(spreadsheet_id, sheet_name = nil)
    authorize

    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = @authorization

    begin
      # Use provided sheet name or default to first sheet
      # Emma exports have many columns (ID through Linked transaction ID = 16 columns A:P)
      sanitized_name = sheet_name&.gsub("'", "''")
      range = sanitized_name ? "'#{sanitized_name}'!A:Q" : "A:Q"

      response = service.get_spreadsheet_values(spreadsheet_id, range)

      if response.values.nil? || response.values.empty?
        raise Error, "No data found in sheet #{sheet_name || 'default'}"
      end

      # First row contains headers
      headers = response.values.first
      data_rows = response.values[1..-1] || []

      # Convert to array of hashes for easier processing
      transactions = data_rows.map do |row|
        # Ensure row has enough columns by padding with nils
        padded_row = row + Array.new([ headers.length - row.length, 0 ].max, nil)

        Hash[headers.zip(padded_row)]
      end

      transactions
    rescue Google::Apis::Error => e
      raise Error, "Failed to fetch spreadsheet: #{e.message}"
    end
  end

  def authorize
    # Prefer OAuth2 tokens if available
    if @oauth_tokens && @oauth_tokens[:access_token]
      require "signet/oauth_2/client"

      @authorization = Signet::OAuth2::Client.new(
        access_token: @oauth_tokens[:access_token],
        refresh_token: @oauth_tokens[:refresh_token],
        expires_at: @oauth_tokens[:expires_at]
      )

      # Refresh token if expired
      if @authorization.expired?
        @authorization.client_id = ENV["GOOGLE_OAUTH_CLIENT_ID"]
        @authorization.client_secret = ENV["GOOGLE_OAUTH_CLIENT_SECRET"]
        @authorization.token_credential_uri = "https://oauth2.googleapis.com/token"
        @authorization.refresh!
      end
    else
      raise AuthenticationError, "No Google OAuth tokens provided. Please authenticate with Google first."
    end
  end
end
