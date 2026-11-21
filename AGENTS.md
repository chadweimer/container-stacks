# Agent Guidelines: `container-stacks`

This document defines the architectural principles, configuration standards, and operational guidelines for AI agents working within the `container-stacks` repository.

---

## 1. Overview & Repository Purpose

This repository serves two primary roles:
1. **Personal Homelab Infrastructure**: Production Docker Compose stacks running services (media, observability, smart home, file management, ingress) on a local host (e.g. TrueNAS SCALE).
2. **Public Application Template Registry**: Generates [registry.json](file:///home/cwmr/repos/container-stacks/registry.json) for [Arcane](https://getarcane.app/) and [templates.json](file:///home/cwmr/repos/container-stacks/templates.json) for [Portainer](https://www.portainer.io/).

Any stack created or modified in this repository must function cleanly for personal deployments while remaining portable and self-contained for downstream template consumers.

---

## 2. Ingress & TLS Conventions

### Centralized Traefik Ingress
Traefik is configured in `proxy/compose.yaml`. ACME DNS-01 challenges and wildcard certificate generation (`*.${BASE_DOMAIN}`) are handled centrally on Traefik's `websecure` (port 443) entrypoint.

* **Router Configuration**:
  Standard web services exposed at single-level subdomains (`<service>.${BASE_DOMAIN}`) only require:
  ```yaml
  traefik.enable: true
  traefik.http.routers.<service>.rule: Host(`${HOST:-<service>.${BASE_DOMAIN}}`)
  traefik.http.routers.<service>.tls: true
  ```
* **Nested Subdomain Exception**:
  Wildcard certificates (`*.${BASE_DOMAIN}`) only cover one level of subdomain. If a stack requires multi-level nested subdomains (for example, `wineandcats` with `db.${STAGE}.${BASE_DOMAIN}` and `${STAGE}.${BASE_DOMAIN}`), define router-level domain SAN overrides and include optional `# TLS_CERT_DOMAIN` / `# TLS_CERT_SANS` in `example.env`:
  ```yaml
  traefik.http.routers.<service>.tls.domains[0].main: ${TLS_CERT_DOMAIN:-${STAGE}.${BASE_DOMAIN}}
  traefik.http.routers.<service>.tls.domains[0].sans: ${TLS_CERT_SANS:-*.${STAGE}.${BASE_DOMAIN}}
  ```
* **General Prohibitions**:
  * **Do NOT** duplicate `traefik.http.routers.<service>.tls.certresolver` on individual services (entrypoint default `myresolver` handles this).
  * **Do NOT** add `# TLS_CERT_DOMAIN` or `# TLS_CERT_SANS` to single-level subdomain stacks where the global wildcard certificate applies.

### Host & Domain Variable Conventions
* **`BASE_DOMAIN`**: Required in all stacks exposing web services (e.g., `BASE_DOMAIN=example.com`).
* **`HOST`**: Optional override variable. In `example.env`, list it commented out under `# The following are optional and override defaults` (e.g., `# HOST=jellyfin.example.com`).
* **Multi-Service Stacks**: If a stack contains multiple web services (e.g., `arrs`, `ollama`), prefix the host variable with the service name:
  * `traefik.http.routers.radarr.rule: Host(`${RADARR_HOST:-radarr.${BASE_DOMAIN}}`)`
  * `traefik.http.routers.sonarr.rule: Host(`${SONARR_HOST:-sonarr.${BASE_DOMAIN}}`)`
* **Internal URLs & Dashboards**: Container environment variables defining public URLs (such as `APP_URL`, `PublishedServerUrl`) and Homepage dashboard links (`homepage.href`) must use the same Host pattern:
  ```yaml
  homepage.href: https://${HOST:-<service>.${BASE_DOMAIN}}
  ```

### Authentication (Authelia Forward Auth)
* Services protected by centralized SSO must include:
  ```yaml
  traefik.http.routers.<service>.middlewares: 'authelia@docker'
  ```
* Services with native authentication, internal OIDC support (e.g. Homebox, Vikunja), or public utility tools omit this middleware.

### Backend Ports & Internal Schemes
* **Non-Standard Ports**: If the container does not listen on standard HTTP port 80, explicitly define the load balancer port:
  ```yaml
  traefik.http.services.<service>.loadbalancer.server.port: <port>
  ```
* **Internal HTTPS**: If the backend container expects HTTPS traffic directly (e.g. Omada port 8043, Frigate port 8971), declare:
  ```yaml
  traefik.http.services.<service>.loadbalancer.server.scheme: https
  ```
  *(Traefik has `--serverstransport.insecureskipverify=true` globally enabled to trust internal self-signed container certs).*

---

## 3. Docker Networks

Pre-existing external networks are defined in `networks.yaml`:
* **`public`**: Attached to Traefik and any service that needs to be exposed via reverse proxy or accessed by Homepage.
* **`docker-proxy`**: Used by services (like Traefik, Homepage, Alloy) that need to query the Docker engine via the socket proxy (`ghcr.io/linuxserver/socket-proxy`).
* **`observe`**: Dedicated bridge network for metric scraping and log aggregation by Grafana Alloy, Loki, and Prometheus. Any service declaring `prometheus.port` must be connected to `observe`.

In `compose.yaml`, reference external networks using modern Compose syntax:
```yaml
networks:
  public:
    external: true
```

---

## 4. Environment & Storage Portability

Never hardcode host-specific paths or environment identities. Always use parameterized environment variables with sensible defaults:

| Variable | Default Fallback | Usage |
| :--- | :--- | :--- |
| `DATA_DIR` | `/mnt/pool0/containers` | Base directory for persistent container configs and application databases. |
| `MEDIA_DIR` | `/mnt/pool1/media` | Base directory for media libraries, downloads, and storage pools. |
| `BACKUP_DIR` | `/mnt/pool0/backups` | Base directory for container/database backup archives. |
| `PUID` | `568` | User ID for container permissions (TrueNAS `apps` user). *Syncthing defaults to `1000`.* |
| `PGID` | `568` | Group ID for container permissions (TrueNAS `apps` group). *Syncthing defaults to `1000`.* |
| `TZ` | `America/Los_Angeles` | Timezone across containers. |
| `PROMETHEUS_INSTANCE` | `truenas-server` | Prometheus metric instance label (`prometheus.label.instance`). |

* In `compose.yaml`:
  * Volumes: `- ${DATA_DIR:-/mnt/pool0/containers}/<service>:/config`
  * User: `user: '${PUID:-568}:${PGID:-568}'` (or `PUID: ${PUID:-568}`, `PGID: ${PGID:-568}`)
  * Timezone: `TZ: ${TZ:-America/Los_Angeles}`
* In `example.env`:
  * Include any variables used by the stack under `# The following are optional and override defaults` commented out with their defaults.

---

## 5. Stack Directory Standards (The 4-File Requirement)

Every stack directory `<stack_name>/` must contain exactly four files:

1. **`compose.yaml`**:
   * Service definitions using standard Compose v2 syntax.
   * `container_name: <name>` for predictable DNS and container naming.
   * `pull_policy: always` and `restart: unless-stopped`.
2. **`example.env`**:
   * Required variables at the top without comments (e.g. `BASE_DOMAIN=example.com`, `API_KEY=key`).
   * Optional variables commented out under `# The following are optional and override defaults`.
   * Never store real passwords or tokens in `example.env`.
3. **`template.json`**:
   * Metadata used by `./update-registry.sh` to generate Arcane and Portainer templates:
     ```json
     {
       "name": "Service Name",
       "description": "Short description of the stack.",
       "version": "1.0.0",
       "tags": [
         "app"
       ]
     }
     ```
4. **`README.md`**:
   * Setup instructions, prerequisites, default ports, and links to upstream documentation. Ensures `documentation_url` in `registry.json` is never a dead link.

---

## 6. Verification & Registry Workflow

When creating, updating, or modifying any stack:
1. **Validate Compose Syntax**:
   ```bash
   docker compose -f <stack>/compose.yaml --env-file <stack>/example.env config -q
   ```
2. **Update Template Registries**:
   Execute the registry generator to compile `registry.json` and `templates.json`:
   ```bash
   ./update-registry.sh
   ```
3. **Validate Registries**:
   Verify that `registry.json` and `templates.json` are valid JSON:
   ```bash
   jq empty registry.json && jq empty templates.json
   ```

---

## 7. Safety & Git Commit Policy

* **Do NOT commit automatically**: Never execute `git commit` or `git push` unless the user explicitly asks you to commit.
* **Keep local `.env` intact**: If editing files, never overwrite or leak user secrets from local uncommitted `.env` files into git-tracked files.
