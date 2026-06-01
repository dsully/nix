{
  ai,
  config,
  lib,
  mutableConfig,
  perSystem,
  ...
}: let
  codexAgentRoles = lib.mapAttrs (_: description: {inherit description;}) ai.descriptions;

  # The home-manager Codex module merges `settings.mcp_servers` over entries
  # generated from `programs.mcp.servers`, but the merge is shallow per server
  # name, so each entry here must be complete rather than a partial overlay.
  mcpServersAutoApprove = ai.permissions.codex.mcpServers config.programs.mcp.servers;
  configPath = "${config.xdg.configHome}/codex/config.toml";
  homeFileConfigPath = lib.removePrefix config.home.homeDirectory configPath;
in {
  imports = [
    (mutableConfig.toml {
      name = "codex";
      target = "codex/config.toml";
      managed = config.programs.codex.settings;
    })
  ];

  home = {
    packages = with perSystem.llm-agents; [
      codex-acp
    ];
  };

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
      hide_agent_reasoning = true;

      hooks = ai.hooks.codex;
      mcp_servers = mcpServersAutoApprove;
      model = "gpt-5.5";

      model_reasoning_effort = "medium";
      model_reasoning_summary = "none";
      model_verbosity = "low";
      personality = "pragmatic";

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
      sandbox_workspace_write = {
        exclude_tmpdir_env_var = false; # Allow $TMPDIR
        exclude_slash_tmp = false;
        network_access = true;
      };

      show_raw_agent_reasoning = false;

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

  # The module would symlink config.toml read-only into the /nix/store, which
  # prevents Codex from persisting interactive trust decisions.
  home.file."${homeFileConfigPath}".enable = lib.mkForce false;
}
