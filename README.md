# container-stacks

My personal container stacks

## Usage

The typical way to bootstrap a system for these stacks is the following:

1. Create [docker networks](#docker-networks)
1. Bring up [Portainer](portainer/compose.yaml), and use the exposed port to access it to proceed with the next steps
1. Bring up the following stacks, in this order
   1. [Docker Proxy](docker-proxy/compose.yaml)
   1. [Traefik](traefik/compose.yaml)
1. Bring up any other stacks desired

### Docker networks

The following named networks are assumed to already be created outside these stacks:

- **docker-proxy** - Used by any service that needs to communicate with the docker engine via `lscr.io/linuxserver/socket-proxy`.
- **ingress** - Used by the [traefik](traefik/compose.yaml) stack to expose services. Any exposed service must be attached to this network in order to be routed to by traefik. This network is also utilized by the [homepage](homepage/compose.yaml) stack to route to services by their service or container name.
- **observe** - Used by the [prometheus](prometheus/compose.yaml), [loki](loki/compose.yaml), and [grafana](grafana/compose.yaml) stacks to scrape or otherwise receive and display observability data. Any service that can be scraped or remote write to one of these systems must be attached to this network, as well as any service used as a datasource in Grafana.

```bash
# Example of using docker cli to create these networks
docker network create docker-proxy
docker network create ingress
docker network create observe
```

### Variables

These stacks are designed to be used with [Portainer](https://portainer.io) with supplied environment variables, or `.env` files when used with docker compose directly.
Refer to the `stack.env.example` file in each directory for the list of environment variables that are expected.

### Portainer Templates

The [templates.json](templates.json) file provides Portainer Templates that can be used to deploy these stacks, supplying the necessary values to variables.
Configure the Portainer instance to point to <https://raw.githubusercontent.com/chadweimer/container-stacks/refs/heads/main/templates.json> to use them.
