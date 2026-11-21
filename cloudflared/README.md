# Cloudflared

Runs the Cloudflare Tunnel daemon to expose internal services securely via Cloudflare without opening router inbound ports.

## Initial Setup

1. Create a tunnel in the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/).
2. Copy your tunnel token into `TUNNEL_TOKEN` in `.env`.
3. Deploy the stack.
