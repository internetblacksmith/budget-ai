class ApplicationController < ActionController::Base
  # Single-user mode - no authentication, no users
  # Just open the app and start using it!

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :load_active_import_job

  private

  def load_active_import_job
    @active_import_job = ImportJob.active.recent.first
  end
end
