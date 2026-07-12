{
  config,
  lib,
  pkgs,
  ...
}: let
  substituters = [
    {
      url = "https://cache.nixos.org?priority=10";
      key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    }
    {
      url = "https://dsully.cachix.org?priority=20";
      key = "dsully.cachix.org-1:smJ/u8VCUmfyavfuZBNXhXhPDfryFeo+vhYT0BPEIQo=";
    }
    {
      url = "https://cache.numtide.com?priority=30";
      key = "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
    }
    {
      url = "https://nix-community.cachix.org?priority=35";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    }
    {
      url = "https://cache.lix.systems?priority=40";
      key = "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=";
    }
  ];

  # Platform-specific trusted users
  trusted_users =
    ["root" "dsully"]
    ++ (
      if pkgs.stdenv.isDarwin
      then ["@admin"]
      else ["@wheel"]
    );
in {
  options.system = {
    fullName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Dan Sully";
    };

    hostName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
    };

    userName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "dsully";
    };

    primaryGroup = lib.mkOption {
      type = lib.types.str;
      default =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "staff"
        else "dsully";
      description = "Primary group of the user.";
    };

    nixFlavor = lib.mkOption {
      type = lib.types.enum [
        "cppnix"
        "determinate"
        "lix"
      ];
      default = "lix";
    };

    nixSettings = lib.mkOption {
      type = lib.types.attrs;
      description = "Common nix settings shared across flavors";
    };

    # Cross-platform passwordless-sudo rules, defined once and rendered
    # natively per platform: nix-darwin only has `security.sudo.extraConfig`
    # (a string), while system-manager exposes the full NixOS
    # `security.sudo.extraRules`. `sudoLib` (below) adapts to both.
    sudoRules = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          users = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          groups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          runAs = lib.mkOption {
            type = lib.types.str;
            default = "ALL:ALL";
          };
          noPasswd = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          setEnv = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          commands = lib.mkOption {
            type = lib.types.listOf lib.types.str;
          };
        };
      });
      default = [];
      description = "Cross-platform sudo rules, rendered per platform.";
    };
  };

  config = {
    system.nixSettings =
      {
        accept-flake-config = true;
        allow-dirty = true;
        allow-symlinked-store = true;
        allowed-users = ["*"];
        always-allow-substitutes = true;
        builders-use-substitutes = true;
        connect-timeout = 5;
        cores = 0;
        experimental-features = [
          "daemon-trust-override"
          "flakes"
          "nix-command"
        ];
        http-connections = 0;
        keep-derivations = true;
        keep-going = true;
        keep-outputs = false;
        max-jobs = "auto";
        max-substitution-jobs = 128;
        narinfo-cache-negative-ttl = 3600;
        stalled-download-timeout = 20;
        substituters = map (x: x.url) substituters;
        trusted-public-keys = map (x: x.key) substituters;
        trusted-users = trusted_users;
        use-xdg-base-directories = true;
        warn-dirty = false;
      }
      // lib.optionalAttrs (config.system.nixFlavor == "determinate") {
        eval-cores = 0;
        experimental-features = [
          "blake3-hashes"
          "build-time-fetch-tree"
          "dynamic-derivations"
          "git-hashing"
        ];
        lazy-trees = true;
      };

    nixpkgs.config.allowUnfree = true;

    # `ttl` (mtr replacement) needs root for raw sockets. The `mtr` fish
    # wrapper resolves it to its /nix/store path before invoking sudo, so
    # this store-path glob matches. Applies on every host.
    system.sudoRules = [
      {
        users = [config.system.userName];
        commands = ["/nix/store/*/bin/ttl"];
      }
    ];

    # Adapters so a single `system.sudoRules` feeds both backends.
    _module.args.sudoLib = {
      # -> NixOS `security.sudo.extraRules` entries (system-manager).
      toExtraRules = map (rule: {
        inherit (rule) users groups runAs;
        commands =
          map (command: {
            inherit command;
            options = lib.optional rule.noPasswd "NOPASSWD" ++ lib.optional rule.setEnv "SETENV";
          })
          rule.commands;
      });

      # -> sudoers lines for nix-darwin `security.sudo.extraConfig`. Defaults
      # are applied here so callers may pass minimal rule literals.
      toText = rules:
        lib.concatMapStringsSep "\n" (
          rule: let
            users = rule.users or [];
            groups = rule.groups or [];
            runAs = rule.runAs or "ALL:ALL";
            noPasswd = rule.noPasswd or true;
            setEnv = rule.setEnv or false;
            who = lib.concatStringsSep ", " (users ++ map (g: "%${g}") groups);
            tag = lib.optionalString noPasswd "NOPASSWD:" + lib.optionalString setEnv "SETENV:";
          in "${who} ALL=(${runAs}) ${tag} ${lib.concatStringsSep ", " rule.commands}"
        )
        rules;
    };
  };
}
