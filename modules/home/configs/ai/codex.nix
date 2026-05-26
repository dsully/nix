{
  ai,
  config,
  lib,
  perSystem,
  ...
}: let
  codexAgentRoles = lib.mapAttrs (_: description: {inherit description;}) ai.descriptions;

  # The home-manager Codex module merges `settings.mcp_servers` over entries
  # generated from `programs.mcp.servers`, but the merge is shallow per server
  # name, so each entry here must be complete rather than a partial overlay.
  mcpServersAutoApprove = ai.permissions.codex.mcpServers ai.mcpServers;
in {
  programs.codex = {
    enable = true;

    package = perSystem.llm-agents.codex;
    enableMcpIntegration = true;

    context = ''
      ${builtins.readFile ./AGENTS.md}

      ${builtins.readFile "${perSystem.llm-agents.rtk}/libexec/rtk/hooks/codex/rtk-awareness.md"}
    '';

    settings = {
      agents = codexAgentRoles;
      analytics.enabled = false;
      approval_policy = "on-request";

      features = {
        hooks = true;
        multi_agent = true;
        tool_search = true;
      };

      feedback.enabled = false;

      mcp_servers = mcpServersAutoApprove;
      model = "gpt-5.5";
      model_reasoning_effort = "medium";

      projects = {
        "${config.home.homeDirectory}/dev" = {
          trust_level = "trusted";
        };
        "${config.xdg.configHome}/nix" = {
          trust_level = "trusted";
        };
        "${config.xdg.configHome}/nvim" = {
          trust_level = "trusted";
        };
      };

      sandbox_mode = "workspace-write";
      sandbox_workspace_write.network_access = true;

      tui.status_line = [
        "model-with-reasoning"
        "current-dir"
        "context-remaining"
        "context-used"
        "five-hour-limit"
      ];
    };

    # Written to a separate file so Codex's interactively-managed
    # `default.rules` smart-approvals allow-list is left untouched.
    rules.common = ai.permissions.codex.rules.common;
  };
}
