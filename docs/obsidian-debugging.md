# Obsidian API Debugging

## Current Status
- **Configuration updated:** HTTPS, 127.0.0.1, port 27124
- **API Key:** Set in credentials and MCP config
- **Issue:** Connection refused when trying to connect

## Diagnosis

```bash
curl -k https://127.0.0.1:27124/
# Result: Connection refused (port 27124)
```

**Possible causes:**
1. Plugin not actually running/enabled
2. Different port configured in Obsidian
3. WSL network isolation (Obsidian running on Windows)
4. HTTPS certificate issue

## Next Steps to Debug

### 1. Check Plugin Settings in Obsidian
1. Open Obsidian → Settings → Community Plugins
2. Find "Local REST API"
3. Verify:
   - ✅ Plugin is enabled (toggle on)
   - Port number (should be 27124)
   - HTTPS enabled/disabled
   - "Server started" message in plugin

### 2. Check What's Actually Listening
In Obsidian plugin settings, it should show:
```
Server: https://127.0.0.1:27124
Status: Running
```

### 3. Test from Windows
Since this is WSL, try testing from Windows PowerShell:
```powershell
curl -k https://127.0.0.1:27124/ -H "Authorization: Bearer 92aa35777ef5ea51b4c18cc3f137a0ba848f3ed0ec6f370dc805f28db8149f54"
```

### 4. Alternative: HTTP instead of HTTPS
Try changing to HTTP if HTTPS isn't working:
```bash
curl http://127.0.0.1:27124/ -H "Authorization: Bearer <key>"
```

## When It Works

You should see a JSON response like:
```json
{
  "status": "OK",
  "versions": {
    "obsidian": "...",
    "plugin": "..."
  }
}
```

## Once Connected

We can:
- Create notes in your vault
- Search and read notes  
- Update daily notes
- List vault contents
- Execute Obsidian commands

All via MCP in Claude Code or direct API calls from scripts.
