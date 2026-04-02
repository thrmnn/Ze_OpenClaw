#!/usr/bin/env node
/**
 * Mission Control - Convex Client
 * Simple CLI to interact with Mission Control Convex backend
 */

const CONVEX_URL = 'https://diligent-ibis-306.convex.cloud';

async function query(functionName, args = {}) {
  const response = await fetch(`${CONVEX_URL}/api/query`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ path: functionName, args, format: 'json' })
  });
  
  if (!response.ok) {
    throw new Error(`Query failed: ${response.statusText}`);
  }
  
  return await response.json();
}

async function mutation(functionName, args = {}) {
  const response = await fetch(`${CONVEX_URL}/api/mutation`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ path: functionName, args, format: 'json' })
  });
  
  if (!response.ok) {
    throw new Error(`Mutation failed: ${response.statusText}`);
  }
  
  return await response.json();
}

async function main() {
  const [,, command, ...args] = process.argv;
  
  try {
    switch (command) {
      case 'agents':
        const agents = await query('agents:listAgents');
        console.log(JSON.stringify(agents.value || agents, null, 2));
        break;
        
      case 'projects':
        const projects = await query('projects:listProjects');
        console.log(JSON.stringify(projects.value || projects, null, 2));
        break;
        
      case 'add-project':
        const name = args.join(' ');
        const projectId = 'p-' + Date.now();
        const newProject = await mutation('projects:createProject', {
          projectId,
          name,
          description: '',
          priority: 'medium'
        });
        console.log(JSON.stringify(newProject.value || newProject, null, 2));
        break;
        
      default:
        console.log('Usage:');
        console.log('  mc-convex.js agents');
        console.log('  mc-convex.js projects');
        console.log('  mc-convex.js add-project <name>');
        process.exit(1);
    }
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

main();
