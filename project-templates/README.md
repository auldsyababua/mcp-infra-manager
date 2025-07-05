# MCP Project Templates

These templates demonstrate how to achieve context-aware MCP access in Claude Code.

## How It Works

1. **Global MCPs**: Defined in `~/Library/Application Support/Claude/claude_code_config.json`
   - Always available regardless of where you launch Claude Code
   - Core tools like GitHub, Filesystem, Memory

2. **Project MCPs**: Defined in `.mcp.json` in each project
   - Only available when Claude Code is launched from that project
   - Project-specific tools and integrations

## Templates

### 1. AI/ML Project
- Includes: Jupyter, MLflow, model serving MCPs
- Use for: Machine learning projects

### 2. Web Development
- Includes: Database, API testing, deployment MCPs  
- Use for: Web applications

### 3. DevOps/Infrastructure
- Includes: Kubernetes, Terraform, monitoring MCPs
- Use for: Infrastructure projects

### 4. Mobile Development
- Includes: Device testing, app store MCPs
- Use for: iOS/Android projects

## Usage

1. Copy the appropriate `.mcp.json` to your project root
2. Customize the configuration for your needs
3. Launch Claude Code from the project directory
4. The project MCPs will be available in addition to global ones

## Example Workflow

```bash
# Create new project
mkdir ~/Desktop/projects/my-ml-project
cd ~/Desktop/projects/my-ml-project

# Copy ML template
cp ~/mcp-infra-manager/project-templates/ml-project/.mcp.json .

# Launch Claude Code with ML-specific MCPs
claude

# Check available MCPs
/mcp
# Will show both global MCPs (GitHub, etc.) AND ML-specific MCPs
```

## Customization

Edit `.mcp.json` to:
- Add project-specific MCP servers
- Override global MCP configurations
- Set project-specific environment variables
- Configure remote MCPs on Workhorse

## Best Practices

1. **Don't duplicate global MCPs** unless you need different settings
2. **Use environment variables** for sensitive data
3. **Document required MCPs** in your project README
4. **Version control** your `.mcp.json` with the project
5. **Test MCPs** with `/mcp` command after setup