#!/bin/bash
# Setup Obsidian MCP Integration
# Requires: Obsidian with Local REST API plugin installed

set -e

echo "=== Obsidian MCP Setup ==="
echo
echo "Prerequisites:"
echo "1. Obsidian installed"
echo "2. Local REST API plugin installed (Community Plugins)"
echo "3. Plugin enabled in Obsidian settings"
echo
echo "Steps:"
echo "1. Open Obsidian → Settings → Community Plugins"
echo "2. Search for 'Local REST API' and install it"
echo "3. Enable the plugin"
echo "4. Copy the API key from plugin settings"
echo

read -p "Do you have the API key ready? (y/n): " has_key

if [ "$has_key" != "y" ]; then
  echo
  echo "Please complete the steps above and run this script again."
  exit 1
fi

read -p "Enter your Obsidian API key: " api_key
read -p "Enter Obsidian port (default: 27123): " port
port=${port:-27123}

# Save to credentials
mkdir -p ~/clawd/credentials
cat > ~/clawd/credentials/obsidian.env << EOF
OBSIDIAN_API_KEY=$api_key
OBSIDIAN_PROTOCOL=http
OBSIDIAN_HOST=localhost
OBSIDIAN_PORT=$port
EOF

echo
echo "✅ Credentials saved to ~/clawd/credentials/obsidian.env"
echo

# Update MCP config
MCP_CONFIG=~/.config/claude-code/mcp.json

if [ -f "$MCP_CONFIG" ]; then
  # Backup existing config
  cp "$MCP_CONFIG" "${MCP_CONFIG}.backup"
  
  # Add obsidian server using jq
  jq '.mcpServers.obsidian = {
    "command": "npx",
    "args": ["-y", "@fazer-ai/mcp-obsidian@latest"],
    "env": {
      "OBSIDIAN_API_KEY": "'"$api_key"'",
      "OBSIDIAN_PROTOCOL": "http",
      "OBSIDIAN_HOST": "localhost",
      "OBSIDIAN_PORT": "'"$port"'"
    }
  }' "$MCP_CONFIG" > "${MCP_CONFIG}.tmp"
  
  mv "${MCP_CONFIG}.tmp" "$MCP_CONFIG"
  
  echo "✅ Updated MCP config: $MCP_CONFIG"
else
  echo "⚠️  MCP config not found: $MCP_CONFIG"
  echo "Creating new config..."
  
  mkdir -p ~/.config/claude-code
  cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["-y", "@fazer-ai/mcp-obsidian@latest"],
      "env": {
        "OBSIDIAN_API_KEY": "$api_key",
        "OBSIDIAN_PROTOCOL": "http",
        "OBSIDIAN_HOST": "localhost",
        "OBSIDIAN_PORT": "$port"
      }
    }
  }
}
EOF
  echo "✅ Created MCP config: $MCP_CONFIG"
fi

echo
echo "=== Setup Complete! ==="
echo
echo "Test the integration:"
echo "  1. Make sure Obsidian is running"
echo "  2. Test: curl http://localhost:$port/ -H 'Authorization: Bearer $api_key'"
echo
echo "Available tools in Claude Code:"
echo "  - obsidian_get_active (get current note)"
echo "  - obsidian_search_simple (search notes)"
echo "  - obsidian_list_vault_root (list files)"
echo "  - obsidian_post_file (create/append notes)"
echo "  - ...and many more"
echo
