{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.pi;
  inherit (lib) literalExample;

  # Need the package to access examples.
  piPackage = perSystem.llm-agents.pi;
  piPath = "${config.home.homeDirectory}/.pi/agent";
  jsonFormat = pkgs.formats.json {};

  defaultPackageExtensions = [
    "npm:pi-subagents@0.17.5"
    "npm:context-mode@1.0.89"
    "npm:pi-mcp-adapter@2.4.2"
  ];

  defaultNpmCommand =
    if cfg.packageManager == "bun"
    then [
      (lib.getExe pkgs.bun)
    ]
    else [
      "${cfg.nodejsPackage}/bin/npm"
    ];

  hasPackageExtensions = cfg.packageExtensions != [];

  piSettings =
    cfg.settings
    // lib.optionalAttrs hasPackageExtensions {
      packages = lib.unique ((cfg.settings.packages or []) ++ cfg.packageExtensions);
      inherit (cfg) npmCommand;
    };

  piImportNpmLock = pkgs.callPackage (pkgs.path + "/pkgs/build-support/node/import-npm-lock") {
    callPackages = pkgs.newScope {nodejs = cfg.nodejsPackage;};
  };

  piNodeModules =
    if cfg.nodeModulesRoot == null
    then null
    else
      piImportNpmLock.buildNodeModules {
        nodejs = cfg.nodejsPackage;
        npmRoot = cfg.nodeModulesRoot;
      };

  # Find the extensions path (it's nested in node_modules)
  extensionsPath =
    if builtins.pathExists "${piPackage}/examples/extensions"
    then "${piPackage}/examples/extensions"
    else if builtins.pathExists "${piPackage}/lib/node_modules/@earendil-works/pi-coding-agent/examples/extensions"
    then "${piPackage}/lib/node_modules/@earendil-works/pi-coding-agent/examples/extensions"
    else if builtins.pathExists "${piPackage}/lib/node_modules/pi-monorepo/examples/extensions"
    then "${piPackage}/lib/node_modules/pi-monorepo/examples/extensions"
    else null;

  # Map extension names to their file paths
  extensionFiles = {
    autoCommitOnExit = "auto-commit-on-exit.ts";
    bookmark = "bookmark.ts";
    claudeRules = "claude-rules.ts";
    confirmDestructive = "confirm-destructive.ts";
    customFooter = "custom-footer.ts";
    dirtyRepoGuard = "dirty-repo-guard.ts";
    gitCheckpoint = "git-checkpoint.ts";
    handoff = "handoff.ts";
    inlineBash = "inline-bash.ts";
    interactiveShell = "interactive-shell.ts";
    modelStatus = "model-status.ts";
    notify = "notify.ts";
    permissionGate = "permission-gate.ts";
    preset = "preset.ts";
    protectedPaths = "protected-paths.ts";
    qna = "qna.ts";
    sessionName = "session-name.ts";
    shutdownCommand = "shutdown-command.ts";
    snake = "snake.ts";
    ssh = "ssh.ts";
    statusLine = "status-line.ts";
    summarize = "summarize.ts";
    titlebarSpinner = "titlebar-spinner.ts";
    todo = "todo.ts";
    tools = "tools.ts";
    triggerCompact = "trigger-compact.ts";
  };

  # Generate list of built-in extension paths
  builtInExtensionsList = lib.filter (ext: cfg.builtInExtensions.${ext}) (builtins.attrNames extensionFiles);

  # Generate home.files entries for built-in extensions
  builtInExtensionFiles = lib.optionalAttrs (extensionsPath != null) (lib.listToAttrs (map (ext: {
      name = "${piPath}/extensions/${extensionFiles.${ext}}";
      value = {
        source = "${extensionsPath}/${extensionFiles.${ext}}";
      };
    })
    builtInExtensionsList));

  # Generate home.files entries for custom extensions
  customExtensionFiles = lib.listToAttrs (map (ext: {
      name = "${piPath}/extensions/${lib.baseNameOf ext}";
      value = {source = ext;};
    })
    cfg.extensions);

  customThemeFiles = lib.listToAttrs (map (theme: {
      name = "${piPath}/themes/${lib.baseNameOf theme}";
      value = {source = theme;};
    })
    cfg.themes);

