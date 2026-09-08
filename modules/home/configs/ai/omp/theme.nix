{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.omp;

  jsonFormat = pkgs.formats.json {};

  ompPath = "${config.xdg.configHome}/omp/agent";

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
  # Custom Nord theme mirroring opencode; selected via `theme.dark` in omp.nix.
  # Named `nord` because the built-in `dark-nord` shadows any themes/dark-nord.json.
  config = lib.mkIf cfg.enable {
    home.file."${ompPath}/themes/nord.json".source = jsonFormat.generate "omp-nord.json" nordTheme;
  };
}
