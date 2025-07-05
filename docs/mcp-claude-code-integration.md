# MCP Integration with Claude Code CLI

## Current State (July 2025)

### The Challenge

Claude Code CLI (`claude` command) currently has limited MCP support compared to Claude Desktop:

1. **No Dynamic Configuration**: Claude Code doesn't read MCP configuration from files or environment variables
2. **Hardcoded MCPs**: Only specific MCPs (like omnisearch, graphql) are available
3. **No Context Awareness**: Can't dynamically change MCPs based on working directory

### What We've Built

1. **Smart MCP Proxy** (Port 8888)
   - Context-aware routing
   - Automatic lifecycle management
   - Resource optimization
   - Ready for when Claude Code supports external MCP configuration

2. **MCP Controller** (Port 8080)
   - Legacy service registry
   - HTTP routing to individual MCPs
   - Currently used by some tools

3. **Infrastructure**
   - Service definitions in `registry/services.yaml`
   - LaunchD service for automatic startup
   - Comprehensive logging and monitoring

## Working with Current Limitations

### Option 1: Use Existing MCPs

The MCPs currently available in Claude Code:
- `mcp-omnisearch`: Multi-provider web search
- `graphql`: GraphQL API queries

These work out of the box without additional configuration.

### Option 2: Use Claude Desktop

Claude Desktop supports full MCP configuration through `claude_desktop_config.json`. You can:

1. Configure MCPs in the desktop app
2. Use the desktop app for MCP-heavy workflows
3. Use Claude Code CLI for simpler tasks

### Option 3: Indirect MCP Usage

Create wrapper scripts that:
1. Call MCP services directly via HTTP
2. Process results
3. Feed them to Claude Code as context

Example:
```bash
# Query GitHub MCP and pipe to Claude
curl -X POST http://localhost:8081/query \
  -d '{"repo": "owner/repo"}' | \
  claude "analyze this GitHub data"
```

## Future Integration Path

When Claude Code adds MCP configuration support, our infrastructure is ready:

### 1. Environment Variable Support
If Claude Code starts reading from environment:
```bash
export CLAUDE_MCP_CONFIG="/path/to/mcp-config.json"
export CLAUDE_MCP_PROXY="http://localhost:8888"
```

### 2. Configuration File Support
If Claude Code starts reading config files:
```json
// ~/.claude/config.json
{
  "mcp": {
    "proxy": "http://localhost:8888",
    "timeout": 30000
  }
}
```

### 3. Command-Line Flags
If Claude Code adds MCP flags:
```bash
claude --mcp-proxy http://localhost:8888 --mcp-context project
```

## Immediate Workarounds

### 1. Project Context Simulation

Create a `.claude-context` file in your project:
```bash
#!/bin/bash
# Load project-specific context

echo "Project: My Project"
echo "Available tools: GitHub, Todoist"
echo "API endpoints: http://localhost:8081/github"
```

Then source it before using Claude:
```bash
source .claude-context && claude
```

### 2. MCP Status Dashboard

Use the smart proxy status endpoint:
```bash
# Check what MCPs would be available
curl http://localhost:8888/status | jq

# Check MCP controller
curl http://localhost:8080/status | jq
```

### 3. Manual MCP Management

Use the provided scripts:
```bash
# Start core MCPs
~/mcp-infra-manager/bin/mcp-quick-setup

# Check status
~/mcp-infra-manager/bin/mcp-manager status

# Stop all MCPs
~/mcp-infra-manager/bin/mcp-manager stop all
```

## Monitoring MCP Requests

Even though Claude Code can't use all MCPs yet, you can monitor what it's trying to access:

```bash
# Watch smart proxy logs
tail -f ~/.mcp/logs/smart-proxy.log

# Watch controller logs  
tail -f ~/.mcp/logs/controller.log
```

## Next Steps

1. **Monitor Claude Code Updates**: Watch for MCP configuration support
2. **Community Engagement**: Check if others have found workarounds
3. **API Bridge**: Consider building a bridge that translates MCP calls
4. **Feature Request**: Request MCP configuration support from Anthropic

## Technical Details

### Why Current Integration Doesn't Work

1. Claude Code CLI is a compiled binary that doesn't expose MCP configuration
2. It connects directly to preconfigured MCP endpoints
3. No hooks for proxy injection or configuration override

### What Would Need to Change

1. Claude Code needs to read MCP configuration from:
   - Environment variables
   - Configuration files
   - Command-line arguments

2. Support for MCP proxy/router instead of direct connections

3. Dynamic MCP discovery mechanism

## Conclusion

While we've built a sophisticated MCP infrastructure ready for the future, current Claude Code CLI limitations mean we can't fully utilize it yet. The infrastructure is ready and waiting for when Claude Code adds proper MCP configuration support.

In the meantime, use the available MCPs (omnisearch, graphql) and consider Claude Desktop for workflows requiring other MCPs.