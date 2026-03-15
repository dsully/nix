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
  };
}
