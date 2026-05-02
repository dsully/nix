# All agent, command, and plugin definitions for AI tools.
{
  aiLib,
  lib,
  ...
}: let
  inherit (aiLib) cpo mkAgent mkCommand parseAgent ws;

  # Map of plugin directory -> { commandName = { file, description, ... }; }
  wsPluginCommands = {
    systems-programming = {
      rust-project = {
        file = "rust-project.md";
        description = "Scaffold production-ready Rust project structures";
      };
    };
    code-refactoring = {
      tech-debt = {
        file = "tech-debt.md";
        description = "Analyze and remediate technical debt";
      };
      refactor-clean = {
        file = "refactor-clean.md";
        description = "Refactor code for cleanliness and maintainability";
      };
    };
  };

  wsCommands =
    lib.foldlAttrs (
      acc: plugin: commandAttrs:
        acc
        // lib.mapAttrs (
          _name: cmdDef:
            mkCommand {
              file = "${ws}/${plugin}/commands/${cmdDef.file}";
              inherit (cmdDef) description;
            }
        )
        commandAttrs
    ) {}
    wsPluginCommands;

  # Map of plugin directory -> { agentName = "filename.md"; }
  wsPluginAgents = {
    backend-development = {
      backend-architect = "backend-architect.md";
      performance-engineer = "performance-engineer.md";
      tdd-orchestrator = "tdd-orchestrator.md";
      test-automator = "test-automator.md";
    };
    cloud-infrastructure = {
      cloud-architect = "cloud-architect.md";
      deployment-engineer = "deployment-engineer.md";
      kubernetes-architect = "kubernetes-architect.md";
    };
    code-documentation = {
      docs-architect = "docs-architect.md";
    };
    # comprehensive-review = {
    #   code-reviewer = "code-reviewer.md";
    # };
    data-engineering = {
      data-engineer = "data-engineer.md";
    };
    debugging-toolkit = {
      debugger = "debugger.md";
      dx-optimizer = "dx-optimizer.md";
    };
    distributed-debugging = {
      devops-troubleshooter = "devops-troubleshooter.md";
      error-detective = "error-detective.md";
    };
    observability-monitoring = {
      database-optimizer = "database-optimizer.md";
      observability-engineer = "observability-engineer.md";
    };
    python-development = {
      python-pro = "python-pro.md";
    };
    systems-programming = {
      # golang-pro = "golang-pro.md";
      rust-pro = "rust-pro.md";
    };
  };

  # Parse each agent file exactly once: { name = { description, body }; }
  wsParsed =
    lib.foldlAttrs (
      acc: plugin: agentAttrs:
        acc
        // lib.mapAttrs (
          _name: file: parseAgent "${ws}/${plugin}/agents/${file}"
        )
        agentAttrs
    ) {}
    wsPluginAgents;

  wsAgents = lib.mapAttrs (_: p: mkAgent {inherit (p) description body;}) wsParsed;
  wsDescriptions = lib.mapAttrs (_: p: p.description) wsParsed;

  cpoSpecs = {
    anthropic-code-simplifier = {
      file = "${cpo}/code-simplifier/agents/code-simplifier.md";
      description = "Simplifies and refines code for clarity, consistency, and maintainability while preserving all functionality";
    };
    # anthropic-code-architect = {
    #   file = "${cpo}/feature-dev/agents/code-architect.md";
    #   description = "Designs feature architectures by analyzing codebase patterns, providing implementation blueprints with files to create/modify, component designs, and data flows";
    #   color = "success";
    # };
    anthropic-code-explorer = {
      file = "${cpo}/feature-dev/agents/code-explorer.md";
      description = "Deeply analyzes codebase features by tracing execution paths, mapping architecture layers, understanding patterns, and documenting dependencies";
      color = "warning";
    };
    anthropic-code-reviewer = {
      file = "${cpo}/feature-dev/agents/code-reviewer.md";
      description = "Reviews code for bugs, logic errors, security vulnerabilities, and adherence to project conventions using confidence-based filtering";
      color = "error";
    };
    # anthropic-pr-code-reviewer = {
    #   file = "${cpo}/pr-review-toolkit/agents/code-reviewer.md";
    #   description = "Reviews pull request code for adherence to project guidelines, style guides, and best practices before committing or creating PRs";
    #   color = "success";
    # };
    # anthropic-pr-code-simplifier = {
    #   file = "${cpo}/pr-review-toolkit/agents/code-simplifier.md";
    #   description = "Automatically simplifies code after writing or modifying, following project best practices while retaining all functionality";
    # };
    anthropic-comment-analyzer = {
      file = "${cpo}/pr-review-toolkit/agents/comment-analyzer.md";
      description = "Analyzes code comments for accuracy, completeness, and long-term maintainability to prevent comment rot and technical debt";
      color = "success";
    };
    # anthropic-pr-test-analyzer = {
    #   file = "${cpo}/pr-review-toolkit/agents/pr-test-analyzer.md";
    #   description = "Reviews pull requests for test coverage quality and completeness, identifying critical gaps in test scenarios";
    #   color = "info";
    # };
    anthropic-silent-failure-hunter = {
      file = "${cpo}/pr-review-toolkit/agents/silent-failure-hunter.md";
      description = "Identifies silent failures, inadequate error handling, and inappropriate fallback behavior in code changes";
      color = "warning";
    };
    anthropic-type-design-analyzer = {
      file = "${cpo}/pr-review-toolkit/agents/type-design-analyzer.md";
      description = "Analyzes type design for encapsulation quality, invariant expression, usefulness, and enforcement with quantitative ratings";
      color = "accent";
    };
    # anthropic-conversation-analyzer = {
    #   file = "${cpo}/hookify/agents/conversation-analyzer.md";
    #   description = "Analyzes conversation transcripts to find problematic behaviors and suggest preventive hooks";
    #   color = "warning";
    # };
  };

  cpoAgents = lib.mapAttrs (_: mkAgent) cpoSpecs;
  cpoDescriptions = lib.mapAttrs (_: spec: spec.description) cpoSpecs;

  wsEnabledPlugins =
    lib.mapAttrs' (
      p: _: lib.nameValuePair "${p}@claude-code-workflows" (lib.mkDefault true)
    )
    wsPluginAgents;
in {
  agents = wsAgents // cpoAgents;
  commands = wsCommands;
  descriptions = wsDescriptions // cpoDescriptions;
  enabledPlugins = wsEnabledPlugins;
}
