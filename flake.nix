{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    # neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-auth.url = "github:numtide/nix-auth";
    nix-auth.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/rynfar/meridian/pull/406 needs to be committed;
    meridian.url = "github:rynfar/meridian";
    meridian.inputs.nixpkgs.follows = "nixpkgs";

    opnix.url = "github:brizzbuzz/opnix";
    opnix.inputs.nixpkgs.follows = "nixpkgs";

    claude-plugins-official.url = "github:anthropics/claude-plugins-official";
    claude-plugins-official.flake = false;

    context-mode.url = "github:mksglu/context-mode";
    context-mode.flake = false;

    wshobson-agents.url = "github:wshobson/agents";
    wshobson-agents.flake = false;

    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    agent-skills.inputs.nixpkgs.follows = "nixpkgs";

    autoresearch-opencode.url = "github:dabiggm0e/autoresearch-opencode";
    autoresearch-opencode.flake = false;

    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({
      config,
      withSystem,
      ...
    }: let
      inherit (inputs.nixpkgs) lib;

      # Auto-discover packages from packages/ as { name = pathToCallPackage; }.
      packageDir = ./packages;
      packagePaths = lib.pipe (builtins.readDir packageDir) [
        (lib.filterAttrs (name: type:
          (type == "regular" && lib.hasSuffix ".nix" name)
          || type == "directory"))
        (lib.mapAttrs' (name: type:
          lib.nameValuePair
          (
            if type == "regular"
            then lib.removeSuffix ".nix" name
            else name
          )
          (packageDir + "/${name}")))
      ];

      # Auto-discover public home modules from modules/home/*.nix.
      # Internal files (imported directly by dsully.nix) are excluded.
      homeModulesDir = ./modules/home;
      homeModulesInternal = ["colors.nix" "dotfiles.nix"];
      homeModules =
        (lib.pipe (builtins.readDir homeModulesDir) [
          (lib.filterAttrs (
            name: type:
              type
              == "regular"
              && lib.hasSuffix ".nix" name
              && !(builtins.elem name homeModulesInternal)
          ))
          (lib.mapAttrs' (name: _:
            lib.nameValuePair
            (lib.removeSuffix ".nix" name)
            (homeModulesDir + "/${name}")))
        ])
        // {
          ai = ./modules/home/configs/ai;
        };

      darwinModules = {
        common = ./modules/darwin/common.nix;
        homebrew = ./modules/darwin/homebrew.nix;
      };

      # Blueprint-compatible "flake" arg passed via specialArgs.
      flakeAttr = {
        inherit homeModules inputs;
        inherit (config.flake) packages;
        modules = {
          darwin = darwinModules;
          system-manager = {
            common = ./modules/system-manager/common.nix;
            opnix = ./modules/system-manager/opnix.nix;
            caddy = ./modules/system-manager/caddy.nix;
            docker = ./modules/system-manager/docker.nix;
          };
        };
      };

      # Blueprint-compatible "perSystem" arg for a given system.
      # llm-agents packages now flow through pkgs.llm-agents (shared-nixpkgs
      # overlay applied in perSystem below), not this injection.
      mkPerSystem = system: {
        self = config.flake.packages.${system};
        nix-auth = inputs.nix-auth.packages.${system};
        devshell = inputs.devshell.legacyPackages.${system};
      };

      # Common extraSpecialArgs for home-manager modules.
      hmArgs = system: {
        inherit inputs;
        flake = flakeAttr;
        perSystem = mkPerSystem system;
      };

      # Standalone home-manager configuration builder. pkgs (from withSystem)
      # already carries the shared-nixpkgs + nixpkgs-fixes overlays.
      mkHome = system: {
        user,
        userModule,
      }:
        withSystem system ({pkgs, ...}:
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = hmArgs system;
            modules = [
              userModule
              {
                home.username = user;
                home.homeDirectory =
                  if pkgs.stdenv.isDarwin
                  then "/Users/${user}"
                  else "/home/${user}";
              }
            ];
          });
    in {
      systems = ["aarch64-darwin" "x86_64-linux"];

      imports = [
        inputs.devshell.flakeModule
        inputs.flake-parts.flakeModules.modules
      ];
      flake = let
        systemManagerConfigs = withSystem "x86_64-linux" ({
          pkgs,
          system,
          ...
        }: let
          smPkg = inputs.system-manager.packages.${system}.default;
          smArgs = {
            inherit inputs pkgs;
            flake = flakeAttr;
            system-manager = smPkg;
          };
        in {
          server = inputs.system-manager.lib.makeSystemConfig {
            modules = [./hosts/server/system-configuration.nix];
            specialArgs = smArgs;
          };
          zap = inputs.system-manager.lib.makeSystemConfig {
            modules = [./hosts/zap/system-configuration.nix];
            specialArgs = smArgs;
          };
        });
      in {
        modules.darwin = darwinModules;

        inherit homeModules;

        # Consuming flakes apply this at their own pkgs construction (module-level
        # nixpkgs.overlays is ignored when pkgs is passed in externally). Exposes
        # pkgs.llm-agents.* and the mcp-nixos doCheck fix that homeModules expect.
        overlays.default = inputs.nixpkgs.lib.composeManyExtensions (import ./overlays {inherit inputs;});

        # Reusable helper for consuming flakes. skillGroupsFrom turns a
        # marketplace's curated plugin list into `programs.ai.skills` groups —
        # see modules/home/configs/ai/skills/sources.nix.
        lib.skillGroupsFrom = (import ./modules/home/configs/ai/skills/sources.nix {inherit lib;}).skillGroupsFrom;

        darwinConfigurations.jarvis = withSystem "aarch64-darwin" ({
          pkgs,
          system,
          ...
        }:
          inputs.nix-darwin.lib.darwinSystem {
            inherit pkgs;
            specialArgs = {
              inherit inputs;
              flake = flakeAttr;
            };
            modules = [
              inputs.home-manager.darwinModules.home-manager
              ./hosts/jarvis/darwin-configuration.nix
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = hmArgs system;
                  users.dsully = import ./hosts/jarvis/users/dsully.nix;
                };
              }
            ];
          });

        systemConfigs = systemManagerConfigs;
      };

      perSystem = {
        system,
        lib,
        ...
      }: let
        # Overlaid package set shared by every consumer (home-manager, darwin,
        # system-manager) via withSystem, plus the packages/ builds below.
        # shared-nixpkgs exposes pkgs.llm-agents.*; nixpkgs-fixes carries the
        # mcp-nixos doCheck override.
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = import ./overlays {inherit inputs;};
        };

        selfPackages =
          lib.mapAttrs (
            name: path: pkgs.callPackage path (packageOverrides.${name} or {})
          )
          packagePaths;

        fmt = pkgs.callPackage ./formatter.nix {};

        # Overrides for packages that need flake input sources.
        packageOverrides = {
          # nh wraps itself to use rom as its build output monitor.
          nh = {inherit (selfPackages) rom;};
        };
      in {
        _module.args.pkgs = pkgs;

        packages = selfPackages // {formatter = fmt;};

        formatter = fmt;

        checks =
          lib.mapAttrs' (name: lib.nameValuePair "pkg-${name}") selfPackages
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            formatting = fmt.passthru.tests.check;
          };

        # home-manager CLI discovers homeConfigurations here.
        legacyPackages.homeConfigurations = let
          user = "dsully";
          hosts = {
            jarvis = "aarch64-darwin";
            server = "x86_64-linux";
            zap = "x86_64-linux";
          };
          mk = mkHome system;
        in
          lib.mapAttrs' (host: _:
            lib.nameValuePair "${user}@${host}" (mk {
              inherit user;
              userModule = ./hosts + "/${host}/users/dsully.nix";
            }))
          (lib.filterAttrs (_: sys: sys == system) hosts);

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
            ripgrep
            sd
            statix
            selfPackages.nix-package-updater
          ];
        };
      };
    });
}
