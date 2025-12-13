# Bullet gem configuration for N+1 query detection
# Development: Warnings and alerts
# Test: Errors to catch performance regressions
# Production: Disabled

if defined?(Bullet) && Rails.env.development?
  # Development environment: Multiple warnings
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
  Bullet.skip_http_headers = false
elsif defined?(Bullet) && Rails.env.test?
  # Test environment: Raise errors on N+1 queries
  # This prevents performance regressions from being committed
  Bullet.enable = true
  Bullet.raise = true
  Bullet.bullet_logger = true
  Bullet.rails_logger = true
end
