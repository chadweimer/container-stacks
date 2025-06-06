# container-stacks

My personal container stacks

## Usage

The typical way to bootstrap a system for these stacks is the following:

1. Create [docker networks](#docker-networks)
1. Create [Authelia secrets](#authelia-secrets)
1. Bring up [Portainer](portainer/compose.yaml), and use the exposed port to access it to proceed with the next steps
1. Bring up the [Proxy](proxy/compose.yaml) stack
1. Bring up any other stacks desired

### Docker networks

The following named networks are assumed to already be created outside these stacks:

- **docker-proxy** - Used by any service that needs to communicate with the docker engine via `ghcr.io/linuxserver/socket-proxy`.
- **ingress** - Used by the [traefik](traefik/compose.yaml) stack to expose services. Any exposed service must be attached to this network in order to be routed to by traefik. This network is also utilized by the [homepage](homepage/compose.yaml) stack to route to services by their service or container name.
- **observe** - Used by the [alloy](alloy/compose.yaml) and [grafana](grafana/compose.yaml) stacks to scrape or otherwise receive and display observability data. Any service that can be scraped or remote write to one of these systems must be attached to this network, as well as any service used as a datasource in Grafana.

```bash
# Example of using docker cli to create these networks
docker network create docker-proxy
docker network create ingress
docker network create observe
```

### Authelia Secrets

In this section, all file/folder paths are relative to the base authelia bind mount location.

1. Define users in `./config/users_database.yml`. E.g.,
   ```yaml
   users:
     some-username:
       disabled: false
       displayname: 'Full Name'
       password: 'password_hash'
       email: 'email@example.com'
       groups:
         - 'admins'
         - 'dev'
   ```
   - To generate password hashes, follow this [guide from Authelia](https://www.authelia.com/reference/guides/passwords/#passwords).
1. Execute the following in the `./secrets` directory below the base authelia bind mount location:
   ```bash
   openssl rand -hex 64 > JWT_SECRET
   openssl rand -hex 64 > OIDC_HMAC_SECRET
   openssl rand -hex 64 > SESSION_SECRET
   openssl rand -hex 64 > STORAGE_ENCRYPTION_KEY
   openssl genrsa -out oidc.jwks.rsa.2048.pem 2048
   ```
1. Create the `./config/oidc_clients.yml` file below the base authelia bind mount location, and populate it with the [desired OIDC client configuration](https://www.authelia.com/integration/openid-connect/introduction/).
   - To generate OIDC client IDs, follow this [guide from Authelia](https://www.authelia.com/reference/guides/generating-secure-values/#generating-a-random-alphanumeric-string), but use length 32 instead of 64 if using the openssl command due to character length restrictions.
   - To generate OIDC client secrets, follow this [guide from Authelia](https://www.authelia.com/reference/guides/generating-secure-values/#generating-a-random-password-hash).

### Variables

These stacks are designed to be used with [Portainer](https://portainer.io) with supplied environment variables, or `.env` files when used with docker compose directly.
Refer to the `example.env` file in each directory for the list of environment variables that are expected.

### Portainer Templates

The [templates.json](templates.json) file provides Portainer Templates that can be used to deploy these stacks, supplying the necessary values to variables.
Configure the Portainer instance to point to <https://raw.githubusercontent.com/chadweimer/container-stacks/refs/heads/main/templates.json> to use them.
