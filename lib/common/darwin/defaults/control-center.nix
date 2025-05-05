{
  system = {
    defaults = {
      controlcenter = {
        AirDrop = false;
        BatteryShowPercentage = false;
        Bluetooth = false;
        Display = false;
        FocusModes = false;
        NowPlaying = false;
        Sound = false;
      };

      CustomUserPreferences = {
        "com.apple.Siri" = {
          StatusMenuVisible = 0;
        };

        "com.apple.Spotlight" = {
          "NSStatusItem Visible Item-0" = false;
        };

        "com.apple.systemuiserver" = {
          "NSStatusItem Visible com.apple.menuextra.appleuser" = false;
          "NSStatusItem Visible com.apple.menuextra.bluetooth" = true;
          "NSStatusItem Visible com.apple.menuextra.clock" = false;
          "NSStatusItem Visible com.apple.menuextra.TimeMachine" = false;
          "NSStatusItem Visible com.apple.menuextra.volume" = false;
          "NSStatusItem Visible com.apple.menuextra.vpn" = false;

          dontAutoLoad = [
            "/System/Library/CoreServices/Menu Extras/AirPort.menu"
            "/System/Library/CoreServices/Menu Extras/Clock.menu"
            "/System/Library/CoreServices/Menu Extras/Displays.menu"
            "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"
            "/System/Library/CoreServices/Menu Extras/User.menu"
            "/System/Library/CoreServices/Menu Extras/Volume.menu"
            "/System/Library/CoreServices/Menu Extras/WWAN.menu"
          ];
        };
      };
    };
  };
}