in {
  options.programs.pi = {
    enable = lib.mkEnableOption "Pi AI coding assistant";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Settings for pi. These will be written to ~/.config/pi/agent/settings.json.
        See https://github.com/badlogic/pi-mono/blob/main/packages/pi-coding-agent/docs/settings.md
      '';
      example = literalExample ''
        {
          defaultProvider = "anthropic";
          defaultModel = "claude-sonnet-4-20250514";
          defaultThinkingLevel = "medium";
          hideThinkingBlock = true;
          theme = "dark";
          compaction = {
            enabled = true;
            reserveTokens = 16384;
            keepRecentTokens = 20000;
          };
        }
      '';
    };

    agentsMd = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional content for ~/.config/pi/agent/AGENTS.md.
        Use for global project instructions, conventions, and common commands.
        Set to null to disable (default).
      '';
    };

    systemMd = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional custom system prompt for ~/.config/pi/agent/SYSTEM.md.
        Replaces the default system prompt. Set to null to use default (default).
      '';
    };

    appendSystemMd = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional text to append to the system prompt via ~/.config/pi/agent/APPEND_SYSTEM.md.
        Set to null to disable (default).
      '';
    };

    customProviders = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Custom Pi model providers. When set, these are written to ~/.config/pi/agent/models.json.
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        List of paths to custom pi extensions to symlink into ~/.config/pi/agent/extensions/.
        These are in addition to any built-in extensions selected via `builtInExtensions`.
      '';
    };

    packageExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultPackageExtensions;
      apply = lib.unique;
      description = ''
        Pi package extension specs to install through Pi's package manager support.
        Values are written to settings.packages, for example "npm:pi-subagents@0.17.5".
      '';
    };

    npmCommand = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultNpmCommand;
      description = ''
        Command Pi should use when installing packageExtensions.
        Defaults to bun unless packageManager is set to "npm".
      '';
    };

    packageManager = lib.mkOption {
      type = lib.types.enum ["npm" "bun"];
      default = "bun";
      description = "Package manager used to build the default npmCommand for Pi package extensions.";
    };

    nodejsPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs_22;
      defaultText = literalExample "pkgs.nodejs_22";
      description = "Node.js package used when packageManager is \"npm\" and for lockfile-backed node_modules builds.";
    };

    nodeModulesRoot = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = literalExample "./pi/extensions";
      description = ''
        Optional directory containing package.json and package-lock.json for Pi extension dependencies.
        When set, its lockfile is built with import-npm-lock and linked to ~/.config/pi/agent/node_modules.
      '';
    };

    builtInExtensions = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Built-in pi extensions from the examples package";

          # Safety extensions
          permissionGate = lib.mkEnableOption "Prompts for confirmation before dangerous bash commands (rm -rf, sudo, etc.)";
          protectedPaths = lib.mkEnableOption "Blocks writes to protected paths (.env, .git/, node_modules/)";
          confirmDestructive = lib.mkEnableOption "Confirms before destructive session actions (clear, switch, fork)";
          dirtyRepoGuard = lib.mkEnableOption "Prevents session changes with uncommitted git changes";

          # Productivity extensions
          todo = lib.mkEnableOption "Todo list tool with /todos command and custom rendering";
          gitCheckpoint = lib.mkEnableOption "Creates git stash checkpoints at each turn for code restoration on fork";
          autoCommitOnExit = lib.mkEnableOption "Auto-commits on exit using last assistant message for commit message";

          # UI/UX extensions
          notify = lib.mkEnableOption "Desktop notifications via OSC 777 when agent finishes (Ghostty, iTerm2, WezTerm)";
          summarize = lib.mkEnableOption "Summarize conversation with GPT-5.2 and show in transient UI";
          statusLine = lib.mkEnableOption "Shows turn progress in footer via ctx.ui.setStatus()";
          titlebarSpinner = lib.mkEnableOption "Braille spinner animation in terminal title while the agent is working";
          modelStatus = lib.mkEnableOption "Shows model changes in status bar via model_select hook";
          customFooter = lib.mkEnableOption "Custom footer with git branch and token stats";

          # Interactive features
          inlineBash = lib.mkEnableOption "Expands !{command} patterns in prompts via input event transformation";
          interactiveShell = lib.mkEnableOption "Run interactive commands (vim, htop) with full terminal via user_bash hook";

          # Custom tools
          tools = lib.mkEnableOption "Interactive /tools command to enable/disable tools with session persistence";
          handoff = lib.mkEnableOption "Transfer context to a new focused session via /handoff <goal>";
          qna = lib.mkEnableOption "Extracts questions from last response into editor via ctx.ui.setEditorText()";

          # System prompt & compaction
          claudeRules = lib.mkEnableOption "Scans .claude/rules/ folder and lists rules in system prompt";
          triggerCompact = lib.mkEnableOption "Triggers compaction when context usage exceeds 100k tokens and adds /trigger-compact command";

          # Session management
          sessionName = lib.mkEnableOption "Name sessions for the session selector via setSessionName";
          bookmark = lib.mkEnableOption "Bookmark entries with labels for /tree navigation via setLabel";

          # Other useful extensions
          preset = lib.mkEnableOption "Named presets for model, thinking level, tools, and instructions via --preset flag";
          shutdownCommand = lib.mkEnableOption "Adds /quit command demonstrating ctx.shutdown()";

          # Games (for fun)
          snake = lib.mkEnableOption "Snake game with custom UI, keyboard handling, and session persistence";

          # Advanced features
          ssh = lib.mkEnableOption "Delegate all tools to a remote machine via SSH using pluggable operations";
        };
      };
      default = {};
      description = ''
        Enable built-in extensions from the pi-coding-agent examples package.
        These extensions are automatically copied to ~/.config/pi/agent/extensions/ when enabled.

        See https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/examples/extensions/README.md
      '';
    };

    skills = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        List of paths to custom pi skills to symlink into ~/.config/pi/agent/skills/.
      '';
    };

    prompts = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        List of paths to custom pi prompt templates to symlink into ~/.config/pi/agent/prompts/.
      '';
    };

    themes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        List of paths to custom pi themes to symlink into ~/.config/pi/agent/themes/.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      activation.createPiDirectories =
        lib.mkIf
        (cfg.extensions != [] || builtInExtensionsList != [] || cfg.nodeModulesRoot != null || cfg.skills != [] || cfg.prompts != [] || cfg.themes != []) ''
          run --quiet mkdir -p "${piPath}/extensions" "${piPath}/skills" "${piPath}/prompts" "${piPath}/themes"
        '';

      file =
        {
          "${piPath}/settings.json" = lib.mkIf (piSettings != {}) {
            source = jsonFormat.generate "pi-settings.json" piSettings;
          };

          "${piPath}/AGENTS.md" = lib.mkIf (cfg.agentsMd != null) {
            text = cfg.agentsMd;
          };

          "${piPath}/SYSTEM.md" = lib.mkIf (cfg.systemMd != null) {
            text = cfg.systemMd;
          };

          "${piPath}/APPEND_SYSTEM.md" = lib.mkIf (cfg.appendSystemMd != null) {
            text = cfg.appendSystemMd;
          };

          "${piPath}/agent/models.json" = lib.mkIf (cfg.customProviders != {}) {
            source = jsonFormat.generate "pi-models.json" {providers = cfg.customProviders;};
          };

          "${piPath}/node_modules" = lib.mkIf (cfg.nodeModulesRoot != null) {
            source = "${piNodeModules}/node_modules";
          };
        }
        // builtInExtensionFiles // customExtensionFiles // customThemeFiles;

      packages = [perSystem.llm-agents.pi];

      sessionVariables = {
        PI_CODING_AGENT_DIR = piPath;
        PI_SKIP_VERSION_CHECK = "1";
        PI_TELEMETRY = "0";
      };
    };

    # Warn if extensions are enabled but pi package doesn't have examples
    warnings =
      lib.optional (extensionsPath == null && builtInExtensionsList != [])
      "pi-coding-agent package doesn't have examples/extensions. Built-in extensions cannot be enabled.";
  };
}
