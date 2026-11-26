# Termix

Self-hosted, plugin-based web server and SSH management platform with terminal access, file management, tunneling, and remote desktop support.

Upstream documentation: <https://termix.site/install/server/docker>

## Initial Setup

1. Copy `example.env` to `.env` and set `BASE_DOMAIN` (optionally set `IMAGE_TAG` to `latest-minimal` or `latest-full` to choose a different bundled plugin set).
2. Deploy the stack.
3. Access Termix at `https://termix.${BASE_DOMAIN}` to create the initial administrator account.

## Post Bring-up

### Single Sign-On (OIDC)

Termix includes native OpenID Connect (OIDC) support via its bundled SSO plugin (`Plugins` -> `SSO`, then `Settings` -> `Single Sign-On`) using callback URI `https://termix.${BASE_DOMAIN}/plugin-api/sso/callback`.
