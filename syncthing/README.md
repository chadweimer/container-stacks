# Syncthing

Continuous, encrypted peer-to-peer file synchronization across multiple devices.

## Initial Setup

1. Copy `example.env` to `.env` and set `BASE_DOMAIN`.
2. Access the Syncthing web interface at `https://syncthing.${BASE_DOMAIN}` (protected behind Authelia).
3. Pair with your other Syncthing nodes and configure folder shares.
