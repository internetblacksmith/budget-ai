source "https://rubygems.org"

gem "rails", "8.1.2"
gem "propshaft", "1.3.1"
gem "sqlite3", "2.9.0"
gem "puma", "7.2.0"
gem "importmap-rails", "2.2.3"
gem "turbo-rails", "2.0.21"
gem "stimulus-rails", "1.3.4"

# CSV parsing for transaction imports
gem "csv", "3.3.5"

# Google Drive integration for Emma spreadsheet import
gem "google-apis-drive_v3", "0.77.0"
gem "google-apis-sheets_v4", "0.46.0"
gem "googleauth", "1.16.2"
gem "signet", "0.21.0"

# MCP (Model Context Protocol) server for AI agent tool access
gem "mcp", "0.7.0"

# HTTP client for LLM integration
gem "faraday", "2.14.1"
gem "faraday-retry", "2.4.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache", "1.0.10"
gem "solid_queue", "1.3.1"
gem "solid_cable", "3.0.12"

# Pagination for transaction lists and large result sets
gem "kaminari", "1.2.2"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", "1.21.1", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", "1.11.1", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "7.1.2", require: false

  # N+1 query detector [https://github.com/flyerhzm/bullet]
  gem "bullet", "8.1.0", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", "1.1.0", require: false

  # RSpec for testing
  gem "rspec-rails", "8.0.3"
  gem "factory_bot_rails", "6.5.1"

  # Load environment variables from .env files
  gem "dotenv-rails", "3.2.0"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console", "4.2.1"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara", "3.40.0"
  gem "selenium-webdriver", "4.41.0"

  # Code coverage
  gem "simplecov", "0.22.0", require: false
  gem "simplecov-html", "0.13.2", require: false

  # Testing matchers
  gem "shoulda-matchers", "7.0.1"

  # Cucumber for BDD integration testing
  gem "cucumber-rails", "4.0.0", require: false
  gem "database_cleaner-active_record", "2.2.2"

  # Code quality
  gem "reek", "6.5.0"
  gem "debride", "1.15.0"

  # HTTP mocking for tests
  gem "webmock", "3.26.1"

  # Session manipulation for testing OAuth flows
  gem "rack_session_access", "0.2.0"
end
