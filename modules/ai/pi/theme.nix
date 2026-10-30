{
  config,
  lib,
  pkgs,
  piPath,
  ...
}: let
  jsonFormat = pkgs.formats.json {};

  nordTheme = {
    "$schema" = "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = "nord";

    # Var layer sources the Nord palette from colors.nix; the semantic `colors`
    # block below references these names.
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
      nordMuted = "#8b95a7";
      # Secondary UI text (widgets, hints, status lines); nord3 and nordMuted are too faint on nord0.
      nordSubtle = "#b4bccb";
      # Subtle Nord-tinted panel backgrounds (blend.* in colors.nix), replacing
      # the off-palette defaults for the custom-message and tool-error blocks.
      nordCustomBg = config.colors.blend.blue;
      nordErrorBg = config.colors.blend.red;
      nordCodeBg = config.colors.blend.turquoise;
    };

    colors = {
      accent = "nord8";
      border = "nord2";
      borderAccent = "nord8";
      borderMuted = "nord2";
      success = "nord14";
      error = "nord11";
      warning = "nord12";
      muted = "nordSubtle";
      dim = "nordSubtle";
      text = "nord6";
      thinkingText = "nord3";
      selectedBg = "nord1";
      userMessageBg = "nord1";
      userMessageText = "";
      customMessageBg = "nordCustomBg";
      customMessageText = "";
      customMessageLabel = "nord15";
      toolPendingBg = "nord1";
      toolSuccessBg = "nord0";
      toolErrorBg = "nordErrorBg";
      toolTitle = "nord8";
      toolOutput = "nord3";
      mdHeading = "nord8";
      mdLink = "nord9";
      mdLinkUrl = "nord7";
      mdCode = "nord14";
      mdCodeBlock = "nord4";
      mdCodeBlockBorder = "nord3Bright";
      mdCodeBlockBg = "nordCodeBg";
      mdQuote = "nordMuted";
      mdQuoteBorder = "nord3";
      mdHr = "nordMuted";
      mdListBullet = "nord8";
      toolDiffAdded = "nord14";
      toolDiffRemoved = "nord11";
      toolDiffContext = "nordMuted";
      syntaxComment = "nordMuted";
      syntaxKeyword = "nord9";
      syntaxFunction = "nord8";
      syntaxVariable = "nord7";
      syntaxString = "nord14";
      syntaxNumber = "nord15";
      syntaxType = "nord7";
      syntaxOperator = "nord9";
      syntaxPunctuation = "nord4";
      thinkingOff = "nord9";
      thinkingMinimal = "nord9";
      thinkingLow = "nord9";
      thinkingMedium = "nord9";
      thinkingHigh = "nord9";
      thinkingXhigh = "nord9";
      bashMode = "nord8";
    };

    export = {
      pageBg = "nord0";
      cardBg = "nord1";
      infoBg = "nord2";
    };
  };
in {
  config = lib.mkIf config.programs.pi-coding-agent.enable {
    home.file = {
      "${piPath}/themes/nord.json".source = jsonFormat.generate "pi-nord.json" nordTheme;
    };
  };
}
