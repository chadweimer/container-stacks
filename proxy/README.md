# proxy

## Initial Setup

### Secrets

#### traefik

Execute the following in the `./secrets` directory of the traefik mount, replacing values with those acquired from Cloudflare and the ACME provider:
```bash
echo 'the-kid' > ACME_EAB_KID
echo 'the-hmac' > ACME_EAB_HMAC
echo 'the-token' > CF_DNS_API_TOKEN
```

#### lldap

Execute the following in the `./secrets` directory of the lldap config mount, replacing `admin-user-password` with the desired password:
```bash
echo $(LC_ALL=C tr -dc 'A-Za-z0-9!#%&'\''()*+,-./:;<=>?@[\]^_{|}~' </dev/urandom | head -c 32) > LLDAP_JWT_SECRET
echo $(LC_ALL=C tr -dc 'A-Za-z0-9!#%&'\''()*+,-./:;<=>?@[\]^_{|}~' </dev/urandom | head -c 32) > LLDAP_KEY_SEED
echo 'admin-user-password' > LLDAP_LDAP_USER_PASS
```

#### Authelia

Execute the following in the `./secrets` directory of the authelia config mount, replacing `bind-user-password` with the desired password:
```bash
openssl rand -hex 64 > JWT_SECRET
openssl rand -hex 64 > OIDC_HMAC_SECRET
openssl rand -hex 64 > SESSION_SECRET
openssl rand -hex 64 > STORAGE_ENCRYPTION_KEY
openssl genrsa -out oidc.jwks.rsa.2048.pem 2048
echo 'bind-user-password' > LDAP_PASSWORD
```

### Configuration

#### Authelia

Create the `./config/oidc_clients.yml` file in the authelia config mount, and populate it with the [desired OIDC client configuration](https://www.authelia.com/integration/openid-connect/introduction/).
- To generate OIDC client IDs, follow this [guide from Authelia](https://www.authelia.com/reference/guides/generating-secure-values/#generating-a-random-alphanumeric-string), but use length 32 instead of 64 if using the openssl command due to character length restrictions.
- To generate OIDC client secrets, follow this [guide from Authelia](https://www.authelia.com/reference/guides/generating-secure-values/#generating-a-random-password-hash).

## Post Bring-up

### lldap

1. Define a user named "authelia" with the same password as used for the `LDAP_PASSWORD` secret
1. If necessary, define a user named "portainer" and log into Portainer to generate an API Key for usage as the Homepage key
1. Define any desired users to use to log in to other services
