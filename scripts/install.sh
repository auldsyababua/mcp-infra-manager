#!/bin/bash
# MCP Infrastructure Manager Installation Script

set -euo pipefail

echo "MCP Infrastructure Manager - Installation"
echo "========================================"
echo

# Detect the directory where script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Check prerequisites
echo "Checking prerequisites..."

# Check for yq
if ! command -v yq &> /dev/null; then
    echo "❌ yq is required but not installed."
    echo "   Install with: brew install yq"
    exit 1
else
    echo "✅ yq is installed"
fi

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
else
    echo "✅ Python 3 is installed"
fi

# Install Python dependencies
echo
echo "Installing Python dependencies..."
pip3 install pyyaml requests fastapi uvicorn

# Create necessary directories
echo
echo "Creating directories..."
mkdir -p ~/.mcp/{logs,pids}
mkdir -p ~/.config/mcp

# Create environment file if it doesn't exist
if [[ ! -f ~/.config/mcp/.env ]]; then
    echo "Creating environment file..."
    cat > ~/.config/mcp/.env << 'EOF'
# MCP Infrastructure Environment Variables
# Add your API keys and configuration here

# GitHub
GITHUB_TOKEN=

# Search Providers
BRAVE_API_KEY=
KAGI_API_KEY=
PERPLEXITY_API_KEY=
TAVILY_API_KEY=

# AI/Context Services
UPSTASH_REDIS_URL=
UPSTASH_REDIS_TOKEN=

# Project-specific
AI_RAILS_SECRETS_MCP_AUTH_TOKEN=
GRAPH_SERVICE_URL=http://localhost:8100

# Database (for Claude Collective)
SHELBY_DB_HOST=192.168.5.148
SHELBY_DB_PORT=5432
SHELBY_DB_NAME=claude_collective
SHELBY_DB_USER=postgres
SHELBY_DB_PASSWORD=

# Defaults
DEFAULT_OLLAMA_BASE_URL=http://10.0.0.2:11434
DEFAULT_MCP_TIMEOUT=60
EOF
    echo "✅ Created ~/.config/mcp/.env"
    echo "   Please add your API keys to this file"
else
    echo "✅ Environment file already exists"
fi

# Create symlinks for easy access
echo
echo "Creating command symlinks..."

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Create symlinks
ln -sf "$BASE_DIR/bin/mcp-manager" ~/.local/bin/mcp-manager
ln -sf "$BASE_DIR/bin/mcp-manager" ~/.local/bin/mcp

echo "✅ Created symlinks in ~/.local/bin/"

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo
    echo "⚠️  ~/.local/bin is not in your PATH"
    echo "   Add this to your shell configuration:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Create systemd template for workhorse (to be copied manually)
echo
echo "Creating systemd service template..."
cat > "$BASE_DIR/systemd/mcp-service@.template" << 'EOF'
[Unit]
Description=MCP Service: %i
After=network.target
Documentation=https://github.com/modelcontextprotocol/

[Service]
Type=simple
User=mcp-service
Group=mcp-service
WorkingDirectory=/opt/mcp-services/%i

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/mcp-services/%i/data
ReadOnlyPaths=/opt/mcp-services/%i

# Resource limits
MemoryMax=1G
MemoryHigh=768M
CPUQuota=50%

# Environment
EnvironmentFile=/etc/mcp-services/global.env
EnvironmentFile=-/etc/mcp-services/%i.env

# Start command
ExecStartPre=/opt/mcp-services/scripts/pre-start.sh %i
ExecStart=/opt/mcp-services/%i/venv/bin/python /opt/mcp-services/%i/server.py
ExecReload=/bin/kill -SIGUSR1 $MAINPID

# Restart policy
Restart=on-failure
RestartSec=5s
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Created systemd template"

# Create example integration for context-engineer
echo
echo "Creating context-engineer integration example..."
cat > "$BASE_DIR/docs/context-engineer-integration.py" << 'EOF'
#!/usr/bin/env python3
"""
Example integration for context-engineer-cli-tool
Add this to your context-engineer project
"""

import sys
sys.path.append('/path/to/mcp-infra-manager/api')

from client import MCPInfraClient, get_mcp_prompt_for_task

# Example usage in your planner
def create_agent_prompt(task, project_context):
    # Get base prompt
    base_prompt = "Your task: " + task
    
    # Add MCP services based on context
    mcp_section = get_mcp_prompt_for_task(task, project_context)
    
    return base_prompt + "\n" + mcp_section

# Example with custom profile selection
def create_agent_with_profile(task, profile='default'):
    client = MCPInfraClient()
    
    # Get services for specific profile
    services = client.get_services_for_profile(profile)
    
    # Generate prompt
    prompt = f"Task: {task}\n"
    prompt += client.generate_prompt_section(profile)
    
    return prompt
EOF

# Final instructions
echo
echo "✅ Installation complete!"
echo
echo "Next steps:"
echo "1. Add your API keys to ~/.config/mcp/.env"
echo "2. Test the installation: mcp-manager list"
echo "3. Start a service: mcp-manager start omnisearch"
echo "4. Generate configs: mcp-manager generate claude-desktop default"
echo
echo "For workhorse setup:"
echo "1. Copy $BASE_DIR to workhorse"
echo "2. Copy systemd template to /etc/systemd/system/mcp-service@.service"
echo "3. Create mcp-service user: sudo useradd -r -s /bin/false mcp-service"
echo "4. Set up service directories in /opt/mcp-services/"
echo
echo "Documentation:"
echo "- Quick start: mcp-manager help"
echo "- Integration guide: $BASE_DIR/docs/context-engineer-integration.py"
echo "- Service registry: $BASE_DIR/registry/services.yaml"