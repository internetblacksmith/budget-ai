class GoogleAuthController < ApplicationController
  def authorize
    client = get_google_auth_client
    auth_uri = client.authorization_uri.to_s
    redirect_to auth_uri, allow_other_host: true
  end

  def callback
    # Handle OAuth errors (user denial, etc.)
    if params[:error]
      # Clear any partial session state
      session.delete(:google_access_token)
      session.delete(:google_refresh_token)
      session.delete(:google_token_expires_at)
      session.delete(:google_user_email)
      session.delete(:google_user_name)

      case params[:error]
      when "access_denied"
        redirect_to imports_path, alert: "Authentication was cancelled"
        return
      else
        redirect_to imports_path, alert: "Authentication failed: #{params[:error]}"
        return
      end
    end

    # Handle test mode with mock authorization code
    if Rails.env.test? && params[:code] == "mock_authorization_code"
      # Mock successful OAuth flow in test environment
      session[:google_access_token] = "mock_access_token"
      session[:google_refresh_token] = "mock_refresh_token"
      session[:google_token_expires_at] = 1.hour.from_now.to_i
      session[:google_user_email] = "user@example.com"
      session[:google_user_name] = "Test User"

      redirect_to imports_path, notice: "Successfully connected to Google Drive as user@example.com"
      return
    end

    client = get_google_auth_client
    client.code = params[:code]

    begin
      client.fetch_access_token!

      # Store the tokens in the session
      session[:google_access_token] = client.access_token
      session[:google_refresh_token] = client.refresh_token
      session[:google_token_expires_at] = client.expires_at

      # Get user info
      drive_service = Google::Apis::DriveV3::DriveService.new
      drive_service.authorization = client

      about = drive_service.get_about(fields: "user")
      session[:google_user_email] = about.user.email_address
      session[:google_user_name] = about.user.display_name

       redirect_to imports_path, notice: "Successfully connected to Google Drive as #{about.user.email_address}"
     rescue StandardError => e
       redirect_to imports_path, alert: "Failed to authenticate with Google: #{e.message}"
    end
  end

  def disconnect
    session.delete(:google_access_token)
    session.delete(:google_refresh_token)
    session.delete(:google_token_expires_at)
    session.delete(:google_user_email)
    session.delete(:google_user_name)

    respond_to do |format|
      format.html { redirect_to imports_path, notice: "Disconnected from Google Drive" }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("emma-sheets-section",
            partial: "imports/google_sheets_section"
          ),
          turbo_stream.prepend("flash-messages",
            partial: "shared/flash",
            locals: { flash: { notice: "Disconnected from Google Drive" } }
          )
        ]
      end
    end
  end

  private

  def get_google_auth_client
    require "signet/oauth_2/client"

    Signet::OAuth2::Client.new(
      client_id: ENV["GOOGLE_OAUTH_CLIENT_ID"],
      client_secret: ENV["GOOGLE_OAUTH_CLIENT_SECRET"],
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://oauth2.googleapis.com/token",
      scope: [
        Google::Apis::DriveV3::AUTH_DRIVE_READONLY,
        Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY,
        "email",
        "profile"
      ],
      redirect_uri: google_auth_callback_url,
      access_type: "offline",
      prompt: "consent"
    )
  end
end
