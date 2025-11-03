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

  # MCP server commands
  mcp = {
    context7.command = lib.getExe mcp-packages.context7-mcp;
    filesystem = {
      command = "rust-mcp-filesystem";
      args = [config.xdg.configHome];
    };
    git.command = lib.getExe mcp-packages.mcp-server-git;
    nixos.command = lib.getExe pkgs.mcp-nixos;
    memory.command = lib.getExe mcp-packages.mcp-server-memory;
    sequential-thinking.command = lib.getExe mcp-packages.mcp-server-sequential-thinking;
  };

  # https://github.com/natsukium/mcp-servers-nix
  # mcp-servers-config = mcp-lib.mkConfig pkgs {
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
        # headers = {
        #   Authorization = "$(echo Bearer $GITHUB_API_TOKEN)";
        # };
        # passwordCommand = {
        #   GITHUB_PERSONAL_ACCESS_TOKEN = [
        #     (pkgs.lib.getExe config.programs.gh.package)
        #     "auth"
        #     "token"
        #   ];
        # };
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
  home = {
    packages =
      (
        with perSystem.nix-ai-tools;
          [
            claude-code-acp
            codex
            crush
            gemini-cli
            opencode
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # Use claude-code from Homebrew on macOS as it is a single binary.
            claude-code
          ]
      )
      ++ (
        with pkgs; [
          github-mcp-server
          mcp-nixos
        ]
      )
      ++ (with my.pkgs; [
        crates-mcp
        git-ai-commit
        rust-mcp-server
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
            inherit (lsp) bash;
            go.command = lsp.go.command;
            lua.command = lsp.lua.command;
            nix.command = lsp.nix.command;
            python.command = lsp.python.command;
            inherit (lsp) rust;
            inherit (lsp) toml;
            inherit (lsp) typescript;
          };

          mcp = mcp-servers-config.config.settings.servers;

          inherit models;

          options = {
            tui = {
              compact_mode = true;
              diff_mode = "unified";
            };
          };

          permissions = {
            allowed_tools = [
              "agent"
              "edit"
              "fetch"
              "glob"
              "grep"
              "ls"
              "multiedit"
              "sourcegraph"
              "view"
              "write"

              "mcp_context7_get-library-doc"
              "mcp_context7_get-library-docs"
              "mcp_context7_resolve-library-id"

              "mcp_github_get_commit"
              "mcp_github_get_discussion_comments"
              "mcp_github_get_discussion"
              "mcp_github_get_file_contents"
              "mcp_github_get_issue_comments"
              "mcp_github_get_issue"
              "mcp_github_get_job_logs"
              "mcp_github_get_latest_release"
              "mcp_github_get_me"
              "mcp_github_get_pull_request_comments"
              "mcp_github_get_pull_request_diff"
              "mcp_github_get_pull_request_files"
              "mcp_github_get_pull_request_reviews"
              "mcp_github_get_pull_request_status"
              "mcp_github_get_pull_request"
              "mcp_github_get_release_by_tag"
              "mcp_github_get_tag"
              "mcp_github_get_workflow_run_logs"
              "mcp_github_get_workflow_run_usage"
              "mcp_github_get_workflow_run"
              "mcp_github_list_branches"
              "mcp_github_list_commits"
              "mcp_github_list_discussion_categories"
              "mcp_github_list_discussions"
              "mcp_github_list_issue_types"
              "mcp_github_list_issues"
              "mcp_github_list_pull_requests"
              "mcp_github_list_releases"
              "mcp_github_list_sub_issues"
              "mcp_github_list_tags"
              "mcp_github_list_workflow_jobs"
              "mcp_github_list_workflow_run_artifacts"
              "mcp_github_list_workflow_runs"
              "mcp_github_list_workflows"
              "mcp_github_search_code"
              "mcp_github_search_issues"
              "mcp_github_search_orgs"
              "mcp_github_search_pull_requests"
              "mcp_github_search_repositories"
              "mcp_github_search_users"
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
    # crush = {
    #   enable = true;
    #
    #   settings = {
    #     lsp = {
    #       go = {
    #         inherit (lsp.go) command;
    #         enabled = true;
    #       };
    #       lua = {
    #         inherit (lsp.lua) command;
    #         enabled = true;
    #       };
    #       nix = {
    #         inherit (lsp.nix) command;
    #         enabled = true;
    #       };
    #       python = {
    #         inherit (lsp.python) command;
    #         inherit (lsp.python) args;
    #         enabled = true;
    #       };
    #       rust = {
    #         inherit (lsp.rust) command;
    #         inherit (lsp.rust) args;
    #         enabled = true;
    #       };
    #       toml = {
    #         inherit (lsp.toml) command;
    #         inherit (lsp.toml) args;
    #         enabled = true;
    #       };
    #       typescript = {
    #         inherit (lsp.typescript) command;
    #         inherit (lsp.typescript) args;
    #         enabled = true;
    #       };
    #     };
    #
    #     mcp = {
    #       context7 = {
    #         inherit (mcp.context7) command;
    #         type = "stdio";
    #       };
    #       filesystem = {
    #         inherit (mcp.filesystem) command args;
    #         type = "stdio";
    #       };
    #       git = {
    #         inherit (mcp.git) command;
    #         type = "stdio";
    #       };
    #       memory = {
    #         inherit (mcp.memory) command;
    #         type = "stdio";
    #       };
    #       # nixos = {
    #       #   inherit (mcp.nixos) command;
    #       #   type = "stdio";
    #       # };
    #       sequential-thinking = {
    #         inherit (mcp.sequential-thinking) command;
    #         type = "stdio";
    #       };
    #     };
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

    # https://opencode.ai/docs/
    opencode = {
      enable = true;
      package = perSystem.nix-ai-tools.opencode;
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
          filesystem = {
            command = [mcp.filesystem.command] ++ mcp.filesystem.args;
            type = "local";
          };
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
          nixos = {
            command = [mcp.nixos.command];
            type = "local";
          };
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
