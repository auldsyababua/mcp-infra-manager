# Claude Code MCP Setup Guide

## How Claude Code MCP Configuration Actually Works

### 1. Configuration Locations

Claude Code looks for MCP configurations in these locations:

**macOS**:
- Global: `~/Library/Application Support/Claude/claude_code_config.json`
- Project: `.mcp.json` in project root

**Linux**:
- Global: `~/.config/Claude/claude_code_config.json`
- Project: `.mcp.json` in project root

### 2. Setting Up Global MCP Configuration

#### Option A: Using Claude Code CLI (Interactive)

```bash
# Add MCP servers one by one
claude mcp add github
claude mcp add filesystem  
claude mcp add memory
claude mcp add mcp-omnisearch
# ... etc
```

#### Option B: Direct Configuration (Recommended)

1. Create/edit the configuration file:

**macOS**:
```bash
mkdir -p ~/Library/Application\ Support/Claude
nano ~/Library/Application\ Support/Claude/claude_code_config.json
```

**Linux**:
```bash
mkdir -p ~/.config/Claude
nano ~/.config/Claude/claude_code_config.json
```

2. Add your MCP server configurations (see example below)

### 3. Example Global Configuration

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${HOME}"],
      "env": {}
    },
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "sequential-thinking": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    },
    "mcp-omnisearch": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "mcp-omnisearch"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}",
        "TAVILY_API_KEY": "${TAVILY_API_KEY}"
      }
    }
  }
}
```

### 4. Project-Specific Configuration

Create `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "project-db": {
      "type": "stdio",
      "command": "node",
      "args": ["./scripts/mcp-db-server.js"],
      "env": {
        "DATABASE_URL": "${PROJECT_DATABASE_URL}"
      }
    },
    "project-api": {
      "type": "stdio",
      "command": "python",
      "args": ["./tools/api-mcp.py"],
      "env": {
        "API_ENDPOINT": "https://api.myproject.com"
      }
    }
  }
}
```

### 5. Environment Variables

Claude Code reads environment variables from your system. Set them in your shell profile:

```bash
# In ~/.zshrc or ~/.bashrc
export GITHUB_TOKEN="your-github-token"
export BRAVE_API_KEY="your-brave-key"
export TAVILY_API_KEY="your-tavily-key"
# ... etc
```

Or use a `.env` file with a tool like `direnv`.

### 6. Remote MCP Servers (Workhorse)

For MCPs running on your Workhorse server, use SSH:

```json
{
  "mcpServers": {
    "workhorse-llm": {
      "type": "stdio",
      "command": "ssh",
      "args": [
        "-o", "StrictHostKeyChecking=no",
        "username@workhorse-ip",
        "cd /path/to/mcp && node server.js"
      ],
      "env": {}
    }
  }
}
```

### 7. Context-Aware Setup (What You Actually Want)

Since Claude Code automatically loads `.mcp.json` from the current directory, you can achieve context-aware MCP access by:

1. **Global MCPs**: Put core MCPs in the global config
2. **Project MCPs**: Create `.mcp.json` in each project
3. **Template Projects**: Create project templates with pre-configured `.mcp.json` files

Example project structure:
```
~/Desktop/projects/
├── web-project/
│   └── .mcp.json  # Web-specific MCPs
├── ml-project/
│   └── .mcp.json  # ML-specific MCPs
└── devops-project/
    └── .mcp.json  # DevOps-specific MCPs
```

### 8. Verifying Your Setup

1. Launch Claude Code:
   ```bash
   claude
   ```

2. Use the `/mcp` command to see available servers

3. Check server status with `@` in your prompts

### 9. Resource Management

Claude Code handles this automatically:
- Starts MCP servers on first use
- Stops them when Claude Code exits
- No manual lifecycle management needed

### 10. Quick Setup Script

Create `~/bin/setup-claude-mcps.sh`:

```bash
#!/bin/bash
# Quick setup for Claude Code MCPs

CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_code_config.json"

# Create directory if needed
mkdir -p "$CONFIG_DIR"

# Copy our configuration
cp ~/mcp-infra-manager/claude-code-config.json "$CONFIG_FILE"

echo "✅ Claude Code MCP configuration installed!"
echo ""
echo "Next steps:"
echo "1. Set environment variables in your shell profile:"
echo "   export GITHUB_TOKEN='your-token'"
echo "   export BRAVE_API_KEY='your-key'"
echo "   # ... etc"
echo ""
echo "2. Restart your shell or source your profile"
echo "3. Launch Claude Code and check /mcp"
```

### Key Differences from Your Original Plan

1. **No proxy needed** - Claude Code handles routing
2. **No lifecycle management** - Automatic start/stop
3. **Context via directories** - Project `.mcp.json` files
4. **Native configuration** - Use Claude's built-in config
5. **Environment variables** - Standard shell environment

This achieves all your goals using Claude Code's native capabilities!