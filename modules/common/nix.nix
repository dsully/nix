{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  substituters =
    [
      {
        url = "https://dsully.cachix.org";
        key = "dsully.cachix.org-1:smJ/u8VCUmfyavfuZBNXhXhPDfryFeo+vhYT0BPEIQo=";
      }
      {
        url = "https://charmbracelet.cachix.org";
        key = "charmbracelet.cachix.org-1:iA+l3/8TVJsKR9h28f7f0C0CYA9JjI24yJ8YlGabbkg=";
      }
      {
        url = "https://nix-community.cachix.org";
        key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
      }
      {
        url = "https://cache.nixos.org";
        key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
      }
      {
        url = "https://numtide.cachix.org";
        key = "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=";
      }
      {
        url = "https://install.determinate.systems";
        key = "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=";
      }
      {
        url = "https://cache.flakehub.com";
        key = "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=";
      }
    ]
    ++ (lib.optionals pkgs.stdenv.isDarwin [
      {
        url = "https://nix-darwin.cachix.org";
        key = "nix-darwin.cachix.org-1:G6r3FhSkSwRCZz2d8VdAibhqhqxQYBQsY3mW6qLo5pA=";
      }
    ]);

  # Platform-specific trusted users
  trusted_users =
    if pkgs.stdenv.isDarwin
    then ["@admin"]
    else ["@wheel"];
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

    nixFlavor = lib.mkOption {
      type = lib.types.enum [
        "cppnix"
        "determinate"
        "lix"
      ];
      default = "determinate";
    };

    substituters = lib.mkOption {
      default = substituters;
    };

    trusted_users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = trusted_users;
    };
  };

  config = {
    # In this flake: perSystem.self
    # In consuming flake: perSystem.upstream
    #
    # Debug: This will show what packages are available
    # packages = [
    #   (builtins.trace "Available packages: ${builtins.toJSON (builtins.attrNames (perSystem.upstream.self or perSystem.self))}")
    # ];
    _module.args.my.pkgs = pkgs.extend (_final: _prev: (perSystem.upstream or perSystem.self));

    nix = lib.mkMerge [
      {
        enable = config.system.nixFlavor != "determinate";

        settings =
          {
            experimental-features = [
              "flakes"
              "nix-command"
            ];

            allow-dirty = true;
            auto-allocate-uids = true;
            auto-optimise-store = true;
            builders-use-substitutes = true;

            extra-nix-path = "nixpkgs=flake:nixpkgs";

            # Don't limit the number of http connections.
            http-connections = 0;

            # Whether to keep building derivations when another build fails.
            keep-going = true;
            max-jobs = "auto";

            substituters = map (x: x.url) config.system.substituters;
            trusted-public-keys = map (x: x.key) config.system.substituters;
            trusted-users = config.system.trusted_users;

            narinfo-cache-negative-ttl = 0;
            warn-dirty = false;

            use-xdg-base-directories = true;
          }
          // (lib.mkIf (config.system.nixFlavor != "lix") {download-buffer-size = 268435456;});
      }

      (lib.mkIf (config.system.nixFlavor == "cppnix") {
        package = pkgs.nixVersions.latest;
      })

      # https://lix.systems/add-to-config/
      (lib.mkIf (config.system.nixFlavor == "lix") {
        package = pkgs.lixPackageSets.latest.lix;
      })

      (lib.mkIf (config.system.nixFlavor == "determinate") {
        package = perSystem.determinate.packages.${config.nixpkgs.system}.default;
        settings.lazy-trees = true;
      })
    ];

    nixpkgs = {
      config.allowUnfree = true;
    };
  };
}
