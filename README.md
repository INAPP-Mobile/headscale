# Headscale

An open source, self-hosted implementation of the Tailscale control server — deploy your own private WireGuard mesh VPN on Railway in one click.

[![Deploy to Railway](https://railway.app/button.svg)](https://railway.com/deploy/headscale-1)

## Why Deploy

Headscale lets you run your own Tailscale control plane: no third-party coordination server, full control over your tailnet. This template runs the official Headscale server on a single Railway service with one persistent volume. Railway terminates TLS automatically, so clients connect to a proper `https://` endpoint with zero certificate configuration.

## Features

- Self-hosted Tailscale control server (WireGuard mesh VPN)
- Automatic HTTPS via Railway — no TLS cert management
- Persistent node database and Noise keys on a Railway volume
- MagicDNS + built-in DNS configuration pushed to clients
- Works with the standard Tailscale client on every platform
- No external database — SQLite, zero extra services

## Configuration

| Variable | Description | Default |
|---|---|---|
| `PORT` | HTTP port Railway routes to (auto-injected) | `8080` |
| `HEADSCALE_BASE_DOMAIN` | MagicDNS base domain — must differ from your server domain | `example.com` |

`RAILWAY_PUBLIC_DOMAIN` is injected automatically by Railway and becomes the `server_url` your clients connect to.

## Volumes

- `/var/lib/headscale` — Persistent state: SQLite database, Noise private key, node registrations

## License

BSD-3-Clause — [Headscale on GitHub](https://github.com/juanfont/headscale)

## Deploy and Host

Click the Deploy to Railway button above. Railway builds the image, provisions the `/var/lib/headscale` volume, and exposes your instance at `https://<project>-production-xxxx.up.railway.app`. No configuration needed to start.

## About Hosting

This template runs the official Headscale container (v0.29.3) on Railway. A lightweight entrypoint renders `config.yaml` from Railway's injected environment (`PORT`, `RAILWAY_PUBLIC_DOMAIN`) at container start. DERP relays use Tailscale's public infrastructure since Railway does not expose UDP. All state lives on a persistent volume, so nodes stay registered across restarts and redeploys.

## Common Use Cases

- Private tailnet for your homelab, phones, and laptops — no Tailscale account required
- Access your Railway services over a private encrypted mesh
- Centralized DNS (MagicDNS) for all your devices
- Full control over node authentication and ACL policies

## Dependencies for

- Tailscale client (free) installed on each device you want in your tailnet
- A Railway account — no external services, databases, or accounts required

### Deployment Dependencies

- Railway injects `PORT` and `RAILWAY_PUBLIC_DOMAIN` automatically
- One persistent volume (`/var/lib/headscale`) for the SQLite database and Noise keys
- DERP relays use Tailscale's public infrastructure (Railway has no UDP egress)

## Quickstart

After deploying, install the Tailscale client and connect:

```sh
tailscale up --login-server https://<your-railway-domain> --hostname my-device
```

Then approve the node from the server (via `railway run` or the web shell):

```sh
headscale users create default
headscale nodes list
headscale nodes register --user default --key <node-key>
```

Your tailnet is ready — `tailscale ping <other-device>` across the mesh.
