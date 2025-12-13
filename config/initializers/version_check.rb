# Version check initializer
# This checks for updates on startup in development/production

if Rails.env.development? || Rails.env.production?
  Rails.application.config.after_initialize do
    begin
      current_version = File.read(Rails.root.join("VERSION")).strip rescue "0.0.0"

      # Log current version
      Rails.logger.info "Budget AI Version: #{current_version}"

      # Store version in config for display
      Rails.application.config.app_version = current_version

      # Check for updates (only in development for now)
      if Rails.env.development? && File.exist?(Rails.root.join(".update/update-info.json"))
        update_info = JSON.parse(File.read(Rails.root.join(".update/update-info.json")))
        latest = update_info["latest_version"]

        if Gem::Version.new(latest) > Gem::Version.new(current_version)
          Rails.logger.warn "=" * 50
          Rails.logger.warn "Update available: v#{latest} (current: v#{current_version})"
          Rails.logger.warn "Run 'easy-update.bat' to update"
          Rails.logger.warn "=" * 50
        end
      end
    rescue => e
      Rails.logger.error "Version check failed: #{e.message}"
    end
  end
end
