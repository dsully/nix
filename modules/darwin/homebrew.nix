{config, ...}: {
  environment = {
    systemPath = [config.homebrew.brewPrefix];
    variables = {
      HOMEBREW_BAT = "1";
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_COMPAT = "1";
      HOMEBREW_NO_ENV_HINTS = "1";
      HOMEBREW_PREFIX = config.homebrew.brewPrefix;
    };
  };

  homebrew = {
    enable = true;

    # Don't quarantine apps installed by homebrew with gatekeeper
    caskArgs.no_quarantine = true;

    global.autoUpdate = false;
    greedyCasks = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
    };

    brews = [
      "mas"
      "rust-mcp-filesystem"
    ];

    casks = [
      "1password"
      # "boltai"
      "cleanshot"
      "daisydisk"
      "dash"
      "font-monaspace"
      "fastmail"
      "ghostty"
      "keka"
      "little-snitch"
      "lunar"
      "monodraw"
      "osaurus"
      "processspy"
      "raindropio"
      "rapidapi"
      "raycast"
      "retcon"
      "rocket"
      "soulver"
      "stay"
      "suspicious-package"
      "tableplus"
      "tower"
      "transmit"
      "typora"
      # Can this replace RapidAPI?
      "yaak"
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
      "iPreview" = 1519213509;
      "JSONPeep" = 1458969831;
      "Kagi Search" = 1622835804;
      "MarkChart" = 6475648822;
      "One Thing" = 1604176982;
      "Parcel" = 375589283;
      "Patterns" = 429449079;
      "Protego" = 6737959724;
      "Refined GitHub" = 1519867270;
      "Save to Raindrop.io" = 1549370672;
      "Slack" = 803453959;
      "TestFlight" = 899247664;
      "Text Lens" = 6743369285;
      "TrashMe 3" = 1490879410;
      "Tuneful" = 6739804295;
      "Userscripts" = 1463298887;
      "WiFi Signal" = 525912054;
      "Wipr" = 1662217862;
      "WordService" = 899972312;
      "Yoink" = 457622435;
    };

    taps = [
      "rust-mcp-stack/tap"
    ];
  };
}
