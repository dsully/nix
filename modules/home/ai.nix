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
      git = {
        enable = true;
        type = "stdio";
      };
      # github = {
      #   enable = true;
      #   env = {
      #     GITHUB_PERSONAL_ACCESS_TOKEN = "$(gh auth token)";
      #   };
      #   type = "stdio";
      # };
      # memory = {
      #   enable = true;
      #   type = "stdio";
      # };
      # nixos = {
      #   enable = true;
      #   type = "stdio";
      # };
      # sequential-thinking = {
      #   enable = true;
      #   type = "stdio";
      # };
    };
    settings.servers = {
      filesystem = {
        command = "rust-mcp-filesystem";
        args = [config.home.homeDirectory];
        type = "stdio";
      };
      rust-analyzer = {
        command = lib.getExe my.pkgs.mcp-rust-analyzer;
        type = "stdio";
      };
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
    # FIXME: Figure out why skils isn't working in programs.claude-code
    file = {
      ".claude/skills/ast-grep".source = "${inputs.ai-skills-ast-grep}/ast-grep/skills/ast-grep";
    };

    packages =
      (
        with perSystem.llm-agents; [
          beads
          claude-code-acp
          # codex
          # gemini-cli
        ]
      )
      ++ (
        with perSystem.mcp-servers-nix; [
          serena
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
        enableAllProjectMcpServers = true;
        includeCoAuthoredBy = false;

        autoUpdates = false;

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
            "Bash(git:*)"
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

            "mcp__filesystem"
            "mcp__serena"
          ];

          ask = [
            "Bash(git rm:*)"
            "Bash(rm:*)"
            "Bash(rmdir:*)"
            "Read(./secrets/**)"
            "Read(~/.cargo)"
            "mcp__context7"
            "mcp__git"
            "mcp__github"
            "mcp__nixos"
            "mcp__rust-analyzer"
            "mcp__sequential-thinking"
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

        # skills = {
        #   ast-grep = "${inputs.ai-skills-ast-grep}/ast-grep/skills/ast-grep";
        # };
      };

      mcpServers = mcp-servers-config.config.settings.servers;
    };

    mcp = {
      enable = true;
      servers = {
        context7 = {
          command = lib.getExe mcp-packages.context7-mcp;
        };
        filesystem = {
          command = "rust-mcp-filesystem";
          args = [config.home.homeDirectory];
        };
        git = {
          command = lib.getExe mcp-packages.mcp-server-git;
        };
        # github = {
        #   command = lib.getExe pkgs.github-mcp-server;
        #   env = {
        #     GITHUB_PERSONAL_ACCESS_TOKEN = "$(gh auth token)";
        #   };
        # };
        # nixos = {
        #   command = lib.getExe pkgs.mcp-nixos;
        # };
        # memory = {
        #   command = lib.getExe mcp-packages.mcp-server-memory;
        # };
        # sequential-thinking = {
        #   command = lib.getExe mcp-packages.mcp-server-sequential-thinking;
        # };
        serena = {
          command = lib.getExe mcp-packages.serena;
        };
      };
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
