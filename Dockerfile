# Headscale — self-hosted Tailscale control server
#
# Stage 1: official distroless image (ko-built static binary at /ko-app/headscale).
# The official image has no shell and no bundled config, so Stage 2 layers the
# binary onto Alpine with a runtime wrapper that renders /etc/headscale/config.yaml
# from Railway-injected env vars ($PORT, $RAILWAY_PUBLIC_DOMAIN).
FROM headscale/headscale:v0.29.3 AS upstream

FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

COPY --from=upstream /ko-app/headscale /usr/local/bin/headscale

# Runtime wrapper: renders config.yaml from env, ensures the data dir exists,
# then starts the control server.
COPY start.sh /usr/local/bin/headscale-start.sh
RUN chmod +x /usr/local/bin/headscale-start.sh

ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${PORT}/health" || exit 1

CMD ["/usr/local/bin/headscale-start.sh"]
