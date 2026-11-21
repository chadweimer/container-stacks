# Scrutiny

Hard Drive S.M.A.R.T monitoring, failure prediction, and web dashboard with InfluxDB backend.

## Initial Setup

1. Ensure the collector container has access to host block devices (`/dev`) and required capabilities (`SYS_ADMIN`, `SYS_RAWIO`).
2. Configure `GOTIFY_TOKEN` to receive disk health alerts via Gotify.
3. Access the dashboard at `https://scrutiny.${BASE_DOMAIN}`.
