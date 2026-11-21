---
name: manage-stack
description: >-
  Create, modify, audit, validate, or document Docker Compose stacks in this repository,
  and update the Arcane and Portainer template registries. Use whenever adding a new stack,
  updating compose files, or verifying stack standards.
---

# Manage Stack

This skill provides step-by-step procedures and canonical templates for managing container stacks in this repository.

---

## Workflow 1: Scaffolding a New Stack

When adding a new container stack `<stack_name>`:

### Step 1: Create the Stack Directory
Create a new directory at the repository root:
```bash
mkdir -p <stack_name>
```

### Step 2: Create `compose.yaml`
Write `<stack_name>/compose.yaml` using the canonical template below:

```yaml
networks:
  public:
    external: true

services:
  <service_name>:
    container_name: <stack_name>
    environment:
      TZ: ${TZ:-America/Los_Angeles}
    image: <image_repo>/<image_name>:${IMAGE_TAG:-latest}
    labels:
      homepage.group: Other # Media, Network, Status, NAS, Other
      homepage.href: https://${HOST:-<stack_name>.${BASE_DOMAIN}}
      homepage.icon: <stack_name>.png
      homepage.name: <Service Display Name>
      traefik.enable: true
      traefik.http.routers.<stack_name>.rule: Host(`${HOST:-<stack_name>.${BASE_DOMAIN}}`)
      traefik.http.routers.<stack_name>.tls: true
      # Optional: Uncomment if non-80 internal container port
      # traefik.http.services.<stack_name>.loadbalancer.server.port: 8080
      # Optional: Uncomment if SSO protection is required
      # traefik.http.routers.<stack_name>.middlewares: 'authelia@docker'
    networks:
      - public
    pull_policy: always
    restart: unless-stopped
    user: '${PUID:-568}:${PGID:-568}'
    volumes:
      - ${DATA_DIR:-/mnt/pool0/containers}/<stack_name>:/config
```

### Step 3: Create `example.env`
Write `<stack_name>/example.env`:

```env
BASE_DOMAIN=example.com

# The following are optional and override defaults
# DATA_DIR=/mnt/pool0/containers
# PUID=568
# PGID=568
# TZ=America/Los_Angeles
# HOST=<stack_name>.example.com
# IMAGE_TAG=latest
```

*Notes on environment variables:*
* Mandatory variables go at the top (uncommented with placeholder values).
* Optional variables go under `# The following are optional and override defaults` commented out with their defaults.
* Never include `# TLS_CERT_DOMAIN` or `# TLS_CERT_SANS` unless the stack requires nested subdomains beyond `*.${BASE_DOMAIN}` (e.g. `wineandcats` with `*.${STAGE}.${BASE_DOMAIN}`). In standard single-level subdomains, the wildcard certificate on Traefik entrypoint covers them automatically.

### Step 4: Create `template.json`
Write `<stack_name>/template.json`:

```json
{
  "name": "<Human Readable Stack Title>",
  "description": "<Clear 1-2 sentence description of what the stack does.>",
  "version": "1.0.0",
  "tags": [
    "app"
  ]
}
```

*Tags:* Use `"app"` or `"infra"`.

### Step 5: Create `README.md`
Write `<stack_name>/README.md`:

```markdown
# <Stack Title>

<Short overview of the application and its purpose.>

## Initial Setup

1. Copy `example.env` to `.env` and set `BASE_DOMAIN`.
2. Configure any required secrets or parameters.
3. Deploy the stack. Access at `https://<stack_name>.${BASE_DOMAIN}`.
```

---

## Workflow 2: Validating & Updating Registries

Whenever a stack is created, updated, or removed:

### Step 1: Validate Compose Configuration
Run `docker compose config` with `example.env`:
```bash
docker compose -f <stack_name>/compose.yaml --env-file <stack_name>/example.env config -q
```
Ensure exit code is `0` with no syntax or variable interpolation errors.

### Step 2: Regenerate Registries
Execute the registry generator from the repository root:
```bash
./update-registry.sh
```
The script will:
* Detect new, removed, or modified templates.
* Bump registry semver (`minor` for new stacks, `major` for removals, `patch` for modifications).
* Update `registry.json` and `templates.json`.

### Step 3: Verify JSON Output
```bash
jq empty registry.json && jq empty templates.json
```

---

## Workflow 3: Auditing Stack Standards

Run these checks to ensure any stack complies with repository conventions:

1. **Check for Hardcoded Host Paths**:
   ```bash
   git grep -n "/mnt/pool" <stack_name>/compose.yaml | grep -vE "DATA_DIR|MEDIA_DIR|BACKUP_DIR"
   ```
   *(Must return empty).*

2. **Check for Redundant Traefik TLS Labels**:
   ```bash
   git grep -n "tls.certresolver" <stack_name>/compose.yaml
   ```
   *(Must return empty unless inspecting `proxy/compose.yaml`).*

3. **Check for Obsolete TLS Env Comments**:
   ```bash
   git grep -n "TLS_CERT_" <stack_name>/example.env
   ```
   *(Must return empty unless inspecting `proxy/example.env`).*

4. **Check for Documentation URL Validity**:
   Ensure `<stack_name>/README.md` exists so downstream Arcane links do not 404.
