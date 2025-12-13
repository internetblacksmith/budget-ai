# Cleanup orphaned import jobs on application startup
# This handles cases where the server was stopped while jobs were running

Rails.application.config.after_initialize do
  # Only run cleanup in non-test environments
  unless Rails.env.test?
    begin
      Rails.logger.info { "[Startup] Checking for orphaned import jobs..." }

      # Use the model's cleanup method
      count = ImportJob.cleanup_orphaned_jobs!

      if count > 0
        Rails.logger.info { "[Startup] ✅ Cleaned up #{count} orphaned import job(s)" }
      else
        Rails.logger.debug { "[Startup] No orphaned import jobs found" }
      end

    rescue => error
      # Don't let cleanup errors prevent application startup
      Rails.logger.error { "[Startup] Failed to cleanup orphaned jobs: #{error.message}" }
    end
  end
end
