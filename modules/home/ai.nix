{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  ws = "${inputs.wshobson-agents}/plugins";

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

  # Generate agents attrset from wsPluginAgents
  agents =
    lib.foldlAttrs (
      acc: plugin: agentAttrs:
        acc
        // lib.mapAttrs (_: file: "${ws}/${plugin}/agents/${file}") agentAttrs
    ) {}
    wsPluginAgents;

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
    python = {
      command = lib.getExe pkgs.ty;
      args = [
        "server"
      ];
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
  lspWithEnabled = lib.mapAttrs (_: v: v // {enabled = true;}) (removeAttrs lsp ["bash"]);

  # For opencode: transform to { command = [...], extensions = [...] }
  lspExtensions = {
    helm = [".tpl" ".yaml"];
    lua = [".lua"];
    nix = [".nix"];
    python = [".py"];
    rust = [".rs"];
    toml = [".toml"];
    typescript = [".ts" ".tsx" ".js" ".jsx"];
  };

  mcp-packages = perSystem.mcp-servers-nix;
  mcpServers = {
    context7 = {
      command = lib.getExe mcp-packages.context7-mcp;
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
      model = "claude-opus-4-5-20251101";
      provider = "anthropic";
      max_tokens = 200000;
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
  opencodeModel = m: "${m.provider}/${m.model}";
in {
  imports = [
    inputs.charmbracelet-nur.homeModules.crush
  ];

  home = {
    packages =
      (
        with perSystem.llm-agents; [
          claude-code-acp
          # codex
          # gemini-cli
          goose-cli
        ]
      )
      ++ (with my.pkgs; [
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
    crush = {
      enable = true;

      settings = {
        lsp = lspWithEnabled;
        mcp = mcpServersWithType;

        inherit models;

        permissions = {
          allowed_tools = [
            "edit"
            "grep"
            "ls"
            "view"
            "mcp_context7_get-library-doc"
          ];
        };

        providers = {
          anthropic = {
            id = "anthropic";
            name = "Anthropic";
            type = "anthropic";
            api_key = "Bearer $(anthropic-api-key)";
            extra_headers = {
              anthropic-version = "2023-06-01";
              anthropic-beta = "oauth-2025-04-20";
            };
            system_prompt_prefix = "You are Claude Code, Anthropic's official CLI for Claude.";
          };
        };
      };
    };

    claude-code = {
      enable = true;
      package = perSystem.llm-agents.claude-code;

      inherit agents;

      memory.source = ./configs/ai/AGENTS.md;

      settings = {
        inherit (models.large) model;
        enableAllProjectMcpServers = false;
        includeCoAuthoredBy = false;

        autoUpdates = false;

        extraKnownMarketplaces = {
          claude-code-workflows = {
            source = {
              source = "directory";
              path = "${inputs.wshobson-agents}";
            };
          };
        };

        enabledPlugins =
          {
            "code-review@claude-plugins-official" = lib.mkDefault true;
            "code-simplifier@claude-plugins-official" = lib.mkDefault true;
            "commit-commands@claude-plugins-official" = lib.mkDefault true;
            "feature-dev@claude-plugins-official" = lib.mkDefault true;
            "pr-review-toolkit@claude-plugins-official" = lib.mkDefault true;
            "ralph-loop@claude-plugins-official" = lib.mkDefault true;
            "rust-analyzer-lsp@claude-plugins-official" = lib.mkDefault true;
          }
          // wsEnabledPlugins;

        hooks = {
          PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = ./configs/ai/hooks/enforce-uv.fish;
                }
              ];
            }
          ];
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
          command = "${lib.getExe my.pkgs.ccometixline} --theme nord";
          padding = 0;
          type = "command";
        };

        permissions = {
          allow = [
            "Bash(ast-grep:*)"
            "Bash(awk:*)"
            "Bash(cargo:*)"
            "Bash(cat:*)"
            "Bash(chmod:*)"
            "Bash(clippy:*)"
            "Bash(curl:*)"
            "Bash(fd:*)"
            "Bash(find:*)"
            "Bash(git diff)"
            "Bash(grep:*)"
            "Bash(jq:*)"
            "Bash(just:*)"
            "Bash(ls:*)"
            "Bash(make:*)"
            "Bash(mkdir:*)"
            "Bash(nix:*)"
            "Bash(pwd:*)"
            "Bash(pytest:*)"
            "Bash(python3:*)"
            "Bash(python:*)"
            "Bash(rg:*)"
            "Bash(rustfmt:*)"
            "Bash(sed:*)"
            "Bash(statix check:*)"
            "Bash(uv:*)"
            "Bash(xargs:*)"
            "Bash(xh:*)"
            "Bash(yq:*)"
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
            "mcp__context7"
            "mcp__filesystem"
            "mcp__rust-analyzer"
          ];

          ask = [
            "Bash(git:*)"
            "Bash(rm:*)"
            "Bash(rmdir:*)"
            "Read(./secrets/**)"
            "mcp__rime"
          ];

          deny = [
            "Bash(su:*)"
            "Bash(sudo:*)"
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

      skills = {
        ast-grep = "${inputs.ai-skills-ast-grep}/ast-grep/skills/ast-grep";
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
      settings = {
        agent = {
          build = {
            apiKey = lib.mkDefault "$ANTHROPIC_API_KEY";
            mode = "primary";
            model = opencodeModel models.medium;
            tools = {
              bash = true;
              edit = true;
              write = true;
            };
          };
          plan = {
            apiKey = lib.mkDefault "$ANTHROPIC_API_KEY";
            mode = "primary";
            model = opencodeModel models.large;
            tools = {
              bash = false;
              edit = false;
              write = false;
            };
          };
          review = {
            apiKey = lib.mkDefault "$ANTHROPIC_API_KEY";
            description = "Reviews code for best practices and potential issues";
            mode = "subagent";
            model = opencodeModel models.large;
            prompt = "You are a code reviewer. Focus on security, performance, and maintainability.";
            tools = {
              edit = false;
              write = false;
            };
          };
        };
        autoupdate = false;
        formatter = lib.mkDefault {
          rustfmt = {
            disabled = false;
            command = [
              "rustfmt"
              "+nightly"
              "--edition=2024"
              "\$FILE"
            ];
            extensions = [".rs"];
          };
        };
        lsp = lib.mkDefault opencodeLsp;
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
