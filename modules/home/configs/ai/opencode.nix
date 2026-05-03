{
  aiAgents,
  aiLib,
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  aro = inputs.autoresearch-opencode;

  lspExtensions = {
    helm = [".tpl" ".yaml"];
    lua = [".lua"];
    nix = [".nix"];
    rust = [".rs"];
    toml = [".toml"];
    typescript = [".ts" ".tsx" ".js" ".jsx"];
  };

  opencodeLsp = lib.mapAttrs (name: v: {
    command = [v.command] ++ (v.args or []);
    extensions = lspExtensions.${name};
  }) (lib.filterAttrs (n: _: lspExtensions ? ${n}) aiLib.lsp);

  autoresearchSkills = {
    autoresearch = "${aro}/skills/autoresearch";
  };
in {
  # Allow host specific overrides.
  options.programs.opencode.extraPlugins = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Additional opencode plugins appended to the base set.";
  };

  config.home = {
    sessionVariables = {
      # https://opencode.ai/docs/cli/#environment-variables
      OPENCODE_DISABLE_AUTOUPDATE = 1;

      # https://opencode.ai/docs/rules/#claude-code-compatibility
      OPENCODE_DISABLE_CLAUDE_CODE = 1;

      OPENCODE_DISABLE_LSP_DOWNLOAD = 1;
      OPENCODE_DISABLE_PRUNE = 1;

      # https://opencode.ai/docs/cli/#experimental
      OPENCODE_EXPERIMENTAL = 1;
      OPENCODE_EXPERIMENTAL_FILEWATCHER = 1;
      OPENCODE_EXPERIMENTAL_ICON_DISCOVERY = 1;
      OPENCODE_EXPERIMENTAL_LSP_TOOL = 1;
      OPENCODE_EXPERIMENTAL_LSP_TY = 1;
      OPENCODE_EXPERIMENTAL_MARKDOWN = 1;
      OPENCODE_EXPERIMENTAL_PLAN_MODE = 1;
    };
  };

  config.programs.opencode = {
    enable = true;
    package = perSystem.llm-agents.opencode;
    enableMcpIntegration = false;
    inherit (aiAgents) agents;
    commands =
      aiAgents.commands
      // (aiLib.mkAI {
        source = aro;
        commands = ["autoresearch"];
      }).commands;

    context = ./AGENTS.md;
    settings = {
      autoupdate = lib.mkDefault true;
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

      mcp = lib.mkDefault {
        agentgateway = {
          type = "remote";
          url = aiLib.agentgateway.mcpHttpUrl;
          enabled = true;
        };
      };

      lsp = lib.mkDefault ((lib.removeAttrs opencodeLsp ["rust"])
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
        lsp = "allow";
        webfetch = "allow";
      };

      plugin =
        [
          "@mohak34/opencode-notifier@latest"
          "${perSystem.llm-agents.rtk}/libexec/rtk/hooks/opencode/rtk.ts"
          "${my.pkgs.icm}/plugins/opencode-icm.ts"
          "${aro}/plugins/autoresearch-context.ts"
          "${inputs.superpowers}/.opencode/plugins/superpowers.js"
        ]
        ++ config.programs.opencode.extraPlugins;
    };

    skills = autoresearchSkills;

    tui = {
      theme = "nord";
      scroll_acceleration = {
        enabled = true;
      };
    };
  };
}
