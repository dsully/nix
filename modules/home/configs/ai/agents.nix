# All agent, command, and plugin definitions for AI tools.
{
  inputs,
  aiLib,
  lib,
  ...
}: let
  inherit (aiLib) agentDescription mkAI;
  cpo = "${inputs.claude-plugins-official}/plugins";
  ws = "${inputs.wshobson-agents}/plugins";

  aiSources = [
    {
      base = ws;
      name = "backend-development";
      plugin = "backend-development@claude-code-workflows";
      agents = ["backend-architect" "performance-engineer" "tdd-orchestrator" "test-automator"];
    }
    {
      base = ws;
      name = "code-refactoring";
      commands = ["tech-debt" "refactor-clean"];
    }
    {
      base = ws;
      name = "debugging-toolkit";
      plugin = "debugging-toolkit@claude-code-workflows";
      agents = ["debugger" "dx-optimizer"];
    }
    {
      base = ws;
      name = "python-development";
      plugin = "python-development@claude-code-workflows";
      agents = ["python-pro"];
    }
    {
      base = ws;
      name = "systems-programming";
      plugin = "systems-programming@claude-code-workflows";
      agents = ["rust-pro"];
      commands = ["rust-project"];
    }
    {
      base = cpo;
      name = "code-simplifier";
      prefix = "anthropic-";
      agents = ["code-simplifier"];
    }
    {
      base = cpo;
      name = "feature-dev";
      prefix = "anthropic-";
      agents = ["code-explorer" "code-reviewer"];
    }
    {
      base = cpo;
      name = "pr-review-toolkit";
      prefix = "anthropic-";
      agents = ["comment-analyzer" "silent-failure-hunter" "type-design-analyzer"];
    }
  ];

  ai = mkAI aiSources;

  inherit (ai) agents commands;
  descriptions = lib.mapAttrs (_: agentDescription) agents;

  enabledPlugins = lib.genAttrs (
    lib.catAttrs "plugin" aiSources
  ) (_: lib.mkDefault true);
in {
  inherit agents commands descriptions;
  inherit enabledPlugins;
}
