{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  acp = inputs.astral-claude-plugins;
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

  # Build an opencode command markdown string with frontmatter + original body.
  mkCommand = {
    file,
    description,
    agent ? null,
    subtask ? null,
  }: let
    agentLine = lib.optionalString (agent != null) "agent: ${agent}\n";
    subtaskLine = lib.optionalString (subtask != null) "subtask: ${lib.boolToString subtask}\n";
  in ''
    ---
    description: ${description}
    ${agentLine}${subtaskLine}---
    ${stripFrontmatter file}'';

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

  # Generate wshobson commands with proper opencode frontmatter
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
    comprehensive-review = {
      code-reviewer = "code-reviewer.md";
    };
    data-engineering.data-engineer = "data-engineer.md";
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
      command = "ast-grep-server";
      env = {
        PYTHON_GIL = "1";
      };
    };
    cargo-mcp = {
      command = lib.getExe my.pkgs.cargo-mcp;
      args = ["stdio"];
      disabled = true;
    };
    crates-mcp = {
      command = lib.getExe my.pkgs.crates-mcp;
      disabled = true;
    };
    filesystem = {
      command = lib.getExe my.pkgs.rust-mcp-filesystem;
      args = [config.home.homeDirectory "--allow-write"];
    };
    git = {
      command = lib.getExe my.pkgs.mcp-git-tools;
    };
    git-remote = {
      command = lib.getExe my.pkgs.git-mcp-rs;
    };
    mcp-rust-builder = {
      command = lib.getExe my.pkgs.mcp-rust-builder;
      disabled = true;
    };
    # memory = {
    #   command = lib.getExe my.pkgs.memory-mcp-1file;
    #   disabled = true;
    # };
    nixos = {
      # command = lib.getExe pkgs.mcp-nixos;
      command = "mcp-nixos";
      env = {
        PYTHON_GIL = "1";
      };
      disabled = true;
    };
    rime = {
      command = lib.getExe my.pkgs.rime;
      args = ["stdio"];
      disabled = true;
    };
    rust-analyzer = {
      command = lib.getExe my.pkgs.mcp-rust-analyzer;
      disabled = true;
    };
    treesitter = {
      command = lib.getExe my.pkgs.treesitter-mcp;
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

  # Extension-to-language mappings for claude-code's lspServers format.
  lspLanguageIds = {
    bash = {
      ".sh" = "shellscript";
      ".bash" = "shellscript";
    };
    go = {".go" = "go";};
    helm = {
      ".tpl" = "helm";
      ".yaml" = "helm";
    };
    lua = {".lua" = "lua";};
    nix = {".nix" = "nix";};
    rust = {".rs" = "rust";};
    toml = {".toml" = "toml";};
    typescript = {
      ".ts" = "typescript";
      ".tsx" = "typescriptreact";
      ".js" = "javascript";
      ".jsx" = "javascriptreact";
    };
  };

  # For claude-code: transform to { command, args?, extensionToLanguage }
  claudeCodeLsp =
    lib.mapAttrs (
      name: v:
        {
          inherit (v) command;
          extensionToLanguage = lspLanguageIds.${name};
        }
        // lib.optionalAttrs (v ? args) {inherit (v) args;}
    )
    lsp;

  opencodeLsp = lib.mapAttrs (name: v: {
    command = [v.command] ++ (v.args or []);
    extensions = lspExtensions.${name};
  }) (lib.filterAttrs (n: _: lspExtensions ? ${n}) lsp);
  # For opencode: prefix with provider
  # opencodeModel = m: "${m.provider}/${m.model}";
in {
  imports = [
    inputs.charmbracelet-nur.homeModules.crush
    inputs.skills-nix.homeModules.default
  ];

  xdg.configFile."opencode/tui.jsonc".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "nord";
    keybinds = {
      input_delete_to_line_start = "ctrl+u";
      input_delete_to_line_end = "ctrl+k";
      # messages_half_page_down = "ctrl+d";
      theme_list = "none";
      username_toggle = "none";
      model_list = "ctrl+p";
      variant_cycle = "ctrl+r";
      model_cycle_recent = "none";
      model_cycle_recent_reverse = "none";
      agent_list = "ctrl+a";
      display_thinking = "ctrl+t";
    };
    scroll_acceleration = {
      enabled = true;
    };
  };

  home = {
    sessionVariables = {
      OPENCODE_EXPERIMENTAL_LSP_TY = "1";
    };

    packages =
      (
        with perSystem.llm-agents; [
          ccstatusline
          claude-code-acp
          # codex
          # gemini-cli
          # goose-cli
        ]
      )
      ++ (with my.pkgs; [
        cargo-mcp
        crates-mcp
        git-mcp-rs
        # infiniloom
        mcp-git-tools
        mcp-rust-analyzer
        mcp-rust-builder
        # memory-mcp-1file
        rust-mcp-filesystem
        rust-mcp-server
        sentry-mcp
        treesitter-mcp
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

      lspServers = claudeCodeLsp;

      mcpServers = mcpServersWithType;
    };

    mcp = {
      enable = true;
      servers = mcpServers;
    };

    skills = {
      enable = true;
      defaultAgents = ["opencode" "claude-code"];
      sources = [
        "cocoindex-io/cocoindex-code"
        "dabiggm0e/autoresearch-opencode"
        "wshobson/agents"
        "vercel-labs/agent-skills"
      ];
    };

    # https://opencode.ai/docs/
    opencode = {
      enable = true;
      package = perSystem.llm-agents.opencode;
      enableMcpIntegration = true;
      inherit agents;

      commands = wsCommands;

      rules = ./configs/ai/AGENTS.md;
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
        permission = lib.mkDefault {
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
        plugin = ["opencode-claude-auth"];
        theme = "nord";
      };
      skills = {
        astral-uv = "${acp}/plugins/astral/skills/uv";
        astral-ruff = "${acp}/plugins/astral/skills/ruff";
        astral-ty = "${acp}/plugins/astral/skills/ty";
      };
    };
  };
}
