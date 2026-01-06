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
  mcp-lib = inputs.mcp-servers-nix.lib;

  lsp = {
    bash = {
      command = lib.getExe pkgs.bash-language-server;
      args = ["start"];
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

  # https://github.com/natsukium/mcp-servers-nix
  mcp-servers-config = mcp-lib.evalModule pkgs {
    programs = {
      context7 = {
        enable = true;
        type = "stdio";
      };
    };
    settings.servers = {
      filesystem = {
        command = "rust-mcp-filesystem";
        args = [config.home.homeDirectory "--allow-write"];
        type = "stdio";
      };
      rime = {
        command = lib.getExe my.pkgs.rime;
        args = ["stdio"];
        type = "stdio";
      };
      rust-analyzer = {
        command = lib.getExe my.pkgs.mcp-rust-analyzer;
        type = "stdio";
      };
    };
  };

  # Shared MCP servers for programs.mcp (used by other tools like opencode)
  sharedMcpServers = {
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
  };

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
        lsp = {
          go = {
            inherit (lsp.go) command;
            enabled = true;
          };
          lua = {
            inherit (lsp.lua) command;
            enabled = true;
          };
          nix = {
            inherit (lsp.nix) command;
            enabled = true;
          };
          python = {
            inherit (lsp.python) command;
            inherit (lsp.python) args;
            enabled = true;
          };
          rust = {
            inherit (lsp.rust) command;
            inherit (lsp.rust) args;
            enabled = true;
          };
          toml = {
            inherit (lsp.toml) command;
            inherit (lsp.toml) args;
            enabled = true;
          };
          typescript = {
            inherit (lsp.typescript) command;
            inherit (lsp.typescript) args;
            enabled = true;
          };
        };

        mcp = mcp-servers-config.config.settings.servers;

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

      agents = {
        code-debugger = ./configs/ai/agents/code-debugger.md;
        code-reviewer = ./configs/ai/agents/code-reviewer.md;
        performance-optimizer = ./configs/ai/agents/performance-optimizer.md;
        systems-architect = ./configs/ai/agents/systems-architect.md;
      };

      memory.source = ./configs/ai/AGENTS.md;

      settings = {
        inherit (models.large) model;
        enableAllProjectMcpServers = false;
        includeCoAuthoredBy = false;

        autoUpdates = false;

        enabledPlugins = {
          "code-review@claude-plugins-official" = lib.mkDefault true;
          "commit-commands@claude-plugins-official" = lib.mkDefault true;
          "feature-dev@claude-plugins-official" = lib.mkDefault true;
          "pr-review-toolkit@claude-plugins-official" = lib.mkDefault true;
          "ralph-wiggum@claude-plugins-official" = lib.mkDefault true;
          "rust-analyzer-lsp@claude-plugins-official" = lib.mkDefault true;
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
            "Skill(bd-issue-tracking)"
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

      mcpServers = mcp-servers-config.config.settings.servers;
    };

    mcp = {
      enable = true;
      servers = sharedMcpServers;
    };

    # https://opencode.ai/docs/
    opencode = {
      enable = true;
      package = perSystem.llm-agents.opencode;
      enableMcpIntegration = true;
      rules = ./configs/ai/AGENTS.md;
      settings = {
        agent = {
          build = {
            apiKey = lib.mkDefault "$ANTHROPIC_API_KEY";
            mode = "primary";
            model = "anthropic/claude-sonnet-4-5-20250929";
            # prompt = "{file:./prompts/build.txt}";
            tools = {
              bash = true;
              edit = true;
              write = true;
            };
          };
          plan = {
            apiKey = lib.mkDefault "$ANTHROPIC_API_KEY";
            mode = "primary";
            model = "anthropic/claude-sonnet-4-5-20250929";
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
            model = "anthropic/claude-sonnet-4-5-20250929";
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
        lsp = lib.mkDefault {
          helm = {
            command = ["helm_ls" "serve" "--stdio"];
            extensions = [".tpl" ".yaml"];
          };
          lua = {
            command = [lsp.lua.command];
            extensions = [".lua"];
          };
          nix = {
            command = [lsp.nix.command];
            extensions = [".nix"];
          };
          python = {
            command = [lsp.python.command];
            extensions = [".py"];
          };
          rust = {
            command = [lsp.rust.command] ++ lsp.rust.args;
            extensions = [".rs"];
          };
          toml = {
            command = [lsp.toml.command] ++ lsp.toml.args;
            extensions = [".toml"];
          };
          typescript = {
            command = [lsp.typescript.command] ++ lsp.typescript.args;
            extensions = [".ts" ".tsx" ".js" ".jsx"];
          };
        };
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
