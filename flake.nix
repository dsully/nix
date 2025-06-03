{
  description = "Nix for macOS configuration";

  ##################################################################################################################
  #
  # Want to know Nix in details? Looking for a beginner-friendly tutorial?
  # Check out https://github.com/ryan4yin/nixos-and-flakes-book !
  #
  ##################################################################################################################

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index.url = "github:nix-community/nix-index";
    nix-index.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";

    nh.url = "github:nix-community/nh";
    nh.inputs.nixpkgs.follows = "nixpkgs";

    dsully.url = "github:dsully/nur";
    dsully.inputs.nixpkgs.follows = "nixpkgs";
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs = inputs @ {
    nixpkgs,
    nix-darwin,
    home-manager,
    system-manager,
    ...
  }: let
    globals = {
      host = {};
      user = {
        name = "dsully";
      };
    };

    # Generic function to create system configurations
    mkDarwin = {
      system ? "aarch64-darwin",
      hostName,
      extraModules ? [],
      extraOverlays ? [],
      extraSpecialArgs ? {},
      ...
    }: let
      mergedGlobals = globals // {host.name = hostName;};
    in
      nix-darwin.lib.darwinSystem {
        inherit system;

        modules =
          [
            {nixpkgs.overlays = extraOverlays;}

            ./lib/nix-core.nix
            ./lib/common/darwin
            ./lib/common/packages.nix
            ./users/${globals.user.name}/darwin.nix
          ]
          ++ extraModules;

        specialArgs =
          {
            globals = mergedGlobals;
            inherit inputs;
          }
          // extraSpecialArgs;
      };

    # https://github.com/numtide/system-manager/issues/98
    mkSystem = {
      hostName,
      extraModules ? [],
      extraOverlays ? [],
      extraSpecialArgs ? {},
      ...
    }: let
      mergedGlobals = globals // {host.name = hostName;};
    in
      system-manager.lib.makeSystemConfig {
        modules =
          [
            ./lib/common/linux
            ./lib/common/packages.nix
            ./users/${globals.user.name}/linux.nix
          ]
          ++ extraModules;

        overlays = extraOverlays;

        extraSpecialArgs =
          {
            globals = mergedGlobals;
            inherit inputs;
          }
          // extraSpecialArgs;
      };

    mkHome = {
      system,
      hostName,
      extraModules ? [],
      extraOverlays ? [],
      ...
    }: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = extraOverlays;
      };

      mergedGlobals = globals // {host.name = hostName;};
    in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules =
          [
            ./lib/nix-core.nix
            ./lib/common/home
          ]
          ++ extraModules;

        extraSpecialArgs = {
          inherit inputs;
          globals = mergedGlobals;
        };
      };
  in rec {
    lib = {
      inherit mkDarwin mkHome mkSystem;

      # Expose to consumers
      homebrew = import ./lib/common/darwin/homebrew.nix;
    };

    overlays = [
      inputs.dsully.inputs.rust-overlay.overlays.default
      inputs.dsully.overlays.default
      inputs.neovim-nightly-overlay.overlays.default
      inputs.nh.overlays.default
    ];

    darwinConfigurations = {
      jarvis = mkDarwin {
        hostName = "jarvis";
        extraModules = [
          ./machines/jarvis.nix
        ];
        extraOverlays = overlays;
      };
    };

    systemConfigs = {
      x86_64-linux = {
        server = mkSystem {
          hostName = "server";
          extraModules = [
            ./machines/server.nix
          ];
          extraOverlays = [
          ];
        };
      };
    };

    homeConfigurations = {
      "dsully@jarvis" = mkHome {
        system = "aarch64-darwin";
        hostName = "jarvis";
        extraOverlays = overlays;
      };

      "dsully@server" = mkHome {
        system = "x86_64-linux";
        hostName = "server";
        extraOverlays = overlays;
      };
    };
  };
}
