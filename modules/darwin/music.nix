{mkSystemModule, ...}:
mkSystemModule {
  name = "music";

  config = {
    system = {
      defaults = {
        CustomUserPreferences = {
          "com.apple.Music" = {
            userWantsPlaybackNotifications = false;
            optimizeSongVolume = false;
            showStoreInSidebar = 1;
            losslessEnabled = true;
          };
        };
      };
    };
  };
}
