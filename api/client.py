"""
MCP Infrastructure Manager Client Library
For use by context-engineer-cli-tool and other applications
"""
import subprocess
import yaml
import json
from pathlib import Path
from typing import List, Dict, Optional, Any

class MCPInfraClient:
    """Client for interacting with MCP Infrastructure Manager"""
    
    def __init__(self, base_path: Optional[str] = None):
        """
        Initialize the client
        
        Args:
            base_path: Path to mcp-infra-manager directory. If None, tries to find it.
        """
        if base_path:
            self.base_path = Path(base_path)
        else:
            # Try common locations
            locations = [
                Path.home() / "mcp-infra-manager",
                Path("/opt/mcp-infra-manager"),
                Path(__file__).parent.parent  # If imported from within the project
            ]
            
            for loc in locations:
                if loc.exists() and (loc / "registry/services.yaml").exists():
                    self.base_path = loc
                    break
            else:
                raise RuntimeError("Could not find mcp-infra-manager installation")
        
        self.registry_file = self.base_path / "registry/services.yaml"
        self.profiles_file = self.base_path / "profiles/access-profiles.yaml"
        self.manager_script = self.base_path / "bin/mcp-manager"
        
        # Load configurations
        self._load_configs()
    
    def _load_configs(self):
        """Load registry and profiles"""
        with open(self.registry_file) as f:
            self.registry = yaml.safe_load(f)
        
        with open(self.profiles_file) as f:
            self.profiles = yaml.safe_load(f)
    
    def reload_configs(self):
        """Reload configurations (useful if they've been updated)"""
        self._load_configs()
    
    def list_services(self) -> Dict[str, Any]:
        """Get all registered services"""
        return self.registry['services']
    
    def list_profiles(self) -> Dict[str, Any]:
        """Get all access profiles"""
        return self.profiles['profiles']
    
    def get_services_for_profile(self, profile: str) -> List[Dict[str, Any]]:
        """
        Get services accessible by a specific profile
        
        Args:
            profile: Profile name
            
        Returns:
            List of service dictionaries with connection details
        """
        if profile not in self.profiles['profiles']:
            raise ValueError(f"Profile '{profile}' not found")
        
        profile_config = self.profiles['profiles'][profile]
        allowed_services = profile_config['services']
        
        services = []
        
        for service_id in allowed_services:
            if service_id == "*":
                # Add all non-restricted services
                for svc_id, svc_info in self.registry['services'].items():
                    if not svc_info.get('requires_auth', False):
                        services.append(self._format_service(svc_id, svc_info))
            else:
                # Add specific service
                if service_id in self.registry['services']:
                    svc_info = self.registry['services'][service_id]
                    services.append(self._format_service(service_id, svc_info))
        
        return services
    
    def _format_service(self, service_id: str, service_info: Dict) -> Dict[str, Any]:
        """Format service information for clients"""
        location = service_info.get('location', 'local')
        host = "10.0.0.2" if location == 'workhorse' else "localhost"
        
        return {
            'id': service_id,
            'name': service_info['name'],
            'description': service_info['description'],
            'url': f"http://{host}:{service_info['port']}",
            'port': service_info['port'],
            'category': service_info.get('category', 'other'),
            'location': location,
            'requires_auth': service_info.get('requires_auth', False),
            'env_vars': service_info.get('env_vars', [])
        }
    
    def generate_prompt_section(self, profile: str, include_categories: bool = True) -> str:
        """
        Generate MCP section for Claude prompt
        
        Args:
            profile: Profile name
            include_categories: Whether to group by categories
            
        Returns:
            Formatted prompt section
        """
        services = self.get_services_for_profile(profile)
        
        if not services:
            return "\nNo MCP services are available for this task."
        
        prompt = "\nYou have access to the following MCP services:\n\n"
        
        if include_categories:
            # Group by category
            categories = {}
            for svc in services:
                cat = svc['category']
                if cat not in categories:
                    categories[cat] = []
                categories[cat].append(svc)
            
            # Output by category
            category_order = ['core', 'search', 'ai-context', 'project', 'development', 'other']
            
            for category in category_order:
                if category in categories:
                    prompt += f"### {category.replace('-', ' ').title()} Services\n\n"
                    
                    for svc in categories[category]:
                        prompt += self._format_service_prompt(svc)
        else:
            # Simple list
            for svc in services:
                prompt += self._format_service_prompt(svc)
        
        prompt += "Only use the MCP services listed above. Do not attempt to access any other services.\n"
        
        return prompt
    
    def _format_service_prompt(self, service: Dict) -> str:
        """Format a single service for the prompt"""
        lines = [
            f"**{service['name']}** (`{service['id']}`)",
            f"- URL: {service['url']}",
            f"- Purpose: {service['description']}"
        ]
        
        if service.get('requires_auth'):
            lines.append("- Note: Requires authentication token")
        
        return "\n".join(lines) + "\n\n"
    
    def determine_profile(self, task: str, project_context: Dict[str, Any]) -> str:
        """
        Automatically determine the best profile based on context
        
        Args:
            task: Task description
            project_context: Context information (project path, etc.)
            
        Returns:
            Profile name
        """
        # Check selection rules
        for rule in self.profiles.get('selection_rules', []):
            condition = rule['condition']
            
            # Check project path condition
            if 'project_path_contains' in condition:
                project_path = project_context.get('project_path', '')
                if condition['project_path_contains'] in project_path:
                    return rule['profile']
            
            # Check task content condition
            if 'task_contains' in condition:
                task_lower = task.lower()
                if any(keyword in task_lower for keyword in condition['task_contains']):
                    return rule['profile']
            
            # Check context condition
            if 'context_contains' in condition:
                context_str = str(project_context).lower()
                if any(keyword in context_str for keyword in condition['context_contains']):
                    return rule['profile']
            
            # Default condition
            if condition.get('default'):
                return rule['profile']
        
        return 'default'
    
    def check_service_status(self, service_id: str) -> Dict[str, Any]:
        """Check if a service is running"""
        try:
            result = subprocess.run(
                [str(self.manager_script), "status", service_id],
                capture_output=True,
                text=True
            )
            
            return {
                'service': service_id,
                'running': result.returncode == 0,
                'output': result.stdout
            }
        except Exception as e:
            return {
                'service': service_id,
                'running': False,
                'error': str(e)
            }
    
    def start_service(self, service_id: str) -> bool:
        """Start a service"""
        try:
            result = subprocess.run(
                [str(self.manager_script), "start", service_id],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except:
            return False
    
    def generate_claude_desktop_config(self, profile: str) -> Dict[str, Any]:
        """Generate Claude Desktop configuration for a profile"""
        services = self.get_services_for_profile(profile)
        
        config = {"mcpServers": {}}
        
        for svc in services:
            # For remote services, use a proxy
            if svc['location'] == 'workhorse':
                config['mcpServers'][svc['id']] = {
                    "command": "node",
                    "args": ["/usr/local/bin/mcp-proxy", svc['url']]
                }
            else:
                # Local services use their command
                service_info = self.registry['services'][svc['id']]
                command_parts = service_info.get('command', '').split()
                if command_parts:
                    config['mcpServers'][svc['id']] = {
                        "command": command_parts[0],
                        "args": command_parts[1:] if len(command_parts) > 1 else []
                    }
            
            # Add environment variables
            if svc['env_vars']:
                config['mcpServers'][svc['id']]['env'] = {
                    var: f"${{{var}}}" for var in svc['env_vars']
                }
        
        return config

# Convenience functions for context-engineer-cli-tool
def get_mcp_prompt_for_task(task: str, project_context: Dict[str, Any]) -> str:
    """
    Quick function to get MCP prompt section for a task
    
    Args:
        task: Task description
        project_context: Context information
        
    Returns:
        Formatted MCP prompt section
    """
    client = MCPInfraClient()
    profile = client.determine_profile(task, project_context)
    return client.generate_prompt_section(profile)