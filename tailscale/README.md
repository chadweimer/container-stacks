# Tailscale

Tailscale mesh VPN client running in host network mode to securely connect your Docker host to your Tailscale tailnet.

## Initial Setup

1. Generate an auth key from the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).
2. Set `TS_AUTHKEY` in `.env`.
3. Deploy the stack.
