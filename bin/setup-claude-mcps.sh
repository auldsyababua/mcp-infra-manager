#!/bin/bash
# Setup Claude Code MCP configuration

set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CONFIG_DIR="$HOME/.config/Claude"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

CONFIG_FILE="$CONFIG_DIR/claude_code_config.json"
SOURCE_CONFIG="$(dirname "$0")/../claude-code-config.json"

echo "🚀 Claude Code MCP Setup"
echo "========================"
echo ""

# Create directory if needed
mkdir -p "$CONFIG_DIR"

# Check if config already exists
if [[ -f "$CONFIG_FILE" ]]; then
    echo "⚠️  Existing configuration found at: $CONFIG_FILE"
    read -p "Back up and replace? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$BACKUP"
        echo "✅ Backed up to: $BACKUP"
    else
        echo "❌ Setup cancelled"
        exit 0
    fi
fi

# Copy configuration
cp "$SOURCE_CONFIG" "$CONFIG_FILE"
echo "✅ Configuration installed to: $CONFIG_FILE"

# Check for environment variables
echo ""
echo "🔍 Checking environment variables..."
echo ""

check_env() {
    local var=$1
    local desc=$2
    if [[ -z "${!var}" ]]; then
        echo "❌ $var not set - $desc"
        return 1
    else
        echo "✅ $var is set"
        return 0
    fi
}

MISSING_VARS=0

check_env "GITHUB_TOKEN" "GitHub personal access token" || ((MISSING_VARS++))
check_env "BRAVE_API_KEY" "Brave Search API key" || ((MISSING_VARS++))
check_env "TAVILY_API_KEY" "Tavily search API key (optional)" || true
check_env "PERPLEXITY_API_KEY" "Perplexity API key (optional)" || true
check_env "TODOIST_API_TOKEN" "Todoist API token (optional)" || true

echo ""

if [[ $MISSING_VARS -gt 0 ]]; then
    echo "⚠️  Missing $MISSING_VARS required environment variables"
    echo ""
    echo "Add these to your shell profile (~/.zshrc or ~/.bashrc):"
    echo ""
    echo "export GITHUB_TOKEN='your-github-token'"
    echo "export BRAVE_API_KEY='your-brave-api-key'"
    echo ""
    echo "Get API keys from:"
    echo "- GitHub: https://github.com/settings/tokens"
    echo "- Brave: https://brave.com/search/api/"
else
    echo "✅ All required environment variables are set!"
fi

# Create example project MCP config
echo ""
echo "📁 Creating example project configurations..."

EXAMPLES_DIR="$HOME/mcp-examples"
mkdir -p "$EXAMPLES_DIR"

# Web project example
cat > "$EXAMPLES_DIR/web-project.mcp.json" << 'EOF'
{
  "mcpServers": {
    "web-tools": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@your-org/web-mcp-tools"],
      "env": {
        "PROJECT_TYPE": "web"
      }
    }
  }
}
EOF

# ML project example
cat > "$EXAMPLES_DIR/ml-project.mcp.json" << 'EOF'
{
  "mcpServers": {
    "jupyter": {
      "type": "stdio",
      "command": "python",
      "args": ["-m", "mcp_jupyter_server"],
      "env": {
        "JUPYTER_URL": "http://localhost:8888"
      }
    }
  }
}
EOF

echo "✅ Example configurations created in: $EXAMPLES_DIR"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Set any missing environment variables"
echo "2. Restart your shell or run: source ~/.zshrc"
echo "3. Launch Claude Code: claude"
echo "4. Check MCP status: /mcp"
echo ""
echo "To use project-specific MCPs:"
echo "- Copy an example from $EXAMPLES_DIR to your project as .mcp.json"
echo "- Or create your own .mcp.json in any project directory"