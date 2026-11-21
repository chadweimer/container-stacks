# Gotify

A simple, self-hosted server for sending and receiving push notifications via REST API and WebSockets.

## Initial Setup

1. Copy `example.env` to `.env` and set `BASE_DOMAIN`.
2. Access the Gotify web UI at `https://gotify.${BASE_DOMAIN}` to set up your admin user and application tokens.
3. Supply `GOTIFY_CLIENT_TOKEN` for the Homepage dashboard widget.
