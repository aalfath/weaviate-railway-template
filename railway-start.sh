#!/bin/sh
# Railway wrapper for the official Weaviate binary.
# Every default below can be overridden with a service variable of the same name.
set -eu

# Refuse to start without an API key: a Weaviate on a public domain with no key is open to anyone.
if [ -z "${AUTHENTICATION_APIKEY_ALLOWED_KEYS:-}" ] && [ "${AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED:-false}" != "true" ]; then
  echo "AUTHENTICATION_APIKEY_ALLOWED_KEYS is empty. Set it (the template generates one)." >&2
  exit 1
fi

# Storage on the Railway volume.
export PERSISTENCE_DATA_PATH="${PERSISTENCE_DATA_PATH:-/var/lib/weaviate}"
# A fixed node name: Railway gives every deploy a new container hostname, and Weaviate's
# Raft schema store is keyed on the node name, so a changing name loses the schema.
export CLUSTER_HOSTNAME="${CLUSTER_HOSTNAME:-node1}"
export RAFT_BOOTSTRAP_EXPECT="${RAFT_BOOTSTRAP_EXPECT:-1}"

# Authentication: API key only, no anonymous access. The key's user is the RBAC root user.
export AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED="${AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED:-false}"
export AUTHENTICATION_APIKEY_ENABLED="${AUTHENTICATION_APIKEY_ENABLED:-true}"
export AUTHENTICATION_APIKEY_USERS="${AUTHENTICATION_APIKEY_USERS:-admin}"
if [ -z "${AUTHORIZATION_ADMINLIST_ENABLED:-}" ]; then
  export AUTHORIZATION_RBAC_ENABLED="${AUTHORIZATION_RBAC_ENABLED:-true}"
  export AUTHORIZATION_RBAC_ROOT_USERS="${AUTHORIZATION_RBAC_ROOT_USERS:-$AUTHENTICATION_APIKEY_USERS}"
fi

# Modules: the API-based vectorizers and generators (OpenAI, Cohere, ...) are available
# per collection with your own provider key; filesystem backups go to the volume.
export ENABLE_API_BASED_MODULES="${ENABLE_API_BASED_MODULES:-true}"
export ENABLE_MODULES="${ENABLE_MODULES:-backup-filesystem}"
export BACKUP_FILESYSTEM_PATH="${BACKUP_FILESYSTEM_PATH:-$PERSISTENCE_DATA_PATH/backups}"
export QUERY_DEFAULTS_LIMIT="${QUERY_DEFAULTS_LIMIT:-25}"
export GRPC_PORT="${GRPC_PORT:-50051}"
export LOG_LEVEL="${LOG_LEVEL:-info}"
# Derive GOMEMLIMIT and GOMAXPROCS from the container's limits, so Weaviate's
# memory-pressure checks work instead of growing until the container is killed.
export LIMIT_RESOURCES="${LIMIT_RESOURCES:-true}"

mkdir -p "$PERSISTENCE_DATA_PATH"

# Railway routes the public domain and its health check to $PORT.
# "::" listens on IPv6 and IPv4, so Railway's private network reaches it too.
exec /bin/weaviate --host "::" --port "${PORT:-8080}" --scheme http "$@"
