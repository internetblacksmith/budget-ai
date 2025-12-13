# Configure SSL certificate handling for HTTPS connections
# This helps with certificate verification issues in development environments

# Look for system CA certificates and configure OpenSSL to use them
cert_locations = [
  "/etc/ssl/certs/ca-certificates.crt",        # Debian/Ubuntu/Gentoo
  "/etc/pki/tls/certs/ca-bundle.crt",          # Fedora/RHEL 6
  "/etc/ssl/ca-bundle.pem",                    # OpenSUSE
  "/etc/ssl/cert.pem",                         # OpenBSD
  "/usr/local/share/certs/ca-root-nss.crt",    # FreeBSD
  "/etc/pki/tls/cert.pem"                     # Old CentOS/RHEL
].freeze

ca_file = ENV["SSL_CERT_FILE"] || cert_locations.find { |path| File.exist?(path) }

if ca_file
  ENV["SSL_CERT_FILE"] ||= ca_file
  Rails.logger.debug { "[SSL] Using CA certificates from: #{ca_file}" }
end

# In development, allow bypassing SSL verification if needed
if !Rails.env.production? && ENV["SKIP_SSL_VERIFY"].present?
  Rails.logger.warn { "[SSL] SSL verification disabled - FOR DEVELOPMENT ONLY!" }
end
