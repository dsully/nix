{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  aiLib = import ./lib.nix {inherit config inputs lib my perSystem pkgs;};
  aiAgents = import ./agents.nix {inherit aiLib lib;};

  # Build codex agent roles from the shared agent definitions.
  # Each agent gets a description extracted from the markdown frontmatter.
  codexAgentRoles =
    lib.mapAttrs (_name: markdown: let
      parts = lib.splitString "description: " markdown;
      desc =
        if builtins.length parts >= 2
        then builtins.head (lib.splitString "\n" (builtins.elemAt parts 1))
        else "Specialized development agent";
    in {
      description = desc;
    })
    aiAgents.agents;
in {
  programs.codex = {
    enable = true;

    package = perSystem.llm-agents.codex;
    enableMcpIntegration = true;

    custom-instructions = builtins.readFile ./AGENTS.md;

    settings = {
      agents = codexAgentRoles;
      approval_policy = "on-request";

      features = {
        multi_agent = true;
        tool_search = true;
      };

      model = "gpt-5.4";
      model_reasoning_effort = "medium";
    };

    skills = {
      astral-uv = "${aiLib.acp}/plugins/astral/skills/uv";
      astral-ruff = "${aiLib.acp}/plugins/astral/skills/ruff";
      astral-ty = "${aiLib.acp}/plugins/astral/skills/ty";
    };
  };
}
