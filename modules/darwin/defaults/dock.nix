{
  system = {
    defaults = {
      dock = {
        # Set Dock to auto-hide and remove the auto-hiding delay.
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;

        launchanim = false;

        # Wipe all (default) app icons from the Dock.
        persistent-apps = [];

        # Don’t show recent applications in Dock
        show-recents = false;

        # Show only open applications in the Dock
        static-only = true;

        # Setting the icon size of Dock items to 36 pixels for optimal size/screen-realestate
        tilesize = 48;

        # Hot corner actions . Valid values include:
        #
        # * `1`: Disabled
        # * `2`: Mission Control
        # * `3`: Application Windows
        # * `4`: Desktop
        # * `5`: Start Screen Saver
        # * `6`: Disable Screen Saver
        # * `7`: Dashboard
        # * `10`: Put Display to Sleep
        # * `11`: Launchpad
        # * `12`: Notification Center
        # * `13`: Lock Screen
        # * `14`: Quick Note
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };

      CustomUserPreferences = {
        "com.apple.dock" = {
          showAppExposeGestureEnabled = false;
          showLaunchpadGestureEnabled = false;
          showMissionControlGestureEnabled = false;

          # https://superuser.com/questions/1778079/disable-switching-window-on-different-desktop
          workspaces-auto-swoosh = true;
        };
      };
    };
  };
}
