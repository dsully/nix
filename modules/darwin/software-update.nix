{mkSystemModule, ...}:
mkSystemModule {
  name = "software-update";

  config = {
    system.defaults.CustomUserPreferences."com.apple.SoftwareUpdate" = {
      # Check for software updates daily, not just once per week
      ScheduleFrequency = 1;

      # Download newly available updates in background
      AutomaticDownload = 1;

      # Install System data files & security updates
      CriticalUpdateInstall = 1;

      # Don't download apps purchased on other Macs
      ConfigDataInstall = 0;

      # Enable the automatic update check
      AutomaticCheckEnabled = true;
    };
  };
}
