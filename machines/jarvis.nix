{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      apple-photos-export
      autorebase
      bacon
      claude-code
      ghostscript_headless
      git-ai-commit
      nix-output-monitor
      pandoc
      reading-list-to-pinboard-rs
      # systemd-language-server
      turbo-commit
      werk
    ];
  };

  homebrew = {
    onActivation = {
      cleanup = "uninstall";
      extraFlags = [
        "--force"
      ];
    };

    casks = [
      "android-platform-tools"
      "anylist"
      "backblaze"
      "chatgpt"
      "discord"
      "downie"
      "fastmate"
      "fission"
      "google-chrome"
      "insta360-studio"
      "latest"
      "macdive"
      "mist"
      "mullvad-vpn"
      "ogdesign-eagle"
      "orion"
      "protonvpn"
      "proxyman"
      "quicken"
      "quickrecorder"
      "retrobatch"
      "signal"
      # "soulseek"
      "superduper"
      "syncthing"
      "tableplus"
      "tailscale"
      "telegram"
      "whatsapp"
      "zipic"
    ];

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas
    masApps = {
      "Acidity" = 6472630023;
      "AirPlayable" = 6475483628;
      "AllMyBatteries" = 1621263412;
      "AutoMounter" = 1160435653;
      "AVR Control" = 1059512196;
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
      "Hush" = 1544743900;
      "Hyperduck" = 6444667067;
      "Hyperspace" = 6739505345;
      "Infuse" = 1136220934;
      "Ivory" = 6444602274;
      "MetaImage" = 1397099749;
      "Paprika Recipe Manager 3" = 1303222628;
      "PDF Expert" = 1055273043;
      "Picview" = 6452016140;
      "Play" = 1596506190;
      "Prime Video" = 545519333;
      "QR Studio" = 6740007834;
      "Radiance" = 1573366225;
      "Reeder" = 1529448980;
      "Rules" = 6461118886;
      "Screens 5" = 1663047912;
      "SD Gallery" = 6445901857;
      "Secret Inbox" = 6462335670;
      "ServerCat" = 1501532023;
      "SmugMug" = 1115348888;
      "Sogni" = 6450021857;
      "Sortio" = 6737292062;
      "Starship" = 1530665887;
      "Subscriptions" = 1577082754;
      "Tripsy" = 1429967544;
      "Tuneful" = 6739804295;
      "UnTrap" = 1637438059;
      "Zero Loss Compress" = 6738362427;
    };

    taps = [
      # "homebrew/homebrew-core" = inputs.homebrew-core
      # "homebrew/homebrew-cask" = inputs.homebrew-cask
      "lihaoyun6/tap" # quickrecorder
      "rajiv/fastmate"
    ];
  };
}
