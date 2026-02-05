#!/bin/bash
# OSC entrypoint wrapper for Neo4j
# Runs nginx proxy in front of Neo4j to serve both HTTP and Bolt on a single port

set -e

# Default PORT if not set
: "${PORT:=7474}"

echo "[OSC] Starting Neo4j OSC wrapper"
echo "[OSC] PORT=${PORT}"
echo "[OSC] OSC_HOSTNAME=${OSC_HOSTNAME:-<not set>}"

# Generate nginx config with PORT substituted
envsubst '${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Configure Neo4j to listen on localhost only (nginx will proxy)
export NEO4J_server_http_listen__address="127.0.0.1:7474"
export NEO4J_server_bolt_listen__address="127.0.0.1:7687"

# Configure advertised addresses for Neo4j Browser discovery
if [ -n "${OSC_HOSTNAME}" ]; then
    # OSC deployment: use hostname with HTTPS port
    export NEO4J_server_default__advertised__address="${OSC_HOSTNAME}"
    export NEO4J_server_bolt_advertised__address="${OSC_HOSTNAME}:443"
else
    # Local development: use localhost with PORT
    export NEO4J_server_default__advertised__address="localhost"
    export NEO4J_server_bolt_advertised__address="localhost:${PORT}"
fi

echo "[OSC] NEO4J_server_default__advertised__address=${NEO4J_server_default__advertised__address}"
echo "[OSC] NEO4J_server_bolt_advertised__address=${NEO4J_server_bolt_advertised__address}"
echo "[OSC] NEO4J_server_http_listen__address=${NEO4J_server_http_listen__address}"
echo "[OSC] NEO4J_server_bolt_listen__address=${NEO4J_server_bolt_listen__address}"
echo "[OSC] NEO4J_AUTH=${NEO4J_AUTH:-<will be set>}"

# Enable debug logging for Neo4j and output to stdout
export NEO4J_server_logs_debug_enabled="true"
export NEO4J_server_logs_user_stdout__enabled="true"
export NEO4J_server_config_strict__validation_enabled="false"
echo "[OSC] NEO4J_server_logs_debug_enabled=true"
echo "[OSC] NEO4J_server_logs_user_stdout__enabled=true"

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
echo "[OSC] Starting nginx on port ${PORT}"
nginx

echo "[OSC] Starting Neo4j..."
# Execute the original Neo4j entrypoint
exec /startup/docker-entrypoint.sh "$@"
