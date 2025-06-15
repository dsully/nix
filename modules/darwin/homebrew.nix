{pkgs, ...}: {
  environment = {
    variables = {
      HOMEBREW_BAT = "1";
      HOMEBREW_BUNDLE_NO_LOCK = "1";
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_COMPAT = "1";
      HOMEBREW_NO_ENV_HINTS = "1";
    };

    systemPackages = [
      pkgs.mas
    ];
  };

  homebrew = {
    enable = true;

    # Don't quarantine apps installed by homebrew with gatekeeper
    caskArgs.no_quarantine = true;

    global.autoUpdate = false;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
    };

    brews = [
    ];

    casks = [
      "1password"
      # "adguard"
      "bartender"
      "boltai"
      "cleanshot"
      "daisydisk"
      "dash"
      "font-monaspace"
      "ghostty"
      "keka"
      "little-snitch"
      "lm-studio"
      "lunar"
      "monodraw"
      "powerflow"
      "processspy"
      "raindropio"
      "rapidapi"
      "raycast"
      "renamer"
      "rocket"
      "soulver"
      "stay"
      "suspicious-package"
      "tableplus"
      "tower"
      "transmit"
      "typora"
      "zed"
    ];

    masApps = {
      "1Password for Safari" = 1569813296;
      "Amphetamine" = 937984704;
      "Bonjourr Startpage" = 1615431236;
      "CleanMyKeyboard" = 6468120888;
      "Color Picker" = 1545870783;
      "CotEditor" = 1024640650;
      "Dato" = 1470584107;
      "DevCleaner" = 1388020431;
      "File Icons for GitHub and GitLab" = 1631366167;
      "Hyperspace" = 6739505345;
      "JSONPeep" = 1458969831;
      "Kagi Search" = 1622835804;
      "MarkChart" = 6475648822;
      "One Thing" = 1604176982;
      "Parcel" = 639968404;
      "Patterns" = 429449079;
      "Protego" = 6737959724;
      "Refined GitHub" = 1519867270;
      "Save to Raindrop.io" = 1549370672;
      "Slack" = 803453959;
      "StopTheMadness Pro" = 6471380298;
      "Taska" = 6741809383;
      "TestFlight" = 899247664;
      "Text Lens" = 6743369285;
      "TrashMe 3" = 1490879410;
      "Tuneful" = 6739804295;
      "WiFi Signal" = 525912054;
      "Wipr" = 1662217862;
      "WordService" = 899972312;
      "Xcode" = 497799835;
      "Yoink" = 457622435;
      "iPreview" = 1519213509;
    };

    taps = [
      "lzt1008/powerflow"
    ];
  };
}
