#!/bin/sh
set -e

# Railway runtime wrapper for Headscale:
# 1. Render /etc/headscale/config.yaml from Railway-injected env vars.
# 2. Ensure the data dir (/var/lib/headscale) exists and is writable.
# 3. Start the control server.
#
# The base image ships no config file; headscale refuses to start without one.
# Railway injects PORT (listener port the proxy routes to) and
# RAILWAY_PUBLIC_DOMAIN (the generated *.up.railway.app hostname). Clients
# connect to https://RAILWAY_PUBLIC_DOMAIN; Railway terminates TLS and proxies
# to $PORT, so the embedded server itself stays plain HTTP.

PORT="${PORT:-8080}"
PUBLIC_DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-}"
BASE_DOMAIN="${HEADSCALE_BASE_DOMAIN:-example.com}"

if [ -n "$PUBLIC_DOMAIN" ]; then
  SERVER_URL="https://${PUBLIC_DOMAIN}"
else
  SERVER_URL="http://localhost:${PORT}"
fi

mkdir -p /etc/headscale /var/lib/headscale

cat > /etc/headscale/config.yaml <<EOF
# Generated at container start by headscale-start.sh
server_url: ${SERVER_URL}
listen_addr: 0.0.0.0:${PORT}
metrics_listen_addr: 127.0.0.1:9090

noise:
  private_key_path: /var/lib/headscale/noise_private.key

prefixes:
  v4: 100.64.0.0/10
  v6: fd7a:115c:a1e0::/48

derp:
  server:
    enabled: false
  # Tailscale's public DERP relays. Railway has no UDP egress for an embedded
  # DERP server, so nodes relay through Tailscale's infrastructure.
  urls:
    - https://controlplane.tailscale.com/derpmap/default
  paths: []
  auto_update_enabled: true
  update_frequency: 3h

database:
  type: sqlite
  sqlite:
    path: /var/lib/headscale/db.sqlite

dns:
  magic_dns: true
  base_domain: ${BASE_DOMAIN}
  override_local_dns: true
  nameservers:
    global:
      - 1.1.1.1
      - 1.0.0.1
      - 2606:4700:4700::1111
      - 2606:4700:4700::1001
  search_domains: []
  extra_records: []

log:
  level: info
  format: text
EOF

echo "=== /etc/headscale/config.yaml ==="
cat /etc/headscale/config.yaml

exec headscale serve
