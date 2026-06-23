# RomM

## Initial Setup

### Authelia

Follow the guide at <https://www.authelia.com/integration/openid-connect/clients/romm/>.

> [!NOTE]
> This stack includes a workaround for an issue that causes the OIDC integration to fail to resolve the Authelia domain when IPv6 is not supported by the DNS resolver.
> This is accomplished through an explicit entry in the `extra_hosts` array of the stack.
