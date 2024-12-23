# container-stacks

My personal container stacks

## Usage

### Variables

These stacks are designed to be used with [Portainer](https://portainer.io) with supplied environment variables, or `.env` files when used with docker compose directly.
Refer to the `stack.env.example` file in each directory for the list of environment variables that are expected.

### Docker networks

Most of these stacks expect a docker network named 'traefik' to already exist.
This network is leverages by the eponymous container to manage reverse proxy configuration for each application that is meant to be exposed outside docker.
