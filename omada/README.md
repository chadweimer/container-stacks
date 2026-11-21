# Omada Controller

TP-Link Omada Software Controller for managing Omada access points, switches, and routers, along with a Prometheus metrics exporter.

## Initial Setup

1. Configure `OMADA_USER` and `OMADA_PASS` in `.env`.
2. Deploy the stack with `network_mode: host` to allow discovery of local network devices.
3. Access the controller web interface at port `8043` or via `https://omada.${BASE_DOMAIN}`.
