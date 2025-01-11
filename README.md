# container-stacks

My personal container stacks

## Usage

### Variables

These stacks are designed to be used with [Portainer](https://portainer.io) with supplied environment variables, or `.env` files when used with docker compose directly.
Refer to the `stack.env.example` file in each directory for the list of environment variables that are expected.

### Docker networks

The following named networks are assumed to already be created outside these stacks:

- **ingress** - Used by the [traefik](traefik/compose.yaml) stack to expose services. Any exposed service must be attached to this network in order to be routed to by traefik. This network is also utilized by the [homepage](homepage/compose.yaml) stack to route to services by their service or container name.
- **observe** - Used by the [prometheus](prometheus/compose.yaml), [loki](loki/compose.yaml), and [grafana](grafana/compose.yaml) stacks to scrape or otherwise receive and display observability data. Any service that can be scraped or remote write to one of these systems must be attached to this network, as well as any service used as a datasource in Grafana.

```bash
# Example of using docker cli to create these networks
docker network create ingress
docker network create observe
```

### Portainer Templates

The [templates.json](templates.json) file provides Portainer Templates that can be used to deploy these stacks, supplying the necessary values to variables.
Configure the Portainer instance to point to <https://raw.githubusercontent.com/chadweimer/container-stacks/refs/heads/main/templates.json> to use them.
