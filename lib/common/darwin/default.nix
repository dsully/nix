{
  globals,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./activation.nix
    ./homebrew.nix
    ./packages.nix

    ./defaults/activity-monitor.nix
    ./defaults/contacts.nix
    ./defaults/control-center.nix
    ./defaults/dock.nix
    ./defaults/finder.nix
    ./defaults/global.nix
    ./defaults/google-chrome.nix
    ./defaults/keyboard.nix
    ./defaults/mail.nix
    ./defaults/messages.nix
    ./defaults/music.nix
    ./defaults/safari.nix
    ./defaults/siri.nix
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

    activationScripts.postUserActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      /usr/bin/killall Dock ControlCenter
    '';

    defaults = {
      #   CustomSystemPreferences = {
      #
      #     # https://apple.stackexchange.com/questions/91679/is-there-a-way-to-set-an-application-shortcut-in-the-keyboard-preference-pane-vi
      #     "com.apple.symbolichotkeys" = {
      #       AppleSymbolicHotKeys = {
      #         # Enable Command-` to switch windows.
      #         "27" = {
      #           enabled = true;
      #           value = {
      #             parameters = [
      #               96
      #               50
      #               1048576
      #             ];
      #             type = "standard";
      #           };
      #         };
      #         # Disable Command-M to minimize
      #         "223" = {
      #           enabled = false;
      #         };
      #       };
      #     };
      #   };
      #
      CustomUserPreferences = {
        "com.apple.DiskUtility" = {
          SidebarShowAllDevices = true;
          "OperationProgress DetailsVisible" = true;
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
        #
        #     # https://apple.stackexchange.com/questions/91679/is-there-a-way-to-set-an-application-shortcut-in-the-keyboard-preference-pane-vi
        #     "com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
        #       # Enable Command-` to switch windows.
        #       "27" = {
        #         enabled = true;
        #         value = {
        #           parameters = [
        #             96
        #             50
        #             1048576
        #           ];
        #           type = "standard";
        #         };
        #       };
        #       # Disable Command-M to minimize
        #       "223" = {
        #         enabled = false;
        #       };
        #     };
        #
        #     "com.apple.SoftwareUpdate" = {
        #       # Check for software updates daily, not just once per week
        #       ScheduleFrequency = 1;
        #
        #       # Download newly available updates in background
        #       AutomaticDownload = 1;
        #
        #       # Install System data files & security updates
        #       CriticalUpdateInstall = 1;
        #
        #       # Don't download apps purchased on other Macs
        #       ConfigDataInstall = 0;
        #
        #       # Enable the automatic update check
        #       AutomaticCheckEnabled = true;
        #     };
        #
        "com.apple.TextEdit" = {
          # Open and save files as UTF-8 in TextEdit
          PlainTextEncoding = 4;
          PlainTextEncodingForWrite = 4;

          # Use plain text mode for new TextEdit documents
          RichText = 0;
        };
        #
        #     "com.apple.TextInputMenu" = {
        #       visible = false; # Disable the flag / keyboard icon.
        #     };
        #
        #     "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
        #
        #     # Turn on app auto-update
        #     "com.apple.commerce".AutoUpdate = true;
        #
        "net.matthewpalmer.Rocket" = {
          "deactivated-apps" = [
            "Slack"
            "Xcode"
            "Terminal"
            "Quicken"
            "Code"
            "Finder"
            "Raycast"
            "Ghostty"
            "Screens 5"
            "Safari"
            "Google Chrome"
            "ChatGPT"
            "BoltAI"
            "Zed"
          ];
          "hot-key-b8-iaK-thyib-yoV-Kep-It" = ":";
          "launch-at-login" = 1;
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
