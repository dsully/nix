{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.system) hostName;
in rec {
  imports = [
    ./homebrew.nix

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

  environment = {
    # Avoid using programs.fish.enable = true, as that forces either
    # babelFish or foreign-env, both of which have significant startup cost.
    shells = [pkgs.fish];

    systemPackages = [
      pkgs.fish
    ];
  };

  networking = {
    computerName = hostName;
    inherit hostName;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  services.openssh = {
    enable = true;
    extraConfig = ''
      # Allow xdg-open-svc to work.
      AcceptEnv SSH_CLIENT_HOME SSH_CLIENT
      StreamLocalBindUnlink yes
    '';
  };

  system = rec {
    activationScripts = {
      # Disable nix-darwin features I don't care about.
      applications.text = lib.mkForce "";
      fonts.text = lib.mkForce "";
      nvram.text = lib.mkForce "";

      postActivation.text = ''
        # Following line should allow us to avoid a logout/login cycle
        sudo -u ${primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

        chflags nohidden ~/Library /Volumes

        # /usr/bin/killall ControlCenter Dock SystemUIServer cfprefsd
      '';
    };

    # Disable nix-darwin features I don't care about.
    build = {
      applications = lib.mkForce "";
      fonts = lib.mkForce "";
    };

    # Turn off NIX_PATH warnings now that we're using flakes
    checks.verifyNixPath = false;

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

      smb.NetBIOSName = hostName;
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    primaryUser = config.system.userName;

    stateVersion = 6;
  };

  security = {
    pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = true;
    };

    sudo.extraConfig = let
      commands = [
        "/bin/launchctl"
        "/nix/store/*/activate"
        "/nix/var/nix/profiles/default/bin/nix*"
        "/run/current-system/sw/bin/darwin-rebuild"
        "/run/current-system/sw/bin/nix*"
      ];
      commandsString = builtins.concatStringsSep ", " commands;
    in ''
      %admin ALL=(ALL:ALL) NOPASSWD: ${commandsString}

      # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
      Defaults env_keep+=SSH_AUTH_SOCK

      Defaults timestamp_timeout=-1
    '';
  };

  users = {
    knownUsers = [system.primaryUser];

    users.${system.primaryUser} = {
      ignoreShellProgramCheck = true;
      shell = pkgs.fish;
      uid = lib.mkDefault 501;

      openssh.authorizedKeys = {
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4sDwDRuvlgW8AYzUsPoEyBxeJjl+ZpR3ScuCVg1gfL jarvis"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGC8/dtnUtRtj7vRv7StxW0xQ+VwfoBkenADsOpvxUAD server"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAwTWYLzOamYF5oiR5UmDAVrg1cJjSGoHD7L9oSpEELI0s8EJHQ9kNkse5Kg9qFYyJr5guTUfktekbwf6Vl2USs=
stelvio"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGr3JjNRLsHjC1QgSPT/Qb25tTC/NbOl0zuJIraRfUXg zap"
        ];
      };
    };
  };
}
