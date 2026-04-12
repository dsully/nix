{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  aiLib = import ./lib.nix {inherit config inputs lib my perSystem pkgs;};
  aiAgents = import ./agents.nix {inherit aiLib inputs lib;};
in {
  home = {
    activation.rtkOpencodeHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${lib.getExe perSystem.llm-agents.rtk} init --global --opencode >/dev/null 2>&1 || true
    '';

    file."${config.xdg.binHome}/opencode" = {
      force = true;
      source = "${my.pkgs.meridian}/libexec/meridian/opencode-wrapper";
    };

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

  programs.opencode = {
    enable = true;
    package = perSystem.llm-agents.opencode;
    enableMcpIntegration = true;
    inherit (aiAgents) agents commands;

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

      lsp = lib.mkDefault (aiLib.opencodeLsp
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

      plugin = lib.mkDefault [
        "@mohak34/opencode-notifier@latest"
        # "opencode-claude-auth"
        "opencode-gemini-auth"
        # "opencode-with-claude"
        "${my.pkgs.meridian}/libexec/meridian/plugin/meridian.ts"
      ];
    };
    skills = {
      astral-uv = "${aiLib.acp}/plugins/astral/skills/uv";
      astral-ruff = "${aiLib.acp}/plugins/astral/skills/ruff";
      astral-ty = "${aiLib.acp}/plugins/astral/skills/ty";
    };

    tui = {
      theme = "nord";
      scroll_acceleration = {
        enabled = true;
      };
    };
  };
}
