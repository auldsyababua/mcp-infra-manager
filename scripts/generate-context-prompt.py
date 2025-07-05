#!/usr/bin/env python3
"""
Generate MCP context prompt for context-engineer-cli-tool
"""
import sys
import yaml
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: generate-context-prompt.py <profile>")
        sys.exit(1)
    
    profile_name = sys.argv[1]
    
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
    
    # Build prompt
    prompt = "\nYou have access to the following MCP services:\n\n"
    
    # Collect services
    services_to_include = []
    
    for service_id in allowed_services:
        if service_id == "*":
            # Add all non-restricted services
            for svc_id, svc_info in registry['services'].items():
                if not svc_info.get('requires_auth', False):
                    services_to_include.append((svc_id, svc_info))
        else:
            # Add specific service
            if service_id in registry['services']:
                services_to_include.append((service_id, registry['services'][service_id]))
    
    # Format services by category
    categories = {}
    for service_id, service_info in services_to_include:
        category = service_info.get('category', 'other')
        if category not in categories:
            categories[category] = []
        categories[category].append((service_id, service_info))
    
    # Output by category
    category_order = ['core', 'search', 'ai-context', 'project', 'development', 'other']
    
    for category in category_order:
        if category in categories:
            prompt += f"### {category.replace('-', ' ').title()} Services\n\n"
            
            for service_id, service_info in categories[category]:
                location = service_info.get('location', 'local')
                host = "10.0.0.2" if location == 'workhorse' else "localhost"
                
                prompt += f"**{service_info['name']}** (`{service_id}`)\n"
                prompt += f"- URL: http://{host}:{service_info['port']}\n"
                prompt += f"- Purpose: {service_info['description']}\n"
                
                # Add any special notes
                if service_info.get('requires_auth'):
                    prompt += f"- Note: Requires authentication token\n"
                
                prompt += "\n"
    
    prompt += "Only use the MCP services listed above. Do not attempt to access any other services.\n"
    
    print(prompt)

if __name__ == "__main__":
    main()