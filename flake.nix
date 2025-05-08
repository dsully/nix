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

    # home-manager, used for managing user configuration
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

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nh.url = "github:viperML/nh";
    nh.inputs.nixpkgs.follows = "nixpkgs";

    dsully.url = "github:dsully/nur";
    dsully.inputs.nixpkgs.follows = "nixpkgs";

    morlana.url = "github:ryanccn/morlana";
    morlana.inputs.nixpkgs.follows = "nixpkgs";
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
    ...
  }: let
    commonModules = [
      ./lib/nix-core.nix
      ./lib/common/packages.nix
      ./lib/common/home
    ];

    commonOverlays = [
      inputs.dsully.overlays.default
      inputs.morlana.overlays.default
      inputs.neovim-nightly-overlay.overlays.default
      inputs.nh.overlays.default
      inputs.rust-overlay.overlays.default
    ];

    commonGlobals = {
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
      globals = commonGlobals // {host.name = hostName;};
    in
      nix-darwin.lib.darwinSystem {
        inherit system;

        modules =
          commonModules
          ++ [
            {nixpkgs.overlays = commonOverlays ++ extraOverlays;}

            home-manager.darwinModules.home-manager

            ./lib/common/darwin
            ./users/${globals.user.name}/darwin.nix
          ]
          ++ extraModules;

        specialArgs = {inherit globals inputs;} // extraSpecialArgs;
      };

    mkLinux = {
      system ? "x86_64-linux",
      hostName,
      extraModules ? [],
      extraOverlays ? [],
      extraSpecialArgs ? {},
      ...
    }: let
      globals = commonGlobals // {host.name = hostName;};
    in
      nixpkgs.lib.nixosSystem {
        inherit system;

        modules =
          commonModules
          ++ [
            {nixpkgs.overlays = commonOverlays ++ extraOverlays;}

            home-manager.nixosModules.home-manager

            ./lib/common/linux
            ./users/${globals.user.name}/linux.nix
          ]
          ++ extraModules;

        specialArgs = {inherit globals inputs;} // extraSpecialArgs;
      };
  in {
    lib = {
      inherit mkDarwin mkLinux;

      # Expose to consumers
      homebrew = import ./lib/common/darwin/homebrew.nix;
      hm = import ./lib/common/home;
    };

    darwinConfigurations = {
      jarvis = mkDarwin {
        hostName = "jarvis";
        extraModules = [
          ./machines/jarvis.nix
          ./users/dsully/home
        ];
        extraOverlays = [
        ];
      };
    };

    nixosConfigurations = {
      server = mkLinux {
        hostName = "server";
        extraModules = [
          ./machines/server.nix
          ./users/dsully/home
        ];
        extraOverlays = [
        ];
      };
    };
  };
}
