{
  config,
  lib,
  pkgs,
  ...
}: let
  substituters = [
    {
      url = "https://dsully.cachix.org?priority=30";
      key = "dsully.cachix.org-1:smJ/u8VCUmfyavfuZBNXhXhPDfryFeo+vhYT0BPEIQo=";
    }
    {
      url = "https://charmbracelet.cachix.org?priority=38";
      key = "charmbracelet.cachix.org-1:iA+l3/8TVJsKR9h28f7f0C0CYA9JjI24yJ8YlGabbkg=";
    }
    {
      url = "https://nix-community.cachix.org?priority=40";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    }
    {
      url = "https://cache.numtide.com?priority=35";
      key = "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
    }
    {
      url = "https://cache.nixos.org?priority=40";
      key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
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
        builders-use-substitutes = true;
        connect-timeout = 5;
        cores = 0;
        experimental-features = [
          "daemon-trust-override"
          "flakes"
          "nix-command"
          "pipe-operator"
        ];
        http-connections = 0;
        keep-derivations = true;
        keep-going = true;
        keep-outputs = true;
        max-jobs = "auto";
        narinfo-cache-negative-ttl = 0;
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

    nixpkgs = {
      config.allowUnfree = true;

      overlays = [
        (_final: prev: {
          python313Packages = prev.python313Packages.override {
            overrides = _pyFinal: pyPrev: {
              mcp = pyPrev.mcp.overrideAttrs (_old: {
                doCheck = false;
                postPatch = "";
              });
            };
          };
        })
      ];
    };
  };
}
