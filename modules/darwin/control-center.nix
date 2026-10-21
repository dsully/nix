{mkSystemModule, ...}:
mkSystemModule {
  name = "control-center";

  config = {
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
          "com.apple.systemuiserver" = {
            "NSStatusItem Visible com.apple.menuextra.TimeMachine" = false;
            "NSStatusItem Visible com.apple.menuextra.vpn" = false;

            dontAutoLoad = [
              "/System/Library/CoreServices/Menu Extras/AirPort.menu"
              "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"
            ];
          };
        };
      };
    };
  };
}
