{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  acp = "${inputs.astral-claude-plugins}";
  cpo = "${inputs.claude-plugins-official}/plugins";
  ws = "${inputs.wshobson-agents}/plugins";

  # Strip YAML frontmatter from a markdown file, returning only the body.
  stripFrontmatter = file: let
    raw = builtins.readFile file;
    parts = lib.splitString "---\n" raw;
  in
    if builtins.length parts >= 3
    then lib.concatStringsSep "" (lib.drop 2 parts)
    else raw;

  # Build an opencode agent markdown string with new frontmatter + original body.
  mkAgent = {
    file,
    description,
    model ? null,
    color ? null,
  }: let
    modelLine = lib.optionalString (model != null) "model: ${model}\n";
    colorLine = lib.optionalString (color != null) "color: ${color}\n";
  in ''
    ---
    description: ${description}
    mode: all
    ${modelLine}${colorLine}---
    ${stripFrontmatter file}'';

  # Map of plugin directory -> { agentName = "filename.md"; }
  wsPluginAgents = {
    application-performance = {
      app-observability-engineer = "observability-engineer.md";
      app-performance-engineer = "performance-engineer.md";
    };
    backend-development = {
      backend-architect = "backend-architect.md";
      event-sourcing-architect = "event-sourcing-architect.md";
    };
    cloud-infrastructure = {
      cloud-architect = "cloud-architect.md";
      deployment-engineer = "deployment-engineer.md";
      hybrid-cloud-architect = "hybrid-cloud-architect.md";
      service-mesh-expert = "service-mesh-expert.md";
    };
    code-documentation = {
      docs-architect = "docs-architect.md";
      tutorial-engineer = "tutorial-engineer.md";
    };
    code-refactoring = {
      legacy-modernizer = "legacy-modernizer.md";
      refactoring-reviewer = "code-reviewer.md";
    };
    code-review-ai.architect-review = "architect-review.md";
    codebase-cleanup.cleanup-test-automator = "test-automator.md";
    data-engineering.data-engineer = "data-engineer.md";
    debugging-toolkit = {
      debugger = "debugger.md";
      dx-optimizer = "dx-optimizer.md";
    };
    error-diagnostics.error-detective = "error-detective.md";
    incident-response = {
      devops-troubleshooter = "devops-troubleshooter.md";
      incident-responder = "incident-responder.md";
    };
    observability-monitoring = {
      database-optimizer = "database-optimizer.md";
      network-engineer = "network-engineer.md";
      obs-performance-engineer = "performance-engineer.md";
      observability-engineer = "observability-engineer.md";
    };
    performance-testing-review = {
      perf-performance-engineer = "performance-engineer.md";
      perf-test-automator = "test-automator.md";
    };
    python-development = {
      fastapi-pro = "fastapi-pro.md";
      python-pro = "python-pro.md";
    };
    systems-programming = {
      golang-pro = "golang-pro.md";
      rust-pro = "rust-pro.md";
    };
    tdd-workflows = {
      tdd-code-reviewer = "code-reviewer.md";
      tdd-orchestrator = "tdd-orchestrator.md";
    };
    unit-testing.test-automator = "test-automator.md";
  };

  # Generate wshobson agents with proper opencode frontmatter
  wsAgents =
    lib.foldlAttrs (
      acc: plugin: agentAttrs:
        acc
        // lib.mapAttrs (
          _name: file:
            mkAgent {
              file = "${ws}/${plugin}/agents/${file}";
              description = let
                raw = builtins.readFile "${ws}/${plugin}/agents/${file}";
                parts = lib.splitString "description: " raw;
                desc =
                  if builtins.length parts >= 2
                  then builtins.head (lib.splitString "\n" (builtins.elemAt parts 1))
                  else "Specialized development agent";
              in
                desc;
            }
        )
        agentAttrs
    ) {}
    wsPluginAgents;

  # Anthropic claude-plugins-official agents
  cpoAgents = {
    anthropic-code-simplifier = mkAgent {
      file = "${cpo}/code-simplifier/agents/code-simplifier.md";
      description = "Simplifies and refines code for clarity, consistency, and maintainability while preserving all functionality";
    };
    anthropic-code-architect = mkAgent {
      file = "${cpo}/feature-dev/agents/code-architect.md";
      description = "Designs feature architectures by analyzing codebase patterns, providing implementation blueprints with files to create/modify, component designs, and data flows";
      color = "success";
    };
    anthropic-code-explorer = mkAgent {
      file = "${cpo}/feature-dev/agents/code-explorer.md";
      description = "Deeply analyzes codebase features by tracing execution paths, mapping architecture layers, understanding patterns, and documenting dependencies";
      color = "warning";
    };
    anthropic-code-reviewer = mkAgent {
      file = "${cpo}/feature-dev/agents/code-reviewer.md";
      description = "Reviews code for bugs, logic errors, security vulnerabilities, and adherence to project conventions using confidence-based filtering";
      color = "error";
    };
    anthropic-pr-code-reviewer = mkAgent {
      file = "${cpo}/pr-review-toolkit/agents/code-reviewer.md";
      description = "Reviews pull request code for adherence to project guidelines, style guides, and best practices before committing or creating PRs";
      color = "success";
    };
    anthropic-pr-code-simplifier = mkAgent {
      file = "${cpo}/pr-review-toolkit/agents/code-simplifier.md";
      description = "Automatically simplifies code after writing or modifying, following project best practices while retaining all functionality";
    };
    anthropic-comment-analyzer = mkAgent {
      file = "${cpo}/pr-review-toolkit/agents/comment-analyzer.md";
      description = "Analyzes code comments for accuracy, completeness, and long-term maintainability to prevent comment rot and technical debt";
      color = "success";
    };
    anthropic-pr-test-analyzer = mkAgent {
      file = "${cpo}/pr-review-toolkit/agents/pr-test-analyzer.md";
      description = "Reviews pull requests for test coverage quality and completeness, identifying critical gaps in test scenarios";
      color = "info";
    };
    anthropic-silent-failure-hunter = mkAgent {
      file = "${cpo}/pr-review-toolkit/agents/silent-failure-hunter.md";
      description = "Identifies silent failures, inadequate error handling, and inappropriate fallback behavior in code changes";
      color = "warning";
    };
    anthropic-type-design-analyzer = mkAgent {
      file = "${cpo}/pr-review-toolkit/agents/type-design-analyzer.md";
      description = "Analyzes type design for encapsulation quality, invariant expression, usefulness, and enforcement with quantitative ratings";
      color = "accent";
    };
    anthropic-conversation-analyzer = mkAgent {
      file = "${cpo}/hookify/agents/conversation-analyzer.md";
      description = "Analyzes conversation transcripts to find problematic behaviors and suggest preventive hooks";
      color = "warning";
    };
  };

  agents = wsAgents // cpoAgents;

  # Collect all wshobson skills by scanning plugin directories.
  wsSkills = let
    plugins = builtins.attrNames (
      lib.filterAttrs (_: v: v == "directory")
      (builtins.readDir "${inputs.wshobson-agents}/plugins")
    );
  in
    builtins.foldl' (
      acc: plugin: let
        skillsDir = "${ws}/${plugin}/skills";
        hasSkills = builtins.pathExists skillsDir;
        skillNames =
          if hasSkills
          then
            builtins.attrNames (
              lib.filterAttrs (_: v: v == "directory")
              (builtins.readDir skillsDir)
            )
          else [];
      in
        acc
        // builtins.listToAttrs (
          map (skill: lib.nameValuePair skill "${skillsDir}/${skill}") skillNames
        )
    ) {}
    plugins;

  # Generate wshobson enabledPlugins from wsPluginAgents keys
  wsEnabledPlugins =
    lib.mapAttrs' (
      p: _: lib.nameValuePair "${p}@claude-code-workflows" (lib.mkDefault true)
    )
    wsPluginAgents;

  lsp = {
    bash = {
      command = lib.getExe pkgs.bash-language-server;
      args = ["start"];
    };
    helm = {
      command = lib.getExe pkgs.helm-ls;
      args = ["serve" "--stdio"];
    };
    go = {
      command = lib.getExe pkgs.gopls;
    };
    lua = {
      command = lib.getExe my.pkgs.emmylua-ls;
    };
    nix = {
      command = lib.getExe pkgs.nil;
    };
    rust = {
      command = "rust-analyzer";
      args = [
        "--disable-build-scripts"
      ];
    };
    toml = {
      command = lib.getExe pkgs.tombi;
      args = [
        "lsp"
      ];
    };
    typescript = {
      command = lib.getExe pkgs.typescript-go;
      args = [
        "--lsp"
        "--stdio"
      ];
    };
  };

  # For crush: add enabled = true to each LSP config
  # lspWithEnabled = lib.mapAttrs (_: v: v // {enabled = true;}) (removeAttrs lsp ["bash"]);

  # For opencode: transform to { command = [...], extensions = [...] }
  lspExtensions = {
    helm = [".tpl" ".yaml"];
    lua = [".lua"];
    nix = [".nix"];
    rust = [".rs"];
    toml = [".toml"];
    typescript = [".ts" ".tsx" ".js" ".jsx"];
  };

  mcpServers = {
    ast-grep = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["--from" "git+https://github.com/ast-grep/ast-grep-mcp" "ast-grep-server"];
    };
    filesystem = {
      command = lib.getExe my.pkgs.rust-mcp-filesystem;
      args = [config.home.homeDirectory "--allow-write"];
    };
    git = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["git-mcp"];
    };
    rime = {
      command = lib.getExe my.pkgs.rime;
      args = ["stdio"];
    };
    rust-analyzer = {
      command = lib.getExe my.pkgs.mcp-rust-analyzer;
    };
  };

  mcpServersWithType = lib.mapAttrs (_: v: v // {type = "stdio";}) mcpServers;

  models = {
    large = {
      model = "claude-opus-4-6";
      provider = "anthropic";
      max_tokens = 1000000;
      reasoning_effort = "medium";
    };
    medium = {
      model = "claude-sonnet-4-5-20250929";
      provider = "anthropic";
      max_tokens = 200000;
      reasoning_effort = "medium";
    };
    small = {
      model = "claude-sonnet-4-20250514";
      provider = "anthropic";
      max_tokens = 5000;
      reasoning_effort = "low";
    };
  };

  opencodeLsp = lib.mapAttrs (name: v: {
    command = [v.command] ++ (v.args or []);
    extensions = lspExtensions.${name};
  }) (lib.filterAttrs (n: _: lspExtensions ? ${n}) lsp);
  # For opencode: prefix with provider
  # opencodeModel = m: "${m.provider}/${m.model}";
in {
  imports = [
    inputs.charmbracelet-nur.homeModules.crush
  ];

  home = {
    sessionVariables = {
      OPENCODE_EXPERIMENTAL_LSP_TY = "1";
    };

    packages =
      (
        with perSystem.llm-agents; [
          ccstatusline
          ccusage-opencode
          claude-code-acp
          # codex
          # gemini-cli
          goose-cli
        ]
      )
      ++ (with my.pkgs; [
        cai
        ccometixline
        crates-mcp
        git-ai-commit
        infiniloom
        mcp-rust-analyzer
        rust-mcp-filesystem
        rust-mcp-server
        turbo-commit
      ]);
  };

  programs = {
    # crush = {
    #   enable = true;
    #
    #   settings = {
    #     lsp = lspWithEnabled;
    #     mcp = mcpServersWithType;
    #
    #     inherit models;
    #
    #     permissions = {
    #       allowed_tools = [
    #         "edit"
    #         "grep"
    #         "ls"
    #         "view"
    #         "mcp_context7_get-library-doc"
    #       ];
    #     };
    #
    #     providers = {
    #       anthropic = {
    #         id = "anthropic";
    #         name = "Anthropic";
    #         type = "anthropic";
    #         api_key = "Bearer $(anthropic-api-key)";
    #         extra_headers = {
    #           anthropic-version = "2023-06-01";
    #           anthropic-beta = "oauth-2025-04-20";
    #         };
    #         system_prompt_prefix = "You are Claude Code, Anthropic's official CLI for Claude.";
    #       };
    #     };
    #   };
    # };

    claude-code = {
      enable = true;
      package = perSystem.llm-agents.claude-code;

      inherit agents;

      memory.source = ./configs/ai/AGENTS.md;

      settings = {
        inherit (models.large) model;

        autoUpdates = false;
        enableAllProjectMcpServers = false;
        enableMcpIntegration = true;
        includeCoAuthoredBy = false;

        extraKnownMarketplaces = {
          "astral-sh" = {
            source = {
              source = "directory";
              path = "${acp}";
            };
          };
          claude-code-workflows = {
            source = {
              source = "directory";
              path = "${inputs.wshobson-agents}";
            };
          };
        };

        enabledPlugins =
          {
            "astral@astral-sh" = lib.mkDefault true;
            "code-review@claude-plugins-official" = lib.mkDefault true;
            "code-simplifier@claude-plugins-official" = lib.mkDefault true;
            "commit-commands@claude-plugins-official" = lib.mkDefault true;
            "feature-dev@claude-plugins-official" = lib.mkDefault true;
            "pr-review-toolkit@claude-plugins-official" = lib.mkDefault true;
            "ralph-loop@claude-plugins-official" = lib.mkDefault true;
            "rust-analyzer-lsp@claude-plugins-official" = lib.mkDefault true;
          }
          // wsEnabledPlugins;

        hooks = lib.mkDefault {
          # PreToolUse = [
          #   {
          #     matcher = "Bash";
          #     hooks = [
          #       {
          #         type = "command";
          #         command = ./configs/ai/hooks/enforce-uv.fish;
          #       }
          #     ];
          #   }
          # ];
          PostToolUse = [
            {
              matcher = "Edit|Write|MultiEdit";
              hooks = [
                {
                  command = ''
                    file_path="$1"
                    case "$file_path" in
                      *.nix)   ${lib.getExe pkgs.alejandra} "$file_path" 2>/dev/null || true ;;
                      *.py)    ${lib.getExe pkgs.ruff} format "$file_path" 2>/dev/null || true ;;
                      *.rs)    rustfmt +nightly "$file_path" 2>/dev/null || true ;;
                    esac
                  '';
                  timeout = 10;
                  type = "command";
                }
              ];
            }
          ];
        };

        statusLine = {
          # command = "${lib.getExe my.pkgs.ccometixline} --theme nord";
          command = lib.getExe perSystem.llm-agents.ccstatusline;
          padding = 0;
          type = "command";
        };

        permissions = {
          allow = [
            "Bash(ast-grep *)"
            "Bash(awk *)"
            "Bash(cargo *)"
            "Bash(curl *)"
            "Bash(fd *)"
            "Bash(jq *)"
            "Bash(just *)"
            "Bash(nix *)"
            "Bash(rg *)"
            "Edit(**/*.md)"
            "Edit(//tmp/**)"
            "Glob"
            "Grep"
            "Read(//tmp/**)"
            "Read(~/.claude/skills/**)"
            "Read(~/dev/**)"
            "Skill(ast-grep)"
            "Task"
            "WebFetch"
            "WebSearch"
            "Write(//tmp/**)"
            "Write(**/plans/**)"
          ];

          ask = [
            "Bash(rm)"
            "Bash(rmdir)"
            "Read(./secrets/**)"
          ];

          deny = [
            "Bash(git)"
            "Bash(su)"
            "Bash(sudo)"
            "Read(./.direnv)"
            "Read(./.env)"
            "Read(./.env.*)"
            "Read(./.envrc)"
            "Read(./build)"
            "Read(./config/credentials.json)"
            "Read(./target)"
            "Read(~/.aws)"
            "Read(~/.cache)"
            "Read(~/.cargo)"
            "Read(~/.ssh)"
          ];

          additionalDirectories = [
            "/tmp"
            "/var"
          ];

          defaultMode = "plan";
          disableBypassPermissionsMode = "disable";
        };

        env = {
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          DISABLE_AUTOUPDATER = "1";
          DISABLE_BUG_COMMAND = "1";
          DISABLE_ERROR_REPORTING = "1";
          DISABLE_TELEMETRY = "1";
          # Dynamically load MCPs
          ENABLE_TOOL_SEARCH = "1";
        };
      };

      mcpServers = mcpServersWithType;
    };

    mcp = {
      enable = true;
      servers = mcpServers;
    };

    # https://opencode.ai/docs/
    opencode = {
      enable = true;
      package = perSystem.llm-agents.opencode;
      enableMcpIntegration = true;
      rules = ./configs/ai/AGENTS.md;
      inherit agents;
      skills =
        {
          astral-uv = "${acp}/plugins/astral/skills/uv";
          astral-ruff = "${acp}/plugins/astral/skills/ruff";
          astral-ty = "${acp}/plugins/astral/skills/ty";
          # Individual wshobson skills can be added selectively instead:
          # python-testing-patterns = "${ws}/python-development/skills/python-testing-patterns";
          # rust-async-patterns = "${ws}/systems-programming/skills/rust-async-patterns";
        }
        // wsSkills;
      settings = {
        # model = opencodeModel models.large;
        autoupdate = lib.mkDefault true;
        # provider = {
        #   anthropic = {
        #     options = {
        #       headers = {
        #         anthropic-beta = "context-1m-2025-08-07";
        #       };
        #     };
        #   };
        # };
        compaction = {
          auto = true;
          prune = true;
        };
        formatter = lib.mkDefault {
          alejandra = {
            command = [
              "${lib.getExe pkgs.alejandra}"
              "\$FILE"
            ];
            extensions = [".nix"];
          };
          gofmt = {disabled = true;};
          gofumpt = {
            command = [
              "${lib.getExe pkgs.gofumpt}"
              "-w"
              "\$FILE"
            ];
            extensions = [".go"];
          };
          nixfmt = {disabled = true;};
          ruff-check = {
            command = [
              "${lib.getExe pkgs.ruff}"
              "check"
              "--fix"
              "\$FILE"
            ];
            extensions = [".py" ".pyi"];
          };
          rustfmt = {
            command = [
              "rustfmt"
              "+nightly"
              "--edition=2024"
              "\$FILE"
            ];
            extensions = [".rs"];
          };
          shfmt = {
            command = [
              "${lib.getExe pkgs.shfmt}"
              "-i"
              "4"
              "-ci"
              "-sr"
              "-s"
              "-bn"
              "-w"
              "\$FILE"
            ];
            extensions = [".sh" ".bash"];
          };
          stylua = {
            command = [
              "${lib.getExe pkgs.stylua}"
              "\$FILE"
            ];
            extensions = [".lua"];
          };
        };
        lsp = lib.mkDefault (opencodeLsp
          // {
            pyright = {disabled = true;};
          });
        permission = lib.mkForce {
          bash = {
            "*" = "allow";
            "git status" = "allow";
            clippy = "allow";
            fd = "allow";
            rg = "allow";
          };
          edit = "allow";
          webfetch = "allow";
        };
        theme = "nord";
      };
    };
  };
}
