{
  ai,
  lib,
  perSystem,
  ...
}: let
  codexAgentRoles = lib.mapAttrs (_: description: {inherit description;}) ai.descriptions;

  # Auto-approve tool calls for every MCP server. The home-manager codex module
  # merges `settings.mcp_servers` over the entries generated from
  # `programs.mcp.servers`, but the merge is shallow per server name, so each
  # entry here must be complete (command/args/enabled) rather than a partial
  # overlay. Deriving from `ai.mcpServers` keeps this isolated to Codex without
  # leaking the codex-only `default_tools_approval_mode` key into the shared
  # claude-code / opencode MCP configs.
  mcpServersAutoApprove =
    lib.mapAttrs (
      _: server:
        (lib.removeAttrs server ["disabled"])
        // {
          enabled = !(server.disabled or false);
          default_tools_approval_mode = "auto";
        }
    )
    ai.mcpServers;
in {
  # home-manager doesn't write here. :(
  # home.sessionVariables.CODEX_HOME = "${config.xdg.configHome}/codex";

  programs.codex = {
    enable = true;

    package = perSystem.llm-agents.codex;
    enableMcpIntegration = true;

    context = ./AGENTS.md;

    settings = {
      agents = codexAgentRoles;
      approval_policy = "on-request";

      features = {
        multi_agent = true;
        tool_search = true;
      };

      model = "gpt-5.5";
      model_reasoning_effort = "medium";

      sandbox_mode = "workspace-write";
      sandbox_workspace_write.network_access = true;

      mcp_servers = mcpServersAutoApprove;
    };
  };
}
