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
