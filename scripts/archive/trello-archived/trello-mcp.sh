#!/bin/bash
# MCP Trello wrapper - loads credentials from env file
set -a
source "$(dirname "$0")/trello.env"
set +a
exec npx -y @delorenj/mcp-server-trello "$@"
