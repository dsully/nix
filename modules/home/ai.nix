{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  mcp-packages = perSystem.mcp-servers-nix;
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

  opencodeLsp = lib.mapAttrs (name: v: {
    command = [v.command] ++ (v.args or []);
    extensions = lspExtensions.${name};
  }) (lib.filterAttrs (n: _: lspExtensions ? ${n}) lsp);

  mcpServers = {
    context7 = {
      command = lib.getExe mcp-packages.context7-mcp;
    };
    filesystem = {
      command = "rust-mcp-filesystem";
      args = [config.home.homeDirectory "--allow-write"];
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

  # For opencode: prefix with provider
  opencodeModel = m: "${m.provider}/${m.model}";

  # Shared agents for claude-code and opencode
  ws = "${inputs.wshobson-agents}/plugins";
  agents = {
    app-observability-engineer = "${ws}/application-performance/agents/observability-engineer.md";
    app-performance-engineer = "${ws}/application-performance/agents/performance-engineer.md";
    architect-review = "${ws}/code-review-ai/agents/architect-review.md";
    backend-architect = "${ws}/backend-development/agents/backend-architect.md";
    cleanup-test-automator = "${ws}/codebase-cleanup/agents/test-automator.md";
    cloud-architect = "${ws}/cloud-infrastructure/agents/cloud-architect.md";
    data-engineer = "${ws}/data-engineering/agents/data-engineer.md";
    database-optimizer = "${ws}/observability-monitoring/agents/database-optimizer.md";
    debugger = "${ws}/debugging-toolkit/agents/debugger.md";
    deployment-engineer = "${ws}/cloud-infrastructure/agents/deployment-engineer.md";
    devops-troubleshooter = "${ws}/incident-response/agents/devops-troubleshooter.md";
    docs-architect = "${ws}/code-documentation/agents/docs-architect.md";
    dx-optimizer = "${ws}/debugging-toolkit/agents/dx-optimizer.md";
    error-detective = "${ws}/error-diagnostics/agents/error-detective.md";
    event-sourcing-architect = "${ws}/backend-development/agents/event-sourcing-architect.md";
    fastapi-pro = "${ws}/python-development/agents/fastapi-pro.md";
    golang-pro = "${ws}/systems-programming/agents/golang-pro.md";
    hybrid-cloud-architect = "${ws}/cloud-infrastructure/agents/hybrid-cloud-architect.md";
    incident-responder = "${ws}/incident-response/agents/incident-responder.md";
    legacy-modernizer = "${ws}/code-refactoring/agents/legacy-modernizer.md";
    network-engineer = "${ws}/observability-monitoring/agents/network-engineer.md";
    obs-performance-engineer = "${ws}/observability-monitoring/agents/performance-engineer.md";
    observability-engineer = "${ws}/observability-monitoring/agents/observability-engineer.md";
    perf-performance-engineer = "${ws}/performance-testing-review/agents/performance-engineer.md";
    perf-test-automator = "${ws}/performance-testing-review/agents/test-automator.md";
    python-pro = "${ws}/python-development/agents/python-pro.md";
    refactoring-reviewer = "${ws}/code-refactoring/agents/code-reviewer.md";
    rust-pro = "${ws}/systems-programming/agents/rust-pro.md";
    service-mesh-expert = "${ws}/cloud-infrastructure/agents/service-mesh-expert.md";
    test-automator = "${ws}/unit-testing/agents/test-automator.md";
    tutorial-engineer = "${ws}/code-documentation/agents/tutorial-engineer.md";
  };
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
          wshobson-agents = {
            source = {
              source = "github";
              repo = "wshobson/agents";
            };
          };
        };

        enabledPlugins = {
          # Official plugins
          "code-review@claude-plugins-official" = lib.mkDefault true;
          "commit-commands@claude-plugins-official" = lib.mkDefault true;
          "feature-dev@claude-plugins-official" = lib.mkDefault true;
          "pr-review-toolkit@claude-plugins-official" = lib.mkDefault true;
          "ralph-wiggum@claude-plugins-official" = lib.mkDefault true;
          "rust-analyzer-lsp@claude-plugins-official" = lib.mkDefault true;
          # wshobson/agents marketplace
          "application-performance@wshobson-agents" = lib.mkDefault true;
          "backend-development@wshobson-agents" = lib.mkDefault true;
          "cloud-infrastructure@wshobson-agents" = lib.mkDefault true;
          "code-documentation@wshobson-agents" = lib.mkDefault true;
          "code-refactoring@wshobson-agents" = lib.mkDefault true;
          "code-review-ai@wshobson-agents" = lib.mkDefault true;
          "codebase-cleanup@wshobson-agents" = lib.mkDefault true;
          "data-engineering@wshobson-agents" = lib.mkDefault true;
          "debugging-toolkit@wshobson-agents" = lib.mkDefault true;
          "error-diagnostics@wshobson-agents" = lib.mkDefault true;
          "incident-response@wshobson-agents" = lib.mkDefault true;
          "observability-monitoring@wshobson-agents" = lib.mkDefault true;
          "performance-testing-review@wshobson-agents" = lib.mkDefault true;
          "python-development@wshobson-agents" = lib.mkDefault true;
          "systems-programming@wshobson-agents" = lib.mkDefault true;
          "tdd-workflows@wshobson-agents" = lib.mkDefault true;
          "unit-testing@wshobson-agents" = lib.mkDefault true;
        };

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
            "/var/folders/"
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
