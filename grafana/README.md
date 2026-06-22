# Grafana

## Post Bring-up

### Homepage

1. Create a new user with the "Viewer" role only
2. Set the `USERNAME` and `PASSWORD` environment variables to that of the user created in step 1
3. Re-deploy the stack

### Authelia

Follow the guide at <https://www.authelia.com/integration/openid-connect/clients/grafana/>.

> [!TIP]
> Contrary to the documentation, you can configure to Grafana side through the web interface under  `Administration > Authentication > Generic OAuth`.
