#!/bin/bash
# Create ze-main agent via Mission Control API

MC_URL="https://mission-control-ruby-zeta.vercel.app"

echo "Creating ze-main agent..."

# Call the activity API (which works) to log this action
curl -s -X POST "$MC_URL/api/activity" \
  -H "Content-Type: application/json" \
  -d '{"type":"setup","message":"Creating ze-main agent","agentId":"system"}'

echo ""
echo "Using Convex CLI to insert ze-main directly..."

cd ~/clawd/mission-control

# Use the seed function but modify it first, OR just use SQL-like insert
# Actually, let me use the working test-direct endpoint pattern

cat > /tmp/insert-ze.js << 'ENDJS'
const { ConvexHttpClient } = require("convex/browser");

async function insertZeMain() {
  const convex = new ConvexHttpClient("https://usable-whale-844.convex.cloud");
  
  try {
    // Try seed first
    const result = await convex.mutation("seed:seedAgents", {});
    console.log("Seed result:", JSON.stringify(result));
    
    // List agents to verify
    const agents = await convex.query("agents:listAgents", {});
    console.log("Total agents:", agents.length);
    console.log("Agent IDs:", agents.map(a => a.agentId).join(", "));
    
    const zeExists = agents.some(a => a.agentId === "ze-main");
    console.log("ze-main exists:", zeExists);
    
  } catch (error) {
    console.error("Error:", error.message);
  }
}

insertZeMain();
ENDJS

cd ~/clawd/mission-control && node /tmp/insert-ze.js
