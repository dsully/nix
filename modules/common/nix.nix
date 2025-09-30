{
  perSystem,
  pkgs,
  ...
}: let
  substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
    "https://cache.lix.systems"
    "https://dsully.cachix.org"
  ];
in {
  imports = [
    ../common/options.nix
  ];

  # In this flake: perSystem.self
  # In consuming flake: perSystem.upstream
  #
  # Debug: This will show what packages are available
  # packages = [
  #   (builtins.trace "Available packages: ${builtins.toJSON (builtins.attrNames (perSystem.upstream.self or perSystem.self))}")
  # ];
  _module.args.my.pkgs = pkgs.extend (_final: _prev: (perSystem.upstream or perSystem.self));

  nix = {
    enable = true;

    # Auto upgrade nix package
    package = pkgs.lixPackageSets.latest.lix;

    settings = {
      allow-dirty = true;
      allow-import-from-derivation = true;
      allow-symlinked-store = true;
      allow-unsafe-native-code-during-evaluation = true;
      always-allow-substitutes = true;
      builders-use-substitutes = true;

      # Enable flakes globally
      experimental-features = [
        "flakes"
        "nix-command"
        # "pipe-operator"
      ];
      extra-nix-path = "nixpkgs=flake:nixpkgs";

      # Don't limit the number of http connections.
      http-connections = 0;

      # Whether to keep building derivations when another build fails.
      keep-going = true;
      max-jobs = "auto";

      inherit substituters;
      trusted-substituters = substituters;

      trusted-public-keys = [
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "dsully.cachix.org-1:smJ/u8VCUmfyavfuZBNXhXhPDfryFeo+vhYT0BPEIQo="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = [
        "@admin"
        "@wheel"
        "dsully"
      ];

      # Conform to the XDG Base Directory Specification
      use-xdg-base-directories = true;

      warn-dirty = false;
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
  };
}
