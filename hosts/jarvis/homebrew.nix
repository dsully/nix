{
  homebrew = {
    onActivation = {
      cleanup = "uninstall";
      extraFlags = [
        "--force"
      ];
    };

    casks = [
      "anylist"
      "chatgpt"
      "discord"
      "downie"
      "fission"
      "google-chrome"
      "iina"
      "insta360-studio"
      "latest"
      "lm-studio"
      "macdive"
      "mist"
      "ogdesign-eagle"
      "protonvpn"
      "proxyman"
      "quicken"
      "retrobatch"
      "serverbuddy"
      "signal"
      "superduper"
      # Uncomment when 2.x is released
      # "syncthing-app"
      "tableplus"
      "tailscale-app"
      "telegram"
      "unifi-identity-endpoint"
      "whatsapp"
      "zipic"
    ];

    masApps = {
      "AVR Control" = 1059512196;
      "AirPlayable" = 6475483628;
      "AutoMounter" = 1160435653;
      "Black Out" = 1319884285;
      "Book Tracker" = 1496543317;
      "Brother P-touch Editor" = 1453365242;
      "Croissant" = 6670288979;
      "Dark Noise" = 1465439395;
      "Darkroom" = 953286746;
      "Discovery" = 1381004916;
      "DoubleMemory" = 6737529034;
      "Draw Things" = 6444050820;
      "FilmNoir" = 1528417240;
      "Flighty" = 1358823008;
      "Globetrotter" = 6469319235;
      "GoPro Quik" = 561350520;
      "Homie" = 1533590432;
      "Hyperduck" = 6444667067;
      "Infuse" = 1136220934;
      "Ivory" = 6444602274;
      "MetaImage" = 1397099749;
      "PDF Expert" = 1055273043;
      "Paprika Recipe Manager 3" = 1303222628;
      "Picview" = 6452016140;
      "Play" = 1596506190;
      "Prime Video" = 545519333;
      "QR Studio" = 6740007834;
      "Radiance" = 1573366225;
      "Reeder" = 6475002485;
      "Rules" = 6461118886;
      "SD Gallery" = 6445901857;
      "Screens 5" = 1663047912;
      "Secret Inbox" = 6462335670;
      "SmugMug" = 1115348888;
      "Sogni" = 6450021857;
      "Sortio" = 6737292062;
      "Starship" = 1530665887;
      "Tripsy" = 1429967544;
      "UnTrap" = 1637438059;
      "Zero Loss Compress" = 6738362427;
    };
  };
}
