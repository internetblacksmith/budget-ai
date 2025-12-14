# Background job for importing transactions from Emma Google Sheets export
class EmmaSpreadsheetImportJob < ApplicationJob
  queue_as :default

  def perform(import_job_id, spreadsheet_id, oauth_tokens = nil, sheet_name = nil)
    import_job = ImportJob.find(import_job_id)
    import_job.update!(status: "processing", started_at: Time.current)

    Rails.logger.info "[EmmaSpreadsheetImportJob] Starting import job #{import_job_id} from spreadsheet #{spreadsheet_id}"

    begin
      progress_callback = build_progress_callback(import_job)
      service = EmmaSpreadsheetImportService.new(spreadsheet_id, oauth_tokens, sheet_name, on_progress: progress_callback)
      success = service.import

      finalize_import(import_job, service, success)
    rescue StandardError => e
      handle_import_error(import_job, e)
      raise
    end
  end

  private

  def finalize_import(import_job, service, success)
    if success
      import_job.update!(
        status: service.errors.any? ? "completed_with_errors" : "completed",
        completed_at: Time.current,
        imported_count: service.imported_count,
        error_messages: service.errors
      )

      reapplied = TransactionEdit.reapply_all!
      Rails.logger.info "[EmmaSpreadsheetImportJob] Import complete: #{service.imported_count} transactions imported"
      Rails.logger.info "[EmmaSpreadsheetImportJob] #{reapplied} edits reapplied"
    else
      import_job.update!(
        status: "failed",
        completed_at: Time.current,
        error_messages: service.errors
      )

      Rails.logger.error "[EmmaSpreadsheetImportJob] Import failed: #{service.errors.join(', ')}"
    end

    # Broadcast update via Turbo Streams
    broadcast_import_status(import_job)
  end

  def handle_import_error(import_job, error)
    import_job.update!(
      status: "failed",
      completed_at: Time.current,
      error_messages: [ "#{error.class}: #{error.message}" ]
    )

    Rails.logger.error "[EmmaSpreadsheetImportJob] Fatal error: #{error.message}"
    Rails.logger.error error.backtrace.first(5).join("\n")

    broadcast_import_status(import_job)
  end

  def build_progress_callback(import_job)
    last_broadcast_at = Time.current

    proc do |imported_count, total_count|
      import_job.update_columns(imported_count: imported_count, total_count: total_count)

      now = Time.current
      if now - last_broadcast_at >= 2
        last_broadcast_at = now
        broadcast_import_status(import_job)
      end
    end
  end

  def broadcast_import_status(import_job)
    Turbo::StreamsChannel.broadcast_replace_to(
      "imports",
      target: "import_job_#{import_job.id}",
      partial: "imports/import_status",
      locals: { import_job: import_job }
    )
  end
end
