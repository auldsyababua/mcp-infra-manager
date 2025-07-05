# MCP Infrastructure Manager

Centralized management system for Model Context Protocol (MCP) services, designed to work with Claude Desktop, Claude Code, and context-engineer-cli-tool.

## Features

- 🎯 **Single source of truth** - All MCP services defined in one YAML file
- 🔒 **Profile-based access control** - Control which services different contexts can access
- 🚀 **Easy service management** - Start, stop, and monitor services with simple commands
- 🔑 **Integrated API key management** - Set and check required environment variables
- 🤖 **Multi-tool support** - Generate configs for Claude Desktop and context-engineer
- 🛡️ **Duplicate prevention** - Automatic detection and prevention of duplicate instances
- 📊 **Health monitoring** - Built-in health checks for all services

## Quick Start

### Installation

```bash
# Clone or download this repository
cd ~/mcp-infra-manager

# Run the installation script
./scripts/install.sh

# Add API keys to ~/.config/mcp/.env
nano ~/.config/mcp/.env
```

### Basic Usage

```bash
# List all services and their status
mcp-manager list

# Start a service
mcp-manager start omnisearch

# Check required environment variables
mcp-manager keys check

# Set an API key
mcp-manager keys set BRAVE_API_KEY "your-key-here"

# Show services for a profile
mcp-manager profile research

# Generate Claude Desktop config
mcp-manager generate claude-desktop research
```

## Adding New Services

### Method 1: Interactive (Recommended)

```bash
mcp-manager add
```

Follow the prompts to add your service.

### Method 2: Edit Registry

Edit `registry/services.yaml`:

```yaml
services:
  my-new-service:
    name: "My New Service"
    description: "What this service does"
    port: 8200
    command: "npx -y @org/my-service"
    category: "development"
    env_vars:
      - MY_SERVICE_API_KEY
```

## Profile System

Profiles control which services are available in different contexts:

- **default** - Basic services for general tasks
- **research** - Extended search and AI capabilities
- **ai-rails** - Project-specific services
- **development** - Code analysis and development tools
- **restricted** - Minimal access for sensitive operations
- **admin** - Full access to all services

## Integration Examples

### Context Engineer CLI Tool

```python
from mcp_infra_manager.api.client import get_mcp_prompt_for_task

# In your agent creation
def create_agent(task, context):
    prompt = f"Task: {task}\n"
    prompt += get_mcp_prompt_for_task(task, context)
    return prompt
```

### Claude Desktop

```bash
# Generate and install config
mcp-manager generate claude-desktop research ~/Desktop/claude-config.json
```

### Manual Integration

```python
from mcp_infra_manager.api.client import MCPInfraClient

client = MCPInfraClient()

# Get services for a profile
services = client.get_services_for_profile('research')

# Generate prompt section
prompt = client.generate_prompt_section('research')

# Auto-detect profile
profile = client.determine_profile(task, project_context)
```

## Service Categories

- **core** - Essential services (GitHub, Filesystem, Memory)
- **search** - Web search services (OmniSearch, Brave)
- **ai-context** - AI enhancement services (Context7, Sequential Thinking)
- **project** - Project-specific services
- **development** - Development tools

## Environment Variables

All API keys and configuration are stored in `~/.config/mcp/.env`:

```bash
# View required variables
mcp-manager keys list

# Check which are missing
mcp-manager keys check

# Set a variable
mcp-manager keys set GITHUB_TOKEN "ghp_..."
```

## Architecture

```
Local Machine (Mac Mini)
├── mcp-infra-manager/          # This management system
├── ~/.config/mcp/.env          # API keys and config
└── ~/.mcp/                     # Logs and PIDs

Workhorse Server (10.0.0.2)
├── /opt/mcp-services/          # Service installations
├── systemd services            # Running MCP servers
└── Docker containers           # Some services in containers
```

## Troubleshooting

### Service won't start
```bash
# Check logs
tail -f ~/.mcp/logs/service-name.log

# Check if port is in use
lsof -i :8084

# Try starting manually
mcp-manager start omnisearch
```

### Missing API keys
```bash
# See what's required
mcp-manager keys check

# Set missing keys
mcp-manager keys set KAGI_API_KEY "your-key"
```

### Profile not working
```bash
# Verify profile exists
mcp-manager profile research

# Check service status
mcp-manager health
```

## Advanced Features

### Custom Profiles

Edit `profiles/access-profiles.yaml` to create custom profiles for specific use cases.

### Remote Services

Services marked with `location: workhorse` run on the remote server and are accessed via the 10GbE link.

### Health Monitoring

```bash
# Check all services
mcp-manager health
```

### Service Updates

```bash
# Update a service property
mcp-manager update omnisearch port 8085
```

## Security

- Services run with limited privileges
- Profile-based access control
- API keys stored separately from configuration
- No direct internet exposure of services
- Authentication required for sensitive services

## Contributing

To add new services or features:

1. Edit `registry/services.yaml` for new services
2. Edit `profiles/access-profiles.yaml` for new profiles
3. Test with `mcp-manager list`
4. Submit changes

## License

MIT License - See LICENSE file for details