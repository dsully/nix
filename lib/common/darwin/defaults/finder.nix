let
  # Sort icon views by name, show item info and minimize grid spacing in icon views.
  icon_view_settings = {
    arrangeBy = "name";
    gridSpacing = 1.0;
    iconSize = 64.0;
    showItemInfo = true;
  };
in {
  system = {
    defaults = {
      finder = {
        # Finder > Preferences > Show warning before changing an extension
        FXEnableExtensionChangeWarning = false;

        # Finder > View > As List
        FXPreferredViewStyle = "Nlsv";

        # Set ~ as the default location for new Finder windows
        NewWindowTarget = "Home";

        # Show icons for hard drives, servers, and removable media on the desktop.
        ShowExternalHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = true;
      };

      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;

          # Force the Finder to gather all metadata first
          UseBareEnumeration = 1;
        };

        "com.apple.finder" = {
          DesktopViewSettings = {
            IconViewSettings = icon_view_settings;
          };

          DisableAllAnimations = true;

          # Open folders in new Finder windows instead of tabs
          FinderSpawnTab = false;

          FK_StandardViewSettings = {
            IconViewSettings = icon_view_settings;
          };

          # Finder > Preferences > Show warning before removing from iCloud Drive
          FXEnableRemoveFromICloudDriveWarning = false;

          # Expand the following File Info panes: "General", "Open with", and "Sharing & Permissions"
          FXInfoPanesExpanded = {
            General = true;
            OpenWith = true;
            Privileges = true;
          };

          # Disable sidebar: Recent Tags
          ShowRecentTags = false;

          StandardViewSettings = {
            IconViewSettings = icon_view_settings;
          };

          WarnOnEmptyTrash = false;
        };

        # Enable AirDrop over Ethernet
        "com.apple.NetworkBrowser" = {
          BrowseAllInterfaces = true;
        };

        # Disable disk image verification.
        "com.apple.frameworks.diskimages" = {
          skip-verify = true;
          skip-verify-locked = true;
          skip-verify-remote = true;
        };

        "com.apple.screencapture" = {
          location = "~/Library/Mobile Documents/com~apple~CloudDocs/Screenshots";
          type = "png";
        };
      };
    };
  };
}
