#!/bin/bash
# Deploy MCP Infrastructure Manager to Workhorse

set -euo pipefail

WORKHORSE_IP="${WORKHORSE_IP:-10.0.0.2}"
WORKHORSE_USER="${WORKHORSE_USER:-workhorse}"

echo "MCP Infrastructure Manager - Deploy to Workhorse"
echo "=============================================="
echo

# Get the directory where script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Deploying from: $BASE_DIR"
echo "Target: $WORKHORSE_USER@$WORKHORSE_IP"
echo

# Copy the infrastructure manager
echo "Copying MCP Infrastructure Manager..."
rsync -avz --exclude='.git' --exclude='*.pyc' --exclude='__pycache__' \
    "$BASE_DIR/" "$WORKHORSE_USER@$WORKHORSE_IP:~/mcp-infra-manager/"

# Run remote setup
echo
echo "Running remote setup..."
ssh "$WORKHORSE_USER@$WORKHORSE_IP" << 'REMOTE_SCRIPT'
set -euo pipefail

echo "Setting up MCP Infrastructure Manager on Workhorse..."

# Install dependencies if needed
if ! command -v yq &> /dev/null; then
    echo "Installing yq..."
    sudo apt-get update
    sudo apt-get install -y python3-pip
    pip3 install yq
fi

# Install Python dependencies
pip3 install pyyaml requests fastapi uvicorn

# Create directories
sudo mkdir -p /opt/mcp-services
sudo mkdir -p /etc/mcp-services
sudo mkdir -p /var/log/mcp-services

# Create mcp-service user if it doesn't exist
if ! id -u mcp-service &>/dev/null; then
    echo "Creating mcp-service user..."
    sudo useradd -r -s /bin/false -d /opt/mcp-services mcp-service
fi

# Set permissions
sudo chown -R mcp-service:mcp-service /opt/mcp-services
sudo chown -R mcp-service:mcp-service /var/log/mcp-services

# Copy systemd template
if [[ -f ~/mcp-infra-manager/systemd/mcp-service@.template ]]; then
    echo "Installing systemd template..."
    sudo cp ~/mcp-infra-manager/systemd/mcp-service@.template \
        /etc/systemd/system/mcp-service@.service
    sudo systemctl daemon-reload
fi

# Create global environment file if it doesn't exist
if [[ ! -f /etc/mcp-services/global.env ]]; then
    echo "Creating global environment file..."
    sudo tee /etc/mcp-services/global.env << 'EOF'
# Global MCP Service Environment
# Add shared environment variables here
MCP_LOG_LEVEL=INFO
EOF
fi

# Create pre-start script
sudo tee /opt/mcp-services/scripts/pre-start.sh << 'EOF'
#!/bin/bash
# Pre-start script for MCP services
SERVICE=$1

echo "Pre-start checks for $SERVICE..."

# Ensure service directory exists
mkdir -p /opt/mcp-services/$SERVICE/data

# Check if virtual environment exists
if [[ ! -d /opt/mcp-services/$SERVICE/venv ]]; then
    echo "Creating virtual environment..."
    python3 -m venv /opt/mcp-services/$SERVICE/venv
fi

echo "Pre-start complete"
EOF

sudo chmod +x /opt/mcp-services/scripts/pre-start.sh
sudo chown mcp-service:mcp-service /opt/mcp-services/scripts/pre-start.sh

echo
echo "✅ Workhorse setup complete!"
echo
echo "Next steps on Workhorse:"
echo "1. Deploy individual MCP services to /opt/mcp-services/"
echo "2. Create service-specific .env files in /etc/mcp-services/"
echo "3. Start services with: sudo systemctl start mcp-service@<name>"
echo "4. Enable auto-start: sudo systemctl enable mcp-service@<name>"

REMOTE_SCRIPT

echo
echo "✅ Deployment complete!"
echo
echo "To manage MCPs on Workhorse:"
echo "1. SSH to workhorse: ssh $WORKHORSE_USER@$WORKHORSE_IP"
echo "2. Use the manager: ~/mcp-infra-manager/bin/mcp-manager"
echo
echo "Remember to:"
echo "- Update the registry to mark which services run on 'workhorse'"
echo "- Configure environment variables for each service"
echo "- Test connectivity from your local machine"