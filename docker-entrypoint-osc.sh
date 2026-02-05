#!/bin/bash
# OSC entrypoint wrapper for Neo4j
# Runs nginx proxy in front of Neo4j to serve both HTTP and Bolt on a single port

set -e

# Default PORT if not set
: "${PORT:=7474}"

# Generate nginx config with PORT substituted
envsubst '${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Configure Neo4j to listen on localhost only (nginx will proxy)
export NEO4J_server_http_listen__address="127.0.0.1:7474"
export NEO4J_server_bolt_listen__address="127.0.0.1:7687"

# Configure advertised addresses for Neo4j Browser discovery
# If OSC_HOSTNAME is set, advertise the correct URL for HTTPS environments
if [ -n "${OSC_HOSTNAME}" ]; then
    export NEO4J_server_default__advertised__address="${OSC_HOSTNAME}"
    export NEO4J_server_bolt_advertised__address="${OSC_HOSTNAME}/bolt"
fi

# Disable auth by default for easier OSC deployment (can be overridden)
: "${NEO4J_AUTH:=none}"
export NEO4J_AUTH

# Set memory limits suitable for containerized environments
: "${NEO4J_server_memory_pagecache_size:=256M}"
export NEO4J_server_memory_pagecache_size

: "${NEO4J_server_memory_heap_initial__size:=256M}"
export NEO4J_server_memory_heap_initial__size

: "${NEO4J_server_memory_heap_max__size:=256M}"
export NEO4J_server_memory_heap_max__size

# Start nginx in background
nginx

# Execute the original Neo4j entrypoint
exec /startup/docker-entrypoint.sh "$@"
