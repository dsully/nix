{
  ai,
  config,
  lib,
  pkgs,
  wrapperLib,
  ...
}: let
  cfg = config.programs.omp;

  jsonFormat = pkgs.formats.json {};
  yamlFormat = pkgs.formats.yaml {};

  configFile = yamlFormat.generate "omp-config.yml" cfg.settings;

  # omp joins PI_CONFIG_DIR onto $HOME, so the value is a home-relative path and
  # not an absolute one. It moves the whole root (agent dir, plugins, run, logs,
  # install-id), because omp never reads XDG_CONFIG_HOME itself. The XDG data,
  # state, and cache roots below then pull everything except the config back out
  # of ~/.config. See `packages/utils/src/dirs.ts` in oh-my-pi.
  ompConfigDir = "${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome}/omp";
  ompPath = "${config.xdg.configHome}/omp/agent";

  # omp redirects data/state/cache to $XDG_<kind>_HOME/omp only when that
  # directory already exists (this is all `omp config init-xdg` does), and it
  # checks on every start, so the roots are created before the config is written.
  xdgRoots = [
    "${config.xdg.cacheHome}/omp"
    "${config.xdg.dataHome}/omp"
    "${config.xdg.stateHome}/omp"
  ];

  # The session variable alone is not enough: a shell that never sources
  # hm-session-vars.sh (a launchd job, a `login -f`, an editor terminal) would
  # fall back to ~/.omp, which no longer exists, and omp dies acquiring the
  # config lock. Bake the value into the binary so every entry point agrees.
  # `--set-default` keeps an explicit PI_CONFIG_DIR (a second checkout, a test
  # root) working.
  # pname, version, and meta (including mainProgram) carry over from `package`.
  # `pkgs` is explicit because nix-wrapper-modules evaluates the wrapper against
  # a whole package set (same reason as packages/nh.nix).
  ompPackage = wrapperLib.wrapPackage {
    inherit pkgs;
    inherit (cfg) package;

    # `envDefault`, so an explicit PI_CONFIG_DIR still wins.
    envDefault.PI_CONFIG_DIR = ompConfigDir;
  };

  # omp expands `${VAR}` and `${VAR:-default}` in discovered MCP configs. The
  # typed schema emits the `{env:VAR}` form, so rewrite it.
  rewriteEnvPlaceholders = lib.replaceStrings ["{env:"] ["\${"];
  rewriteMcpValue = value:
    if builtins.isString value
    then rewriteEnvPlaceholders value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: rewriteMcpValue) value
    else if builtins.isList value
    then map rewriteMcpValue value
    else value;

  # Normalize via lib.hm.mcp.transformMcpServer to drop the typed schema's null
  # and empty-default fields. omp reads the `enabled` flag directly, so it is
  # kept. `addType` writes the explicit `stdio`/`http` transport tag that omp
  # validates against `command`/`url`.
  ompMcpServer = server:
    lib.hm.mcp.transformMcpServer {
      inherit server;
      extraTransforms = [
        lib.hm.mcp.addType
        rewriteMcpValue
      ];
    };

  ompMcpServers = lib.mapAttrs (_: ompMcpServer) config.programs.mcp.servers;

  # One file per marketplace agent, the omp counterpart of
  # `programs.opencode.agents`. omp resolves an agent by its frontmatter `name`,
  # so the attribute key only names the file.
  agentFiles =
    lib.mapAttrs' (name: text: {
      name = "${ompPath}/agents/${name}.md";
      value.text = text;
    })
    ai.ompAgents;

  # Slash commands, the omp counterpart of `programs.opencode.commands`. omp
  # reads the same Claude markdown shape (frontmatter `description`, `$ARGUMENTS`
  # and `$1`-style placeholders) and takes the command name from the filename.
  commandFiles =
    lib.mapAttrs' (name: text: {
      name = "${ompPath}/commands/${name}.md";
      value.text = text;
    })
    ai.commands;

  # omp auto-detects a built-in server when its root markers are in the cwd and
  # its binary resolves, so bashls, gopls, nil, rust-analyzer, and
  # typescript-native need no config: home installs each binary on PATH. Only the
  # two servers omp has no built-in entry for are declared here, and a config
  # merges onto the defaults rather than replacing them, so auto-detection of
  # every other server is unaffected.
  #
  # Both need the three required fields. emmylua-ls is not a rename of the
  # built-in `lua-language-server` entry, whose `settings.Lua` block is written
  # for that other binary; the built-in never starts anyway, because
  # lua-language-server is not installed.
  ompLspServers = {
    emmylua-ls = {
      inherit (ai.lsp.lua) command;
      fileTypes = [".lua"];
      rootMarkers = [
        ".emmyrc.json"
        ".luarc.json"
        ".luarc.jsonc"
        ".stylua.toml"
        "stylua.toml"
      ];
    };

    tombi = {
      inherit (ai.lsp.toml) command args;
      fileTypes = [".toml"];
      rootMarkers = [
        "tombi.toml"
        "Cargo.toml"
        "pyproject.toml"
        ".git"
      ];
    };
  };

  # Custom theme mirroring opencode's Nord palette (opencode packages/tui/src/theme/assets/nord.json, dark variant).
  #
  # omp already ships a built-in `dark-nord`, and the loader resolves built-ins
  # before ~/.omp/agent/themes, so a themes/dark-nord.json is shadowed and never
  # used. This ships under `nord` instead.
  #
  # The Nord palette itself is identical to omp's built-in; the semantic assignments below are re-pointed to
  # opencode's dark mappings wherever opencode defines a counterpart.
  #
  # Tokens with no opencode counterpart keep omp's Nord values.
  nordTheme = {
    name = "nord";

    # Var layer sources the Nord palette from colors.nix (the single source of
    # truth); the semantic `colors` block below references these names.
    vars = {
      nord0 = config.colors.black.dim;
      nord1 = config.colors.black.base;
      nord2 = config.colors.black.bright;
      nord3 = config.colors.gray.base;
      nord3Bright = config.colors.extra.fzfHl;
      nord4 = config.colors.white.dim;
      nord5 = config.colors.white.base;
      nord6 = config.colors.white.bright;
      nord7 = config.colors.cyan.base;
      nord8 = config.colors.cyan.bright;
      nord9 = config.colors.blue.base;
      nord10 = config.colors.blue.bright;
      nord11 = config.colors.red.base;
      nord12 = config.colors.orange.base;
      nord13 = config.colors.yellow.base;
      nord14 = config.colors.green.base;
      nord15 = config.colors.magenta.base;
      # opencode's dark textMuted/diffContext/comment tone; no Nord-palette equivalent.
      nordMuted = "#8b95a7";
    };

    colors = {
      accent = "nord8";
      border = "nord2";
      borderAccent = "nord8";
      borderMuted = "nord2";
      success = "nord14";
      error = "nord11";
      warning = "nord12";
      muted = "nordMuted";
      dim = "nord3";
      text = "nord6";
      thinkingText = "nord3";
      selectedBg = "nord1";
      userMessageBg = "nord1";
      userMessageText = "";
      customMessageBg = "#3c384f";
      customMessageText = "";
      customMessageLabel = "nord15";
      toolPendingBg = "nord1";
      toolSuccessBg = "nord0";
      toolErrorBg = "#3b2f31";
      toolText = "";
      toolTitle = "nord8";
      toolOutput = "nord3";
      mdHeading = "nord8";
      mdLink = "nord9";
      mdLinkUrl = "nord7";
      mdCode = "nord14";
      mdCodeBlock = "nord4";
      mdCodeBlockBorder = "nord3Bright";
      mdQuote = "nordMuted";
      mdQuoteBorder = "nord3";
      mdHr = "nordMuted";
      mdListBullet = "nord8";
      toolDiffAdded = "nord14";
      toolDiffRemoved = "nord11";
      toolDiffContext = "nordMuted";
      link = "nord8";
      syntaxComment = "nordMuted";
      syntaxKeyword = "nord9";
      syntaxFunction = "nord8";
      syntaxVariable = "nord7";
      syntaxString = "nord14";
      syntaxNumber = "nord15";
      syntaxType = "nord7";
      syntaxOperator = "nord9";
      syntaxPunctuation = "nord4";
      thinkingOff = "nord2";
      thinkingMinimal = "nord3";
      thinkingLow = "nord10";
      thinkingMedium = "nord9";
      thinkingHigh = "nord15";
      thinkingXhigh = "nord7";
      bashMode = "nord8";
      statusLineBg = "nord0";
      statusLineSep = "nord3";
      statusLineModel = "nord8";
      statusLinePath = "nord7";
      statusLineGitClean = "nord14";
      statusLineGitDirty = "nord13";
      statusLineContext = "nord9";
      statusLineSpend = "nord8";
      statusLineStaged = "nord14";
      statusLineDirty = "nord13";
      statusLineUntracked = "nord8";
      statusLineOutput = "nord12";
      statusLineCost = "nord12";
      statusLineSubagents = "nord8";
      pythonMode = "#f0c040";
    };

    export = {
      pageBg = "nord0";
      cardBg = "nord1";
      infoBg = "nord2";
    };
  };
