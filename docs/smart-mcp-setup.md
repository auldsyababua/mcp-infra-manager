# Smart MCP Setup Guide

## Overview

The Smart MCP system provides intelligent, context-aware access to MCP (Model Context Protocol) services for Claude Code instances. It automatically manages service lifecycle, enforces access controls based on project context, and optimizes resource usage.

## Key Features

1. **Context-Aware Access**: Different MCP sets for different contexts (system, global, project)
2. **Automatic Lifecycle Management**: Services start on-demand and stop after inactivity
3. **Resource Optimization**: Prevents resource waste with automatic timeouts
4. **Single Integration Point**: One proxy endpoint for all Claude instances
5. **Project-Specific MCPs**: Configure allowed MCPs per project

## Installation

### 1. Install Python Dependencies

```bash
pip3 install aiohttp pyyaml psutil
```

### 2. Install the Smart Proxy Service

```bash
# Copy the launchd service
cp ~/mcp-infra-manager/launchd/com.mcp.smartproxy.plist ~/Library/LaunchAgents/

# Load the service
launchctl load ~/Library/LaunchAgents/com.mcp.smartproxy.plist

# Start the service
launchctl start com.mcp.smartproxy
```

### 3. Configure Claude Code Alias

Add this to your shell configuration (`~/.zshrc` or `~/.bashrc`):

```bash
# Smart MCP-enabled Claude
alias claude-mcp='~/mcp-infra-manager/bin/claude-mcp'
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

## Usage

### Basic Usage

```bash
# Launch Claude with MCP support from any directory
claude-mcp

# The smart proxy will automatically:
# 1. Detect your current context
# 2. Start only the allowed MCPs
# 3. Configure Claude to use them
```

### Context Examples

#### System Context (Root/Admin)
```bash
cd /
claude-mcp
# Access to ALL MCPs
```

#### Global Context (Home Directory)
```bash
cd ~
claude-mcp
# Access to: GitHub, Filesystem, Memory, Sequential-Thinking, OmniSearch
```

#### Project Context
```bash
cd ~/Desktop/projects/my-project
claude-mcp
# Access to: MCPs defined in .mcp/config.json
```

## Project Configuration

Create `.mcp/config.json` in your project root:

```json
{
  "allowed_mcps": [
    "github",
    "todoist",
    "project-specific-mcp"
  ],
  "env": {
    "PROJECT_API_KEY": "${PROJECT_API_KEY}"
  },
  "timeout": 600,  // Custom timeout in seconds (default: 300)
  "auto_start": true  // Auto-start these MCPs (default: false)
}
```

## Monitoring

### Check Status
```bash
# View all running MCPs and their status
curl http://localhost:8888/status | jq

# Health check
curl http://localhost:8888/health
```

### View Logs
```bash
# Smart proxy logs
tail -f ~/.mcp/logs/smart-proxy.log

# Service logs
tail -f ~/.mcp/logs/smart-proxy.out
tail -f ~/.mcp/logs/smart-proxy.err
```

## Troubleshooting

### Smart Proxy Not Starting

1. Check if port 8888 is already in use:
   ```bash
   lsof -i :8888
   ```

2. Check service status:
   ```bash
   launchctl list | grep mcp
   ```

3. View error logs:
   ```bash
   cat ~/.mcp/logs/smart-proxy.err
   ```

### MCPs Not Available in Claude

1. Ensure smart proxy is running:
   ```bash
   curl http://localhost:8888/health
   ```

2. Check allowed MCPs for current context:
   ```bash
   curl -H "X-Working-Directory: $PWD" http://localhost:8888/ | jq
   ```

3. Verify MCP services can start:
   ```bash
   ~/mcp-infra-manager/bin/mcp-manager status
   ```

## Advanced Configuration

### Custom Context Rules

Edit the `ContextManager` class in `${HOME}/mcp-infra-manager/bin/mcp-smart-proxy` to add custom contexts:

```python
'custom_context': {
    'path_patterns': ['/path/to/special/projects/*'],
    'allowed_mcps': ['special-mcp-1', 'special-mcp-2'],
    'priority': 20
}
```

### Resource Limits

Modify these constants in the smart proxy script:

```python
ACTIVITY_TIMEOUT = 300  # Seconds before auto-shutdown
CHECK_INTERVAL = 60     # How often to check for inactive services
PROXY_PORT = 8888      # Smart proxy port
```

## Security Considerations

1. **Local Only**: Smart proxy only listens on localhost
2. **No External Access**: Use Tailscale VPN for remote access
3. **Context Isolation**: MCPs are restricted based on working directory
4. **API Key Safety**: Keys are loaded from environment, not stored in config

## Future Enhancements

1. **Web UI**: Dashboard for monitoring and management
2. **Usage Analytics**: Track which MCPs are used most
3. **Dynamic Discovery**: Auto-discover new MCPs
4. **Load Balancing**: Distribute MCPs across multiple machines
5. **Caching**: Cache MCP responses for better performance