{
  config,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  mcp-packages = perSystem.mcp-servers-nix;

  lsp = {
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
  mcp = {
    context7 = {
      command = lib.getExe mcp-packages.context7-mcp;
    };
    filesystem = {
      command = lib.getExe mcp-packages.mcp-server-filesystem;
      args = [
        config.xdg.configHome
      ];
    };
    git = {
      command = lib.getExe mcp-packages.mcp-server-git;
    };
    github = {
      command = lib.getExe perSystem.nixpkgs.github-mcp-server;
    };
    memory = {
      command = lib.getExe mcp-packages.mcp-server-memory;
    };
    # nixos = {
    #   command = lib.getExe perSystem.nixpkgs.mcp-nixos;
    # };
    sequential-thinking = {
      command = lib.getExe mcp-packages.mcp-server-sequential-thinking;
    };
  };

  #   programs = {
  #     context7.enable = true;
  #     everything.enable = true;
  #     filesystem = {
  #       enable = true;
  #       args = [
  #         config.xdg.configHome
  #       ];
  #     };
  #     git.enable = true;
  #     github.enable = true;
  #     memory.enable = true;
  #     sequential-thinking.enable = true;
  #   };
  #   settings = {
  #     servers = {
  #       nixos = {
  #         command = lib.getExe pkgs.mcp-nixos;
  #         enable = true;
  #       };
  #     };
  #   };
  # };

  models = {
    large = {
      model = "claude-opus-opus-4-1-20250805";
      provider = "anthropic";
      max_tokens = 32000;
    };
    medium = {
      model = "claude-sonnet-4-5-20250929";
      provider = "anthropic";
      max_tokens = 32000;
    };
    small = {
      model = "claude-sonnet-4-20250514";
      provider = "anthropic";
      max_tokens = 5000;
    };
  };
in {
  home = {
    packages =
      (with perSystem.nix-ai-tools; [
        claude-code-acp
        crush
      ])
      ++ (with pkgs; [
        aichat
        claude-code
        codex
        gemini-cli
        github-mcp-server
        mcp-nixos
        opencode
      ])
      ++ (with my.pkgs; [
        git-ai-commit
        turbo-commit
      ]);
  };

  # https://mynixos.com/options/xdg.configFile.%3Cname%3E
  xdg = {
    configFile = {
      "crush/crush.json" = {
        force = true;
        source = (pkgs.formats.json {}).generate ".config/crush/crush.json" {
          "$schema" = "https://charm.land/crush.json";
          lsp = {
            go.command = lsp.go.command;
            lua.command = lsp.lua.command;
            nix.command = lsp.nix.command;
            python.command = lsp.python.command;
            inherit (lsp) rust;
            inherit (lsp) toml;
            inherit (lsp) typescript;
          };

          mcp = {
            context7 = {
              inherit (mcp.context7) command;
              type = "stdio";
            };
            filesystem = {
              inherit (mcp.filesystem) command args;
              type = "stdio";
            };
            git = {
              inherit (mcp.git) command;
              type = "stdio";
            };
            github = {
              inherit (mcp.github) command;
              type = "http";
            };
            memory = {
              inherit (mcp.memory) command;
              type = "stdio";
            };
            # nixos = {
            #   inherit (mcp.nixos) command;
            #   type = "stdio";
            # };
            sequential-thinking = {
              inherit (mcp.sequential-thinking) command;
              type = "stdio";
            };
          };

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

      # "mcp/mcp.json".source = mcp-servers;
      # mcp-servers-nix.lib.mkConfig {};
    };
  };

  programs = {
    claude-code = {
      enable = true;
      package = pkgs.claude-code;

      settings = {
        inherit (models.medium) model;
        enableAllProjectMcpServers = true;
        includeCoAuthoredBy = false;

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
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
          DISABLE_AUTOUPDATER = 1;
          DISABLE_BUG_COMMAND = 1;
          DISABLE_ERROR_REPORTING = 1;
          DISABLE_TELEMETRY = 1;
        };

        mcpServers = {
          github = {
            type = "http";
            url = "https://api.githubcopilot.com/mcp/";
            headers = {
              Authorization = "Bearer \${GITHUB_API_TOKEN}";
            };
          };
          context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
          };

          sequential-thinking = {
            type = "http";
            url = "https://remote.mcpservers.org/sequentialthinking/mcp";
          };
        };
      };
    };

    # https://opencode.ai/docs/
    opencode = {
      enable = true;
      package = pkgs.opencode;
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
        mcp = {
          context7 = {
            command = [mcp.context7.command];
            type = "local";
          };
          # filesystem = {
          #   command = [mcp.filesystem.command] ++ mcp.filesystem.args;
          #   type = "local";
          # };
          git = {
            command = [mcp.git.command];
            type = "local";
          };
          # github = {
          #   command = [mcp.github.command];
          #   type = "local";
          # };
          memory = {
            command = [mcp.memory.command];
            type = "local";
          };
          # nixos = {
          #   command = [mcp.nixos.command];
          #   type = "local";
          # };
          sequential-thinking = {
            command = [mcp.sequential-thinking.command];
            type = "local";
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
