class ImportsController < ApplicationController
  include AccountStatistics
  allow_browser versions: :modern if respond_to?(:allow_browser)

  def index
    @recent_imports = ImportJob.completed_recently.limit(5)

    @google_connected = session[:google_access_token].present?
    @google_user_email = session[:google_user_email]
  end

  def list_spreadsheets
    unless session[:google_access_token].present?
      render json: { error: "Not connected to Google" }, status: :unauthorized
      return
    end

    begin
      service = GoogleDriveService.new({ access_token: session[:google_access_token] })
      spreadsheets = service.list_spreadsheets
      render json: spreadsheets.map { |s| { id: s[:id], name: s[:name] } }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def list_spreadsheet_sheets
    unless session[:google_access_token].present?
      render json: { error: "Not connected to Google" }, status: :unauthorized
      return
    end

    begin
      service = GoogleDriveService.new({ access_token: session[:google_access_token] })
      sheets = service.list_sheets(params[:spreadsheet_id])
      render json: sheets
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def import_emma
    spreadsheet_id = params[:spreadsheet_id]
    sheet_name = params[:sheet_name]

    unless spreadsheet_id.present?
      redirect_to imports_path, alert: "Please select a spreadsheet"
      return
    end

    import_job = ImportJob.create!(
      source: "emma_export",
      total_files: 1,
      status: "pending"
    )

    EmmaSpreadsheetImportJob.perform_later(
      import_job.id,
      spreadsheet_id,
      { access_token: session[:google_access_token] },
      sheet_name
    )

    redirect_to imports_path, notice: "Import started! Check back in a moment."
  end

  def reset_database
    unless params[:confirm] == "DELETE ALL DATA"
      redirect_to imports_path, alert: "Confirmation required to reset database."
      return
    end

    TransactionEdit.delete_all
    Transaction.delete_all
    ChatMessage.delete_all
    ImportJob.delete_all
    Account.delete_all
    CachedStatisticsService.new.invalidate_all!

    redirect_to imports_path, notice: "All transactions and import history have been cleared."
  end

  def check_import_status
    case find_relevant_import_job
    in ImportJob => job
      render json: build_status_response(job)
    in nil
      render json: { status: "none" }
    end
  end

  private

  def find_relevant_import_job
    ImportJob.active.recent.first || ImportJob.completed_recently.recent.first
  end

  def build_status_response(job)
    {
      status: job.status,
      id: job.id,
      imported_count: job.imported_count,
      total_count: job.total_count,
      error_messages: job.error_messages,
      job_type: job.source
    }
  end
end
