# *Arrs

A complete media automation stack integrating:
- **Bazarr**: Subtitle management
- **Cleanuparr**: Media cleanup automation
- **Maintainerr**: Media library maintenance and rules engine
- **Prowlarr**: Indexer management for Usenet and BitTorrent
- **Radarr**: Movie collection manager
- **Jellyseerr**: Media discovery and request management
- **Sonarr**: TV series collection manager
- **Tdarr**: Distributed audio/video transcoding automation
- **Transmission + Gluetun**: BitTorrent client routed securely through a VPN container

## Initial Setup

1. Copy `example.env` to `.env` and configure:
   - `BASE_DOMAIN`: Base domain for Traefik routing.
   - `RADARR_API_KEY`, `SONARR_API_KEY`: API keys from your Arr instances.
   - `VPN_SERVICE_PROVIDER`, `WIREGUARD_PRIVATE_KEY` (or OpenVPN credentials) for Gluetun.
2. Ensure both `${DATA_DIR:-/mnt/pool0/containers}` and `${MEDIA_DIR:-/mnt/pool1/media}` are properly mounted.
