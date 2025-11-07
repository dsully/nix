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
      github = {
        enable = true;
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "$(gh auth token)";
        };
        type = "stdio";
      };
      memory = {
        enable = true;
        type = "stdio";
      };
      nixos = {
        enable = true;
        type = "stdio";
      };
      sequential-thinking = {
        enable = true;
        type = "stdio";
      };
    };
    settings.servers = {
      filesystem = {
        command = "rust-mcp-filesystem";
        args = [config.xdg.configHome];
        type = "stdio";
      };
    };
  };

  models = {
    large = {
      model = "claude-opus-opus-4-1-20250805";
      provider = "anthropic";
      max_tokens = 32000;
      reasoning_effort = "medium";
    };
    medium = {
      model = "claude-sonnet-4-5-20250929";
      provider = "anthropic";
      max_tokens = 32000;
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
  # Hardcode until https://github.com/charmbracelet/nur/pull/33 is merged.
  imports = [inputs.charmbracelet-nur.legacyPackages.aarch64-darwin.modules.homeModules.crush];

  home = {
    packages =
      (
        with perSystem.nix-ai-tools;
          [
            claude-code-acp
            codex
            gemini-cli
            opencode
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            # Use claude-code from Homebrew on macOS as it is a single binary.
            claude-code
          ]
      )
      ++ (with my.pkgs; [
        crates-mcp
        git-ai-commit
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
      # Use claude-code from Homebrew on macOS as it is a single binary.
      package = null;

      settings = {
        inherit (models.medium) model;
        enableAllProjectMcpServers = true;
        includeCoAuthoredBy = false;

        autoUpdates = false;

        statusLine = {
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')]  $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
          type = "command";
        };

        permissions = {
          allow =
            [
              "Bash(cargo :*)"
              "Bash(fd:*)"
              "Bash(find:*)"
              "Bash(git add:*)"
              "Bash(git bisect:*)"
              "Bash(git blame:*)"
              "Bash(git diff:*)"
              "Bash(git fetch:*)"
              "Bash(git grep:*)"
              "Bash(git log:*)"
              "Bash(git ls-remote:*)"
              "Bash(git remote show:*)"
              "Bash(git restore:*)"
              "Bash(git show:*)"
              "Bash(git status:*)"
              "Bash(ls:*)"
              "Bash(mkdir:*)"
              "Bash(nix :*)"
              "Bash(pwd:*)"
              "Bash(rg:*)"
              "Bash(statix check:*)"
              "Bash(uv:*)"
              "Bash(xh:*)"
              "Edit(**/*.md)"
              "Glob"
              "Grep"
              "Read(~/.claude/plugins/cache/superpowers/skills/*)"
              "Task"
              "WebFetch"
              "WebSearch"
            ]
            ++ [
              "mcp__context7__get-library-docs"
              "mcp__context7__resolve-library-id"
              "mcp__sequential-thinking"
            ];

          ask = [];

          deny = [
            "Bash(rm -rf :*)"
            "Bash(su:*)"
            "Bash(sudo:*)"
            "Read(./.direnv)"
            "Read(./.env.*)"
            "Read(./.env)"
            "Read(./.envrc)"
            "Read(./build)"
            "Read(./config/credentials.json)"
            "Read(./secrets/**)"
            "Read(./targets)"
            "Read(~/.aws)"
            "Read(~/.cache)"
            "Read(~/.cargo)"
            "Read(~/.ssh)"
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

        mcpServers = mcp-servers-config.config.settings.servers;
      };
    };

    mcp = {
      enable = true;
      servers = {
        context7 = {
          command = lib.getExe mcp-packages.context7-mcp;
        };
        filesystem = {
          command = "rust-mcp-filesystem";
          args = [config.xdg.configHome];
        };
        git = {
          command = lib.getExe mcp-packages.mcp-server-git;
        };
        github = {
          command = lib.getExe pkgs.github-mcp-server;
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = "$(gh auth token)";
          };
        };
        nixos = {
          command = lib.getExe pkgs.mcp-nixos;
        };
        memory = {
          command = lib.getExe mcp-packages.mcp-server-memory;
        };
        sequential-thinking = {
          command = lib.getExe mcp-packages.mcp-server-sequential-thinking;
        };
      };
    };

    # https://opencode.ai/docs/
    opencode = {
      enable = true;
      package = perSystem.nix-ai-tools.opencode;
      enableMcpIntegration = true;
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
