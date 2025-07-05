# Quick Integration Guide for Context Engineer CLI Tool

## Installation

1. Install MCP Infrastructure Manager:
```bash
cd ~/mcp-infra-manager
./scripts/install.sh
```

2. Add your API keys:
```bash
# Use your existing env file
cp ~/.config/mcp/.env.backup ~/.config/mcp/.env

# Or manually add keys
mcp-manager keys set GITHUB_TOKEN "your-token"
mcp-manager keys set BRAVE_API_KEY "your-key"
# etc...
```

## Integration Code

Add this to your context-engineer-cli-tool:

### Option 1: Simple Integration

```python
# In your agent creation code
import subprocess
import json

def get_mcp_services_for_agent(task, project_path):
    """Get MCP services based on task context"""
    
    # Determine profile based on context
    profile = 'default'
    if 'ai-rails' in project_path:
        profile = 'ai-rails'
    elif 'project-shelby' in project_path:
        profile = 'project-shelby'
    elif any(word in task.lower() for word in ['research', 'search', 'find']):
        profile = 'research'
    
    # Get MCP prompt section
    result = subprocess.run(
        ['~/mcp-infra-manager/scripts/generate-context-prompt.py', profile],
        capture_output=True,
        text=True
    )
    
    return result.stdout if result.returncode == 0 else ""

# Use in your planner
def create_agent_prompt(task, context):
    base_prompt = f"Task: {task}"
    mcp_section = get_mcp_services_for_agent(task, context.get('project_path', ''))
    return f"{base_prompt}\n{mcp_section}"
```

### Option 2: Using the Client Library

```python
# Add to your project
import sys
sys.path.append('~/mcp-infra-manager/api')

from client import MCPInfraClient

# Initialize once
mcp_client = MCPInfraClient()

# In your planner
def create_agent_prompt(task, context):
    # Auto-detect profile
    profile = mcp_client.determine_profile(task, context)
    
    # Get MCP section
    mcp_section = mcp_client.generate_prompt_section(profile)
    
    return f"Task: {task}\n{mcp_section}"
```

## Managing Services

### Start services you need:
```bash
# Start core services
mcp-manager start github
mcp-manager start filesystem
mcp-manager start memory

# Start search services
mcp-manager start omnisearch

# Check status
mcp-manager list
```

### Add new services:
```bash
# Interactive add
mcp-manager add

# Or edit the registry directly
nano ~/mcp-infra-manager/registry/services.yaml
```

### Set API keys:
```bash
# Check what's needed
mcp-manager keys check

# Set missing keys
mcp-manager keys set KAGI_API_KEY "your-key"
```

## Profile Configuration

Edit `~/mcp-infra-manager/profiles/access-profiles.yaml` to customize which services are available for different contexts.

## Example: Adding a Custom MCP

1. Add to registry:
```yaml
# In registry/services.yaml
services:
  my-custom-mcp:
    name: "My Custom MCP"
    description: "Does something specific"
    port: 8200
    command: "python3 /path/to/my-mcp/server.py"
    category: "custom"
```

2. Add to profiles:
```yaml
# In profiles/access-profiles.yaml
profiles:
  my-project:
    name: "My Project"
    description: "Custom project profile"
    services:
      - github
      - filesystem
      - my-custom-mcp
```

3. Use in context-engineer:
```python
# Auto-detect based on project path
if 'my-project' in context['project_path']:
    profile = 'my-project'
```

## Benefits

- ✅ **No duplicate MCPs** - System prevents multiple instances
- ✅ **Easy to add services** - Just edit YAML files
- ✅ **Profile-based access** - Control what each agent can see
- ✅ **Centralized management** - One place for all MCP config
- ✅ **Works with existing setup** - Integrates with your current tools