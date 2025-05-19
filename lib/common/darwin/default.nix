{
  globals,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./homebrew.nix
    ./packages.nix

    ./defaults/activity-monitor.nix
    ./defaults/apps.nix
    ./defaults/contacts.nix
    ./defaults/control-center.nix
    ./defaults/dock.nix
    ./defaults/finder.nix
    ./defaults/global.nix
    ./defaults/keyboard.nix
    ./defaults/mail.nix
    ./defaults/messages.nix
    ./defaults/music.nix
    ./defaults/safari.nix
    ./defaults/siri.nix
    ./defaults/spotlight.nix
    ./defaults/trackpad.nix
  ];

  environment.etc."sudoers.d/custom".text = ''
    Defaults env_keep += "TERMINFO"
    Defaults timestamp_timeout=-1
  '';

  networking = {
    computerName = globals.host.name;
    hostName = globals.host.name;
  };


  system = {
    # Turn off NIX_PATH warnings now that we're using flakes
    checks.verifyNixPath = false;

    activationScripts.postActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      sudo -v

      /usr/bin/killall ControlCenter Dock SystemUIServer cfprefsd
      sudo /usr/bin/killall cfprefsd
    '';

    defaults = {
      CustomUserPreferences = {
        "com.apple.DiskUtility" = {
          "OperationProgress DetailsVisible" = true;
          advanced-image-options = true;
          DUDebugMenuEnabled = true;
          SidebarShowAllDevices = true;
        };

        #     NSGlobalDomain = {
        #       NSUseAnimatedFocusRing = false; # Disable the over-the-top focus ring animation
        #
        #       # Disable animations when opening and closing windows.
        #       NSAutomaticWindowAnimationsEnabled = false;
        #
        #       # Disable animations when opening a Quick Look window.
        #       QLPanelAnimationDuration = 0;
        #
        #       # Turn off auto-termination
        #       NSDisableAutomaticTermination = true;
        #     };
        #
        #     "com.apple.Accessibility" = {
        #       EnhancedBackgroundContrastEnabled = true;
        #     };
        #
        "com.apple.SoftwareUpdate" = {
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

        "com.apple.TextEdit" = {
          # Open and save files as UTF-8 in TextEdit
          PlainTextEncoding = 4;
          PlainTextEncodingForWrite = 4;

          # Use plain text mode for new TextEdit documents
          RichText = 0;
        };

        "com.apple.TextInputMenu" = {
          visible = false; # Disable the flag / keyboard icon.
        };

        "com.apple.TimeMachine" = {
            DoNotOfferNewDisksForBackup = true;
        };
      };

      LaunchServices = {
        LSQuarantine = false;
      };

      loginwindow = {
        GuestEnabled = false;
      };

      smb.NetBIOSName = globals.host.name;
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    primaryUser = globals.user.name;
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  users = {
    knownUsers = [globals.user.name];

    users.${globals.user.name} = {
      home = "/Users/${globals.user.name}";
      shell = pkgs.fish;
      uid = lib.mkDefault 501;
    };
  };
}
