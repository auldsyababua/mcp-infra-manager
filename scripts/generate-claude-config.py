#!/usr/bin/env python3
"""
Generate Claude Desktop configuration for a specific profile
"""
import json
import sys
import yaml
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: generate-claude-config.py <profile> [output_file]")
        sys.exit(1)
    
    profile_name = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Load registry and profiles
    base_dir = Path(__file__).parent.parent
    with open(base_dir / "registry/services.yaml") as f:
        registry = yaml.safe_load(f)
    
    with open(base_dir / "profiles/access-profiles.yaml") as f:
        profiles = yaml.safe_load(f)
    
    if profile_name not in profiles['profiles']:
        print(f"Error: Profile '{profile_name}' not found")
        sys.exit(1)
    
    profile = profiles['profiles'][profile_name]
    allowed_services = profile['services']
    
    # Build Claude Desktop configuration
    config = {
        "mcpServers": {}
    }
    
    # Add each allowed service
    for service_id in allowed_services:
        if service_id == "*":
            # Add all services
            for svc_id, svc_info in registry['services'].items():
                add_service_to_config(config, svc_id, svc_info)
        else:
            # Add specific service
            if service_id in registry['services']:
                add_service_to_config(config, service_id, registry['services'][service_id])
    
    # Output configuration
    if output_file:
        with open(output_file, 'w') as f:
            json.dump(config, f, indent=2)
        print(f"Configuration saved to: {output_file}")
    else:
        print(json.dumps(config, indent=2))

def add_service_to_config(config, service_id, service_info):
    """Add a service to Claude Desktop config"""
    
    # For remote services, use a proxy command
    if service_info.get('location') == 'workhorse':
        config['mcpServers'][service_id] = {
            "command": "node",
            "args": [
                "/usr/local/bin/mcp-proxy",
                f"http://10.0.0.2:{service_info['port']}"
            ]
        }
    else:
        # Local services use their command directly
        command_parts = service_info.get('command', '').split()
        if command_parts:
            config['mcpServers'][service_id] = {
                "command": command_parts[0],
                "args": command_parts[1:] if len(command_parts) > 1 else []
            }
    
    # Add environment variables if needed
    if 'env_vars' in service_info:
        config['mcpServers'][service_id]['env'] = {
            var: f"${{{var}}}" for var in service_info['env_vars']
        }

if __name__ == "__main__":
    main()