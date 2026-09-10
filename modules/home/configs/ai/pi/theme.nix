{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};

  piPath = "${config.home.homeDirectory}/.pi/agent";

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
      # Subtle Nord-tinted panel backgrounds (blend.* in colors.nix), replacing
      # the off-palette defaults for the custom-message and tool-error blocks.
      nordCustomBg = config.colors.blend.blue;
      nordErrorBg = config.colors.blend.red;
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
      thinkingOff = "nord2";
      thinkingMinimal = "nord3";
      thinkingLow = "nord10";
      thinkingMedium = "nord9";
      thinkingHigh = "nord15";
      thinkingXhigh = "nord7";
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

      "${piPath}/extensions/powerline-footer/theme.json".source = jsonFormat.generate "pi-powerline-footer-theme.json" {
        colors = {
          border = config.colors.black.bright;
          context = config.colors.gray.base;
          contextError = config.colors.red.base;
          contextWarn = config.colors.yellow.base;
          cost = config.colors.white.bright;
          gitClean = config.colors.green.base;
          gitDirty = config.colors.orange.base;
          model = config.colors.white.bright;
          path = config.colors.gray.bright;
          queue = config.colors.cyan.base;
          separator = config.colors.gray.base;
          shellMode = config.colors.green.base;
          thinking = config.colors.orange.base;
          thinkingLow = config.colors.blue.bright;
          thinkingMedium = config.colors.cyan.bright;
          thinkingMinimal = config.colors.blue.base;
          tokens = config.colors.gray.base;
        };
      };
    };
  };
}
