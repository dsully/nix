{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (config.system) hostName;
in rec {
  imports = [
    ../common/nix.nix
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

  documentation = {
     doc.enable = false;
     info.enable = false;
  };

  environment = {
    profiles = lib.mkOrder 700 [ "\$HOME/.local/state/nix/profile" ];
    shells = [pkgs.fish];

    systemPackages = [
        pkgs.cachix
        pkgs.fish
        pkgs.just
        pkgs.nh
    ];
  };

  networking = {
    computerName = hostName;
    inherit hostName;
  };

  nix = lib.mkMerge [
    {
      nixPath = lib.mapAttrsToList (name: _: "${name}=flake:${name}") (
        lib.filterAttrs (_: value: value ? _type && value._type == "flake") inputs
      );

      optimise.automatic = lib.mkIf (config.system.nixFlavor != "determinate") true;

      registry = lib.mapAttrs (_: value: {flake = value;}) (
        lib.filterAttrs (_: value: value ? _type && value._type == "flake") inputs
      );

      settings = config.system.nixSettings;
    }

    (lib.mkIf (config.system.nixFlavor == "cppnix") {
      enable = true;
      package = pkgs.nixVersions.latest;
      settings.download-buffer-size = 268435456;
    })

    # https://lix.systems/add-to-config/
    (lib.mkIf (config.system.nixFlavor == "lix") {
      enable = true;
      package = pkgs.lixPackageSets.latest.lix;
    })

    (lib.mkIf (config.system.nixFlavor == "determinate") {
      enable = false;
    })
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };

    info.enable = lib.mkForce false;
  };

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

        # Spotlight exclusions for Electron apps (reduces mds_stores CPU usage)
        # Note: postActivation runs as root, so we must use absolute paths
        USER_HOME="/Users/${config.system.primaryUser}"
        SPOTLIGHT_EXCLUSIONS=(
          "$USER_HOME/Library/Application Support/1Password"
          "$USER_HOME/Library/Application Support/Discord"
          "$USER_HOME/Library/Application Support/Eagle"
          "$USER_HOME/Library/Application Support/Fastmail"
          "$USER_HOME/Library/Application Support/Google/Chrome"
          "$USER_HOME/Library/Application Support/Granola"
          "$USER_HOME/Library/Application Support/LM Studio"
          "$USER_HOME/Library/Application Support/Marco"
          "$USER_HOME/Library/Application Support/Raindrop.io"
          "$USER_HOME/Library/Application Support/Signal"
          "$USER_HOME/Library/Application Support/Slack"
          "$USER_HOME/Library/Caches"
          "$USER_HOME/.cargo"
          "$USER_HOME/.rustup"
          "$USER_HOME/.npm"
          "$USER_HOME/.pnpm"
        )

        for dir in "''${SPOTLIGHT_EXCLUSIONS[@]}"; do
          if [ -d "$dir" ]; then
            # Add .metadata_never_index file to prevent Spotlight indexing
            touch "$dir/.metadata_never_index"
          fi
        done

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

        NSGlobalDomain = {
          NSUseAnimatedFocusRing = false; # Disable the over-the-top focus ring animation

          # Disable animations when opening and closing windows.
          NSAutomaticWindowAnimationsEnabled = false;

          # Disable animations when opening a Quick Look window.
          QLPanelAnimationDuration = 0;

          # Turn off auto-termination
          NSDisableAutomaticTermination = true;
        };

        "com.apple.Accessibility" = {
          EnhancedBackgroundContrastEnabled = true;
        };

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
friday"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGr3JjNRLsHjC1QgSPT/Qb25tTC/NbOl0zuJIraRfUXg zap"
        ];
      };
    };
  };
}
