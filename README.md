# Weaviate on Railway

One-click [Weaviate](https://weaviate.io) vector database for Railway, built from the official image `semitechnologies/weaviate:1.40.5` (pinned by digest in the [`Dockerfile`](Dockerfile)).

## What it deploys

One service, **Weaviate**, built from this repo:

- REST and GraphQL API on the service's public Railway domain (port `8080`).
- gRPC API on port `50051`, reachable from your other Railway services over the private network: `${{Weaviate.RAILWAY_PRIVATE_DOMAIN}}:50051`.
- A volume at `/var/lib/weaviate` holding collections, the schema and filesystem backups (`/var/lib/weaviate/backups`).
- An API key, generated at deploy time. Anonymous access is off, so every request except the health endpoints needs `Authorization: Bearer <key>`. The key belongs to the user `admin`, the RBAC root user. The container refuses to start without a key.
- Health check on `/v1/.well-known/ready`.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `AUTHENTICATION_APIKEY_ALLOWED_KEYS` | `${{secret(48,"…")}}` (letters and digits) | API key for the REST, GraphQL and gRPC APIs |
| `PORT` | `8080` | HTTP port; the public domain and the health check point here |

Fixed defaults, set in [`railway-start.sh`](railway-start.sh) and each overridable with a service variable of the same name:

| Variable | Default |
|---|---|
| `PERSISTENCE_DATA_PATH` | `/var/lib/weaviate` |
| `CLUSTER_HOSTNAME` | `node1` (a fixed node name, so the schema survives redeploys) |
| `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED` | `false` |
| `AUTHENTICATION_APIKEY_USERS` | `admin` |
| `AUTHORIZATION_RBAC_ENABLED` / `AUTHORIZATION_RBAC_ROOT_USERS` | `true` / `admin` |
| `ENABLE_API_BASED_MODULES` | `true` (OpenAI, Cohere, Anthropic, Google, Voyage AI and other API vectorizers and generators) |
| `ENABLE_MODULES` | `backup-filesystem` |
| `BACKUP_FILESYSTEM_PATH` | `/var/lib/weaviate/backups` |
| `LIMIT_RESOURCES` | `true` (sets Go's memory limit to 80% of the container's) |
| `QUERY_DEFAULTS_LIMIT` | `25` |

Any other [Weaviate environment variable](https://docs.weaviate.io/deploy/configuration/env-vars) can be added too, for example `DISABLE_TELEMETRY=true`.

## Connect from another Railway service

```
WEAVIATE_HTTP_HOST=${{Weaviate.RAILWAY_PRIVATE_DOMAIN}}
WEAVIATE_HTTP_PORT=8080
WEAVIATE_GRPC_PORT=50051
WEAVIATE_API_KEY=${{Weaviate.AUTHENTICATION_APIKEY_ALLOWED_KEYS}}
```

Python (v4 client):

```python
import os, weaviate
from weaviate.classes.init import Auth

client = weaviate.connect_to_custom(
    http_host=os.environ["WEAVIATE_HTTP_HOST"], http_port=8080, http_secure=False,
    grpc_host=os.environ["WEAVIATE_HTTP_HOST"], grpc_port=50051, grpc_secure=False,
    auth_credentials=Auth.api_key(os.environ["WEAVIATE_API_KEY"]),
)
```

From outside Railway, the REST and GraphQL API is at `https://<your domain>` (port 443) with the same key. The gRPC port isn't public; the v4 Python and v3 TypeScript clients need it for queries, so run them inside Railway, or add a TCP proxy for port 50051 in the service's settings (plain gRPC, not TLS).

## Updates

This template builds from this repo. When the pinned Weaviate version changes on `main`, Railway shows deployers an "update available" notice, and they choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) before you apply an update, and take a backup first (`POST /v1/backups/filesystem`). Weaviate supports upgrading one minor version at a time.

## Local run

```sh
docker build -t weaviate-railway .
docker run -p 8080:8080 -e AUTHENTICATION_APIKEY_ALLOWED_KEYS=change-me -v weaviate-data:/var/lib/weaviate weaviate-railway
curl -H "Authorization: Bearer change-me" localhost:8080/v1/meta
```
