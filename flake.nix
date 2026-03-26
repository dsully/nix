{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    system-manager.url = "github:numtide/system-manager";

    nix-auth.url = "github:numtide/nix-auth";
    nix-auth.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";

    nix-rtk.url = "github:deepwatrcreatur/nix-rtk";
    nix-rtk.inputs.llm-agents.follows = "llm-agents";

    charmbracelet-nur.url = "github:charmbracelet/nur";
    charmbracelet-nur.inputs.nixpkgs.follows = "nixpkgs";

    opnix.url = "github:brizzbuzz/opnix";
    opnix.inputs.nixpkgs.follows = "nixpkgs";

    claude-plugins-official.url = "github:anthropics/claude-plugins-official";
    claude-plugins-official.flake = false;

    wshobson-agents.url = "github:wshobson/agents";
    wshobson-agents.flake = false;

    skills-nix.url = "github:idjoo/skills.nix";

    astral-claude-plugins.url = "github:astral-sh/claude-code-plugins";
    astral-claude-plugins.flake = false;
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({
      config,
      withSystem,
      ...
    }: let
      # Auto-discover packages from packages/ directory.
      packageDir = ./packages;
      packageEntries = builtins.readDir packageDir;
      packageNames = builtins.filter (x: x != null) (map (name: let
        type = packageEntries.${name};
      in
        if type == "regular" && builtins.match ".*\\.nix$" name != null
        then builtins.replaceStrings [".nix"] [""] name
        else if type == "directory"
        then name
        else null)
      (builtins.attrNames packageEntries));

      # Home modules exported for downstream consumption.
      homeModules = {
        dsully = ./modules/home/dsully.nix;
        ai = ./modules/home/configs/ai;
        paste = ./modules/home/paste.nix;
        copypaste = ./modules/home/copypaste.nix;
        xdg-open-svc = ./modules/home/xdg-open-svc.nix;
        cachix-watch-store = ./modules/home/cachix-watch-store.nix;
      };

      # Blueprint-compatible "flake" arg passed via specialArgs.
      flakeAttr = {
        inherit homeModules inputs;
        inherit (config.flake) packages;
        modules = {
          darwin = {
            common = ./modules/darwin/common.nix;
            homebrew = ./modules/darwin/homebrew.nix;
          };
          system-manager = {
            common = ./modules/system-manager/common.nix;
          };
        };
      };

      # Blueprint-compatible "perSystem" arg for a given system.
      mkPerSystem = system: {
        self = config.flake.packages.${system};
        llm-agents = inputs.llm-agents.packages.${system};
        nix-auth = inputs.nix-auth.packages.${system};
        devshell = inputs.devshell.legacyPackages.${system};
      };

      # Common extraSpecialArgs for home-manager modules.
      hmArgs = system: {
        inherit inputs;
        flake = flakeAttr;
        perSystem = mkPerSystem system;
      };

      # Standalone home-manager configuration builder.
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
      flake = {
        # Typed module exports with class checking.
        modules = {
          darwin = {
            common = ./modules/darwin/common.nix;
            homebrew = ./modules/darwin/homebrew.nix;
          };
          homeManager = homeModules;
        };

        # Also export as homeModules for backward compat with downstream.
        inherit homeModules;

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

        systemManagerConfigurations = withSystem "x86_64-linux" ({
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
            extraSpecialArgs = smArgs;
          };
          zap = inputs.system-manager.lib.makeSystemConfig {
            modules = [./hosts/zap/system-configuration.nix];
            extraSpecialArgs = smArgs;
          };
        });
      };

      perSystem = {
        pkgs,
        system,
        lib,
        ...
      }: let
        selfPackages = builtins.listToAttrs (map (name: {
            inherit name;
            value = pkgs.callPackage (
              if builtins.hasAttr "${name}.nix" packageEntries
              then "${packageDir}/${name}.nix"
              else "${packageDir}/${name}"
            ) (packageOverrides.${name} or {});
          })
          packageNames);

        fmt = pkgs.callPackage ./formatter.nix {};

        # Overrides for packages that need flake input sources.
        packageOverrides = {
        };
      in {
        packages = selfPackages // {formatter = fmt;};

        formatter = fmt;

        checks =
          lib.mapAttrs' (name: lib.nameValuePair "pkg-${name}") selfPackages
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            formatting = fmt.passthru.tests.check;
          };

        # home-manager CLI discovers homeConfigurations here.
        legacyPackages.homeConfigurations = let
          mk = mkHome system;
          homes = {
            "dsully@jarvis" = {
              user = "dsully";
              userModule = ./hosts/jarvis/users/dsully.nix;
            };
            "dsully@server" = {
              user = "dsully";
              userModule = ./hosts/server/users/dsully.nix;
            };
            "dsully@zap" = {
              user = "dsully";
              userModule = ./hosts/zap/users/dsully.nix;
            };
          };
          hostSystem = {
            jarvis = "aarch64-darwin";
            server = "x86_64-linux";
            zap = "x86_64-linux";
          };
        in
          lib.filterAttrs (name: _:
            hostSystem.${lib.last (lib.splitString "@" name)} == system)
          (lib.mapAttrs (_: mk) homes);

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