in {
  # Merged copy of oh-my-pi's own home-manager module (nix/home-manager.nix).
  # Upstream takes the omp flake as `{ self }` and defaults `package` to
  # `self.packages.<system>.default`; this flake has no oh-my-pi input, so the
  # default comes from the `llm-agents` input instead.
  options.programs.omp = {
    enable = lib.mkEnableOption "OMP coding agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.omp;
      defaultText = lib.literalExpression "pkgs.llm-agents.omp";
      description = "OMP package to install.";
    };

    settings = lib.mkOption {
      type = lib.types.nullOr yamlFormat.type;
      default = null;
      description = ''
        Settings written declaratively to {file}`~/.omp/agent/config.yml`.
        On each `home-manager switch` the declared settings are copied into
        place as a writable regular file (not a read-only store symlink), so
        OMP can acquire its config lock and rewrite the file when persisting
        runtime changes (`/settings`, onboarding). Those runtime changes are
        overwritten by the declared values again on the next
        `home-manager switch`.
      '';
      example = {
        theme.dark = "titanium";
        startup.quiet = true;
      };
    };
  };

  config = lib.mkMerge [
    {programs.omp.enable = lib.mkDefault true;}

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = lib.hasPrefix "${config.home.homeDirectory}/" config.xdg.configHome;
          message = "programs.omp: omp resolves PI_CONFIG_DIR under $HOME, so xdg.configHome must be inside ${config.home.homeDirectory}.";
        }
      ];

      home = {
        packages = [ompPackage];

        # OMP rewrites its config at runtime and acquires an advisory lock on it
        # first; on macOS the lock backend creates an flock sidecar next to the
        # target file. A `home.file` store symlink is read-only and lives under
        # /nix/store, so both the lock and the atomic rewrite fail with EACCES
        # and break every launch. Copy a writable regular file instead.
        activation.ompConfig = lib.mkIf (cfg.settings != null) (
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            run mkdir -p ${lib.escapeShellArgs ([ompPath] ++ xdgRoots)}
            run install -m 600 ${configFile} "${ompPath}/config.yml"
          ''
        );

        sessionVariables.PI_CONFIG_DIR = ompConfigDir;

        file =
          agentFiles
          // commandFiles
          // {
            "${ompPath}/mcp.json" = lib.mkIf (ompMcpServers != {}) {
              source = jsonFormat.generate "omp-mcp.json" {
                mcpServers = ompMcpServers;
              };
            };

            "${ompPath}/lsp.json".source = jsonFormat.generate "omp-lsp.json" {
              servers = ompLspServers;
            };

            # Native user context file. It has the highest discovery priority, so
            # it shadows ~/.claude/CLAUDE.md and every other user-level context
            # file.
            "${ompPath}/AGENTS.md".text = ''
              ${builtins.readFile ./AGENTS.md}
              ${ai.rulesMarkdown}
            '';

            # Custom Nord theme mirroring opencode; selected via theme.dark
            # below. Named `nord` because the built-in `dark-nord` shadows any
            # themes/dark-nord.json.
            "${ompPath}/themes/nord.json".source = jsonFormat.generate "omp-nord.json" nordTheme;
          };
      };

      programs = {
        # omp reads native user skills from ~/.omp/agent/skills. The built-in
        # agent-skills targets do not cover that path, so declare it here.
        agent-skills.targets.omp = {
          dest = "${ompPath}/skills";
          structure = "symlink-tree";
        };

        omp.settings = {
          setupVersion = 2;

          astGrep.enabled = true;
          autolearn.enabled = true;
          commands.enableClaudeUser = true;
          composer.shape = "pi";
          defaultThinkingLevel = ai.models.large.reasoning_effort;
          dev.autoqa = false;
          display.showTokenUsage = false;

          edit = {
            mode = "hashline";
            autoRepair.enabled = true;
          };

          error.notify = "on";
          extendedContext = true;
          hideThinkingBlock = true;
          lsp.formatOnWrite = true;

          marketplace.autoUpdate = "off";
          memory.backend = "mnemopi";
          modelRoles.default = "${ai.models.large.provider}/${ai.models.large.model}";

          personality = "pragmatic";
          providers.memoryModel = "qwen3-1.7b";

          retry.waitForUsageReset = true;
          skills.enableSkillCommands = false;
          spelling.typoDetection = false;

          startup = {
            checkUpdate = false;
            quiet = true;
            setupWizard = false;
            changelogMode = "hidden";
          };

          statusLine = {
            preset = "custom";
            separator = "powerline-thin";
            sessionAccent = false;
            leftSegments = ["model" "context_pct" "context_total" "git"];
            rightSegments = [];
            segmentOptions = {
              model.showThinkingLevel = false;
              git = {
                showBranch = true;
                showStaged = false;
                showUnstaged = false;
                showUntracked = false;
              };
            };
          };

          steeringMode = "one-at-a-time";
          symbolPreset = "nerd";
          terminal.showProgress = true;

          theme = {
            dark = "nord";
            light = "light";
          };

          tools.approvalMode = "yolo";

          tui = {
            textSizing = true;
            reactions = false;
          };
        };
      };
    })
  ];
}
