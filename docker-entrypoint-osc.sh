#!/bin/bash
# OSC entrypoint wrapper for Neo4j
# Maps PORT environment variable to Neo4j HTTP listen address

set -e

# Default PORT if not set
: "${PORT:=7474}"

# Configure Neo4j to listen on the specified PORT for HTTP
# Neo4j uses double underscore for dots in config property names
export NEO4J_server_http_listen__address="0.0.0.0:${PORT}"

# Disable auth by default for easier OSC deployment (can be overridden)
: "${NEO4J_AUTH:=none}"
export NEO4J_AUTH

# Set default listen address to allow external connections
export NEO4J_server_default__listen__address="0.0.0.0"

# Set memory limits suitable for containerized environments
# These can be overridden via environment variables
: "${NEO4J_server_memory_pagecache_size:=256M}"
export NEO4J_server_memory_pagecache_size

: "${NEO4J_server_memory_heap_initial__size:=256M}"
export NEO4J_server_memory_heap_initial__size

: "${NEO4J_server_memory_heap_max__size:=256M}"
export NEO4J_server_memory_heap_max__size

# Enable TLS on Bolt connector for HTTPS browser compatibility
# This allows bolt+s:// connections when the UI is served over HTTPS
BOLT_CERT_DIR="/var/lib/neo4j/certificates/bolt"
mkdir -p "${BOLT_CERT_DIR}"

# Generate self-signed certificate if not present
if [ ! -f "${BOLT_CERT_DIR}/private.key" ]; then
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout "${BOLT_CERT_DIR}/private.key" \
        -out "${BOLT_CERT_DIR}/public.crt" \
        -subj "/CN=neo4j" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
        2>/dev/null
    chown -R neo4j:neo4j "${BOLT_CERT_DIR}" 2>/dev/null || true
fi

export NEO4J_dbms_ssl_policy_bolt_enabled="true"
export NEO4J_dbms_ssl_policy_bolt_base__directory="${BOLT_CERT_DIR}"
export NEO4J_dbms_ssl_policy_bolt_private__key="private.key"
export NEO4J_dbms_ssl_policy_bolt_public__certificate="public.crt"
export NEO4J_server_bolt_tls__level="OPTIONAL"

# Execute the original Neo4j entrypoint
exec /startup/docker-entrypoint.sh "$@"
