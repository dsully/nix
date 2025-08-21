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
      command = lib.getExe my.pkgs.emmylua-analyzer-rust;
    };
    nix = {
      command = lib.getExe pkgs.nil;
    };
    python = {
      command = lib.getExe pkgs.ty;
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
    nixos = {
      command = lib.getExe perSystem.nixpkgs.mcp-nixos;
    };
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
      model = "claude-opus-4-20250514";
      provider = "anthropic";
      max_tokens = 32000;
    };
    medium = {
      model = "claude-sonnet-4-20250514";
      provider = "anthropic";
      max_tokens = 32000;
    };
    small = {
      model = "claude-3-5-haiku-20241022";
      provider = "anthropic";
      max_tokens = 5000;
    };
  };
in {
  home = {
    packages =
      (with perSystem.nix-ai-tools; [
        claude-code
        crush
        gemini-cli
        goose-cli
        opencode
      ])
      ++ (with pkgs; [
        aichat
        github-mcp-server
        mcp-nixos
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
            nixos = {
              inherit (mcp.nixos) command;
              type = "stdio";
            };
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
        };
      };

      "goose/config.yaml" = {
        force = true;
        source = (pkgs.formats.yaml {}).generate ".config/goose/config.yaml" {
          GOOSE_PROVIDER = "anthropic";
          GOOSE_MODEL = models.small;
          GOOSE_MODE = "smart_approve";
          extensions = {
            computercontroller = {
              display_name = "Computer Controller";
              enabled = true;
              name = "computercontroller";
              timeout = 300;
              type = "builtin";
            };
            developer = {
              display_name = "Developer Tools";
              enabled = true;
              name = "developer";
              timeout = 300;
              type = "builtin";
            };
            memory = {
              display_name = "Memory";
              enabled = true;
              name = "memory";
              timeout = 300;
              type = "builtin";
            };
          };
        };
      };

      # "mcp/mcp.json".source = mcp-servers;
      # mcp-servers-nix.lib.mkConfig {};
    };
  };

  # https://opencode.ai/docs/
  programs = {
    opencode = {
      enable = true;
      package = perSystem.nix-ai-tools.opencode;
      settings = {
        agent = {
          build = {
            apiKey = lib.mkDefault "$ANTHROPIC_API_KEY";
            mode = "primary";
            model = "anthropic/claude-sonnet-4-20250514";
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
            model = "anthropic/claude-haiku-4-20250514";
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
            model = "anthropic/claude-sonnet-4-20250514";
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
        lsp = {
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
