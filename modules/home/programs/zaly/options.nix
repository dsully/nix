{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;

  jsonFormat = pkgs.formats.json {};

  reasoningEffort = types.enum ["off" "minimal" "low" "medium" "high" "xhigh" "max"];

  # A typed, optional (unset = null) config field. Null fields are stripped
  # before the config is written, so they fall back to zaly's own defaults.
  opt = type: description:
    mkOption {
      type = types.nullOr type;
      default = null;
      inherit description;
    };
in {
  options.programs.zaly = {
    enable = lib.mkEnableOption "zaly, a terminal AI coding agent";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The zaly package to install. Null installs no package, e.g. when the
        binary is provided elsewhere.
      '';
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = {};
      description = ''
        Freeform settings written to {file}`$XDG_CONFIG_HOME/zaly/config.json`.
        This is the escape hatch for keys without a dedicated typed option; the
        typed options below take precedence on overlap.
      '';
      example = lib.literalExpression ''
        {
          keymap."ctrl+g" = "composer.submit";
          resources."my-pack".enabled = false;
        }
      '';
    };

    model = opt types.str "Default model to use for the agent.";
    reasoning = opt reasoningEffort "Default reasoning effort.";
    tools = opt (types.listOf types.str) "Tools enabled for the agent.";
    plugins = opt (types.listOf types.str) "TypeScript plugins to load.";

    ui = {
      mode = opt (types.enum ["scrollback" "fullscreen"]) ''
        scrollback renders into native terminal history; fullscreen uses a
        dedicated app viewport with a fixed footer.
      '';
      theme = opt types.str "Theme name or path to a custom theme file.";
      images = opt types.bool "Render images when the terminal supports it.";
      reasoning = opt types.bool "Show the reasoning trace in the UI.";
      copyOnSelect = opt types.bool "Copy the active selection on select.";
      collapsedTools = opt (types.listOf types.str) "Tools whose result body is hidden in the UI.";
      listHeight = opt types.int "Maximum visible rows in selection lists (pickers, autocomplete).";
      treeHeight = opt types.int "Maximum visible rows in the session tree.";
      sessionTree = opt (types.listOf (types.enum ["assistant" "reasoning" "tools" "system"])) ''
        Which message kinds appear in the session tree.
      '';
    };

    permissions = {
      preset = opt (types.enum ["strict" "readonly" "permissive" "yolo"]) "Permissions preset.";
      allow = opt (types.listOf types.str) "Rules that are always allowed.";
      deny = opt (types.listOf types.str) "Rules that are always denied.";
      ask = opt (types.listOf types.str) "Rules that always prompt.";
    };

    skills = {
      enabled = opt types.bool "Allow skills to be used by the agent.";
      actions = opt types.bool "Show skill actions.";
      actionPrefix = opt types.str "Prefix for skill actions, e.g. `skill:`.";
    };

    commands = {
      actionPrefix = opt types.str "Prefix for command actions.";
      bash = opt types.bool "Allow bash execution in commands.";
      expr = opt types.bool "Allow JS expressions in command templates.";
    };

    compaction = {
      enabled = opt types.bool "Enable automatic compaction when context fills.";
      keepTokens = opt types.int "Tokens of existing messages to preserve in context.";
      reasoning = opt reasoningEffort "Reasoning effort for the compaction summary.";
      summaryTokens = opt types.int "Maximum tokens for the generated summary.";
      threshold = opt types.float "Context-usage ratio that triggers compaction.";
    };

    masking = {
      enabled = opt types.bool "Enable masking of large tool results.";
      keepTurns = opt types.int "Recent turns kept unmasked regardless of score.";
      minTokens = opt types.int "Minimum tool-result size eligible for masking.";
      delta = opt types.float "How far above the target ratio triggers a masking pass.";
      target = opt types.float "Target used/limit token ratio to reach by masking.";
    };

    system = {
      bash = opt (types.listOf types.str) "Command used by the bash tool.";
      git = opt (types.listOf types.str) "Command used for git packs.";
      npm = opt (types.listOf types.str) "Package-manager command used for npm packs.";
    };
  };
}
