# SSL Certificate Troubleshooting Guide

If you get SSL certificate errors when connecting to Google APIs:

```
SSL_connect returned=1 errno=0 state=error: certificate verify failed
```

## Solution 1: Auto-Detection (Recommended)

The app automatically looks for system certificates in common locations:

```
/etc/ssl/certs/ca-certificates.crt       # Ubuntu/Debian
/etc/pki/tls/certs/ca-bundle.crt         # Fedora/RHEL
/etc/ssl/ca-bundle.pem                   # OpenSUSE
/etc/ssl/cert.pem                        # OpenBSD
```

Just restart Rails and it should pick them up.

## Solution 2: Manual Certificate File

```bash
# Download CA certificates
curl https://curl.se/ca/cacert.pem -o ~/cacert.pem

# Set in .env.local
SSL_CERT_FILE=~/cacert.pem
```

## Solution 3: Development Bypass

In `.env.local`:
```
SKIP_SSL_VERIFY=1
```

**Warning:** Only use in development.

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `SSL_CERT_FILE` | Path to CA certificate file | `/etc/ssl/certs/ca-certificates.crt` |
| `SSL_CERT_DIR` | Directory with CA certificates | `/etc/ssl/certs/` |
| `SKIP_SSL_VERIFY` | Bypass SSL verification (dev only) | `1` |

## Platform-Specific

- **Ubuntu/Debian**: `sudo apt-get install ca-certificates`
- **CentOS/RHEL**: `sudo yum install ca-certificates`
- **macOS**: `brew install ca-certificates`
