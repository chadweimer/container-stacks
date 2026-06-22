# Arcane

## Initial Setup

### Secrets

Per the [Arcane documentation](https://getarcane.app/docs/setup/installation#docker-compose-recommended), you can generate the values for the `ENCRYPTION_KEY` and `JWT_SECRET` via `openssl rand -hex 32`.

## Post Bring-up

### Authelia

Follow the guide at <https://www.authelia.com/integration/openid-connect/clients/arcane/>, specifically following the "Web GUI" section for the Arcane configuration.
