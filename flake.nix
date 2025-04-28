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

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index.url = "github:nix-community/nix-index";
    nix-index.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    nh.url = "github:viperML/nh";
    nh.inputs.nixpkgs.follows = "nixpkgs";

    dsully.url = "github:dsully/nur";
    dsully.inputs.nixpkgs.follows = "nixpkgs";

    morlana.url = "github:ryanccn/morlana";
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
    # Common overlays for all systems
    commonOverlays = [
      inputs.dsully.overlays.default
      inputs.neovim-nightly-overlay.overlays.default
      inputs.nur.overlays.default
      inputs.rust-overlay.overlays.default
    ];

    # Default username (can be overridden per host)
    defaultUserName = "dsully";

    # Generic function to create system configurations
    mkSystem = {
      system,
      hostName,
      userName ? defaultUserName,
      extraModules ? [],
      extraOverlays ? [],
      extraSpecialArgs ? {},
      ...
    }: let
      isDarwin = builtins.match ".*-darwin" system != null;

      # Select the appropriate system function based on isDarwin
      systemFunc =
        if isDarwin
        then nix-darwin.lib.darwinSystem
        else nixpkgs.lib.nixosSystem;

      # Select the appropriate home-manager module based on isDarwin
      hmModule =
        if isDarwin
        then home-manager.darwinModules.home-manager
        else home-manager.nixosModules.home-manager;

      osCommonConfig =
        ./lib/common/${
          if isDarwin
          then "darwin"
          else "nixos"
        }.nix;

      osUserConfig =
        ./users/${userName}/${
          if isDarwin
          then "darwin"
          else "nixos"
        }.nix;
    in
      systemFunc {
        inherit system;

        specialArgs =
          {
            inherit system userName hostName inputs isDarwin;
          }
          // extraSpecialArgs;

        modules =
          [
            {nixpkgs.overlays = commonOverlays ++ extraOverlays;}

            ./lib/nix-core.nix
            ./lib/common/packages.nix

            osCommonConfig
            osUserConfig
            hmModule
          ]
          ++ extraModules;
      };

    mkDarwin = args:
      mkSystem (args // {system = args.system or "aarch64-darwin";});

    mkNixOS = args:
      mkSystem (args // {system = args.system or "x86_64-linux";});
  in {
    lib = {
      inherit mkDarwin mkNixOS;

      # Expose to consumers
      homebrew = import ./lib/common/homebrew.nix;
    };

    darwinConfigurations = {
      jarvis = mkDarwin {
        hostName = "jarvis";
        extraModules = [
          ./machines/jarvis
        ];
        extraOverlays = [
          inputs.nh.overlays.default
          inputs.morlana.overlays.default
        ];
      };
    };
  };
}
