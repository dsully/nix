{
  aiAgents,
  aiLib,
  lib,
  perSystem,
  ...
}: let
  codexAgentRoles = lib.mapAttrs (_: description: {inherit description;}) aiAgents.descriptions;
in {
  programs.codex = {
    enable = true;

    package = perSystem.llm-agents.codex;
    enableMcpIntegration = false;

    context = ./AGENTS.md;

    settings = {
      agents = codexAgentRoles;
      approval_policy = "on-request";

      features = {
        multi_agent = true;
        tool_search = true;
      };

      mcp_servers.agentgateway.url = aiLib.agentgateway.mcpHttpUrl;

      model = "gpt-5.5";
      model_reasoning_effort = "medium";
    };
  };
}
