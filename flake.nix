{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # No nixpkgs follows: nix-community.cachix.org only has builds against the overlay's own pins.
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    nix-wrapper-modules.url = "github:nix-community/nix-wrapper-modules";
    nix-wrapper-modules.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    opnix.url = "github:brizzbuzz/opnix";
    opnix.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    agent-skills.inputs.nixpkgs.follows = "nixpkgs";

    claude-plugins-official.url = "github:anthropics/claude-plugins-official";
    claude-plugins-official.flake = false;

    improve.url = "github:shadcn/improve";
    improve.flake = false;

    mattpocock-skills.url = "github:mattpocock/skills";
    mattpocock-skills.flake = false;

    no-ai-slop.url = "github:petergyang/no-ai-slop";
    no-ai-slop.flake = false;

    ponytail.url = "github:DietrichGebert/ponytail";
    ponytail.flake = false;

    softaworks.url = "github:softaworks/agent-toolkit";
    softaworks.flake = false;

    superpowers.url = "github:obra/superpowers";
    superpowers.flake = false;

    wshobson-agents.url = "github:wshobson/agents";
    wshobson-agents.flake = false;
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({
      config,
      withSystem,
      ...
    }: let
      inherit (inputs.nixpkgs) lib;

      discoverPackages = import ./lib/discoverPackages.nix {inherit lib;};

      # Host factories bound to this flake's overlaid pkgs for one system.
      factoriesFor = system:
        withSystem system ({pkgs, ...}: let
          args = {
            inherit inputs pkgs;
            packages = config.flake.packages.${system};
          };
        in {
          mkDarwinHost = import ./lib/mkDarwinHost.nix args;
          mkSystemManagerHost = import ./lib/mkSystemManagerHost.nix args;
        });

      darwin = factoriesFor "aarch64-darwin";
      linux = factoriesFor "x86_64-linux";

      # Every modules/hosts/<name>.nix, grouped by the factory it takes, so each
      # system's homeConfigurations can be listed without evaluating the other's.
      hostFiles =
        lib.mapAttrs' (name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (import ./modules/hosts/${name}))
        (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (builtins.readDir ./modules/hosts));

      hostsBySystem = {
        aarch64-darwin =
          lib.mapAttrs (_: host: host {inherit (darwin) mkDarwinHost;})
          (lib.filterAttrs (_: host: builtins.functionArgs host ? mkDarwinHost) hostFiles);
        x86_64-linux =
          lib.mapAttrs (_: host: host {inherit (linux) mkSystemManagerHost;})
          (lib.filterAttrs (_: host: builtins.functionArgs host ? mkSystemManagerHost) hostFiles);
      };
    in {
      systems = ["aarch64-darwin" "x86_64-linux"];

      imports = [inputs.devshell.flakeModule];

      flake = {
        # Factories for consuming flakes. Each host factory takes
        # { inputs, pkgs, packages, extraModuleDirs? } first; see lib/hostLib.nix.
        lib = let
          withUpstream = factory: args: import factory (args // {upstreamPackages = config.flake.packages;});
        in {
          inherit discoverPackages;
          hideFromModel = import ./lib/hideFromModel.nix {inherit lib;};
          mkDarwinHost = withUpstream ./lib/mkDarwinHost.nix;
          mkSystemManagerHost = withUpstream ./lib/mkSystemManagerHost.nix;
        };

        # Consuming flakes apply this at their own pkgs construction (module-level
        # nixpkgs.overlays is ignored when pkgs is passed in externally). Exposes
        # pkgs.llm-agents.* that the modules expect.
        overlays.default = inputs.nixpkgs.lib.composeManyExtensions (import ./overlays {inherit inputs;});

        darwinConfigurations = lib.mapAttrs (_: host: host.system) hostsBySystem.aarch64-darwin;

        systemConfigs = lib.mapAttrs (_: host: host.system) hostsBySystem.x86_64-linux;
      };

      perSystem = {
        system,
        lib,
        ...
      }: let
        # Overlaid package set shared by every consumer (home-manager, darwin,
        # system-manager) via withSystem, plus the packages/ builds below.
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = import ./overlays {inherit inputs;};
        };

        selfPackages =
          lib.filterAttrs (_: lib.meta.availableOn pkgs.stdenv.hostPlatform)
          (lib.mapAttrs (_: path: pkgs.callPackage path {}) (discoverPackages ./packages));

        fmt = pkgs.callPackage ./formatter.nix {};
      in {
        _module.args.pkgs = pkgs;

        packages = selfPackages;

        formatter = fmt;

        checks =
          lib.mapAttrs' (name: lib.nameValuePair "pkg-${name}") selfPackages
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            formatting = fmt.passthru.tests.check;
          };

        # home-manager CLI discovers homeConfigurations here.
        legacyPackages.homeConfigurations =
          lib.mergeAttrsList (lib.mapAttrsToList (_: host: host.homeConfigurations) hostsBySystem.${system});

        devshells.default = {
          packages = with pkgs; [
            alejandra
            cachix
            deadnix
            fd
            fish
            jq
            just
            nh
            nurl
            oxfmt
            oxlint
            ripgrep
            sd
            statix
            selfPackages.nix-package-updater
          ];
        };
      };
    });
}
