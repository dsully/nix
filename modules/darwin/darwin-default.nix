{
  config,
  inputs,
  lib,
  mkSystemModule,
  pkgs,
  sudoLib,
  ...
}: let
  inherit (config.system) hostName;
in
  mkSystemModule {
    name = "darwin-default";

    config = rec {
      documentation = {
        doc.enable = false;
        info.enable = false;
      };

      environment = {
        profiles = lib.mkOrder 700 ["\$HOME/.local/state/nix/profile"];
        shells = [pkgs.fish];

        systemPackages = [
          pkgs.fish
          pkgs.just
        ];
      };

      networking = {
        computerName = hostName;
        inherit hostName;
      };

      nix = lib.mkMerge [
        {
          optimise.automatic = lib.mkIf (config.system.nixFlavor == "cppnix") true;

          registry = lib.mapAttrs (_: value: {flake = value;}) (
            lib.filterAttrs (_: value: value ? _type && value._type == "flake") inputs
          );

          settings.nix-path = lib.mapAttrsToList (name: _: "${name}=flake:${name}") (
            lib.filterAttrs (_: value: value ? _type && value._type == "flake") inputs
          );
        }

        (lib.mkIf (config.system.nixFlavor == "cppnix") {
          enable = true;
          package = pkgs.nixVersions.latest;
        })

        (lib.mkIf (config.system.nixFlavor == "determinate") {
          enable = false;
        })
      ];

      nixpkgs.hostPlatform = "aarch64-darwin";

      programs.nh = {
        enable = true;
        clean = {
          inherit (config.nix) enable;
        };
        flake = "/Users/${config.system.userName}/.config/nix";
      };

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
          AcceptEnv SSH_CLIENT_HOME SSH_CLIENT_MOUNT SSH_CLIENT_OS
          StreamLocalBindUnlink yes
        '';
      };

      system = rec {
        activationScripts = {
          # Disable nix-darwin features I don't care about.
          applications.text = lib.mkForce "";
          fonts.text = lib.mkForce "";
          nvram.text = lib.mkForce "";

          postActivation.text =
            # bash
            ''
              # Following line should allow us to avoid a logout/login cycle
              sudo -u ${primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

              chflags nohidden ~/Library /Volumes
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
            NSGlobalDomain = {
              NSUseAnimatedFocusRing = false; # Disable the over-the-top focus ring animation

              NSAutomaticWindowAnimationsEnabled = true;

              # Disable animations when opening a Quick Look window.
              QLPanelAnimationDuration = 0;

              # Turn off auto-termination
              NSDisableAutomaticTermination = true;
            };

            "com.apple.Accessibility" = {
              EnhancedBackgroundContrastEnabled = false;
            };

            "com.apple.TextInputMenu" = {
              visible = false; # Disable the flag / keyboard icon.
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
      };

      security = {
        pam.services.sudo_local = {
          touchIdAuth = true;
          reattach = true;
        };

        sudo.extraConfig = let
          # Darwin-specific rules; cross-platform ones come from system.sudoRules.
          darwinRules = [
            {
              groups = ["admin"];
              commands = [
                "/bin/launchctl"
                "/nix/store/*/activate"
                "/nix/var/nix/profiles/default/bin/nix*"
                "/run/current-system/sw/bin/darwin-rebuild"
                "/run/current-system/sw/bin/nix*"
              ];
            }
          ];
        in ''
          ${sudoLib.toText (config.system.sudoRules ++ darwinRules)}

          # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
          Defaults env_keep+=SSH_AUTH_SOCK

          Defaults timestamp_timeout=-1
        '';
      };

      users = {
        knownGroups = ["onepassword-secrets"];
        knownUsers = [system.primaryUser];

        groups.onepassword-secrets = {
          gid = 600;
          members = [system.primaryUser];
        };

        users.${system.primaryUser} = {
          home = "/Users/${system.primaryUser}";
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
    };
  }
