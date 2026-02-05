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

# Execute the original Neo4j entrypoint
exec /startup/docker-entrypoint.sh "$@"
