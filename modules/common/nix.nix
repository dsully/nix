{
  config,
  lib,
  pkgs,
  ...
}: let
  commonSubstituters = [
    {
      url = "https://dsully.cachix.org?priority=30";
      key = "dsully.cachix.org-1:smJ/u8VCUmfyavfuZBNXhXhPDfryFeo+vhYT0BPEIQo=";
    }
    {
      url = "https://charmbracelet.cachix.org?priority=38";
      key = "charmbracelet.cachix.org-1:iA+l3/8TVJsKR9h28f7f0C0CYA9JjI24yJ8YlGabbkg=";
    }
    {
      url = "https://nix-darwin.cachix.org?priority=38";
      key = "nix-darwin.cachix.org-1:G6r3FhSkSwRCZz2d8VdAibhqhqxQYBQsY3mW6qLo5pA=";
    }
    {
      url = "https://numtide.cachix.org?priority=38";
      key = "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=";
    }
    {
      url = "https://cache.nixos.org?priority=40";
      key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    }
  ];

  determinateSubstituters = [
    {
      url = "https://cache.flakehub.com?priority=35";
      key = "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=";
    }
    {
      url = "https://install.determinate.systems?priority=35";
      key = "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=";
    }
  ];

  # Platform-specific trusted users
  trusted_users =
    ["dsully"]
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

    nixFlavor = lib.mkOption {
      type = lib.types.enum [
        "cppnix"
        "determinate"
        "lix"
      ];
      default = "determinate";
    };

    nixSettings = lib.mkOption {
      type = lib.types.attrs;
      description = "Common nix settings shared across flavors";
    };
  };

  config = {
    system.nixSettings =
      {
        allow-dirty = true;
        allowed-users = ["*"];
        builders-use-substitutes = true;
        connect-timeout = 5;
        cores = 0;
        experimental-features = [
          "blake3-hashes"
          "daemon-trust-override"
          "dynamic-derivations"
          "flakes"
          "git-hashing"
          "nix-command"
          "pipe-operators"
        ];
        http-connections = 0;
        keep-derivations = true;
        keep-going = true;
        keep-outputs = true;
        max-jobs = "auto";
        narinfo-cache-negative-ttl = 0;
        stalled-download-timeout = 20;
        substituters = map (x: x.url) (
          commonSubstituters
          ++ lib.optionals (config.system.nixFlavor == "determinate") determinateSubstituters
        );
        trusted-public-keys = map (x: x.key) (
          commonSubstituters
          ++ lib.optionals (config.system.nixFlavor == "determinate") determinateSubstituters
        );
        trusted-users = trusted_users;
        use-xdg-base-directories = true;
        warn-dirty = false;
      }
      // lib.optionals (config.system.nixFlavor == "determinate") {
        allow-import-from-derivation = true;
        allow-symlinked-store = true;
        allow-unsafe-native-code-during-evaluation = true;
        eval-cores = 0;
        experimental-features = ["build-time-fetch-tree"];
        lazy-trees = true;
      };

    nixpkgs = {
      config.allowUnfree = true;
    };
  };
}
